local addonName, NS = ...
local L = NS.L
local Core = {}
NS.Core = Core

function Core:Message(text)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffc99b51CS:|r "..text) end
end

function Core:Warn(text)
  local now=GetTime and GetTime() or 0
  if self.lastWarning and now-self.lastWarning<5 then return end
  self.lastWarning=now
  self:Message(text)
end

function Core:Initialize(db)
  if db==nil then
    if CrateShopDB==nil then CrateShopDB={version=1,lists={}} end
    db=CrateShopDB
  end
  -- Do not replace malformed or future-version saved data silently.
  if type(db)~="table" or (db.version~=nil and db.version~=1) or type(db.lists)~="table" then
    self:Warn(L.BAD_DB)
    return
  end
  self.integration=NS.Integration.New(db)
  NS.Dialog:Install(self)
  if not self.hooked then NS.Detector:Install(self); self.hooked=true end
end

function Core:Read(link)
  if not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink)~="function" then
    return nil,"unavailable"
  end
  local ok,data=pcall(C_TooltipInfo.GetHyperlink,link)
  if not ok or type(data)~="table" or type(data.lines)~="table" or #data.lines==0 then
    return nil,"unavailable"
  end
  return NS.Parser.Parse(data.lines)
end

function Core:Observe(link)
  if not self.integration or self.pending then return end
  local id=tonumber(link:match("|Hitem:(%d+):"))
  if not id then return end
  local parsed,status,detail=self:Read(link)
  if not parsed then
    if status=="invalid" then
      local diagnostic=""
      if detail then
        local text=tostring(detail.text or ""):gsub("|","<124>")
          :gsub("[%c ]",function(c) return string.format("<%d>",c:byte()) end)
        local difference=""
        if detail.expected and detail.text then
          for i=1,math.max(#detail.text,#detail.expected) do
            local actual,wanted=detail.text:byte(i),detail.expected:byte(i)
            if actual~=wanted then
              difference=string.format(L.DIFFERENCE,i,tostring(actual),tostring(wanted),#detail.text,#detail.expected)
              break
            end
          end
          if difference=="" then difference=L.IDENTICAL_BYTES end
        end
        diagnostic=string.format(L.DIAGNOSTIC,L["REASON_"..tostring(detail.reason)] or tostring(detail.reason),tostring(detail.line),difference,text)
      end
      self:Warn(string.format(L.INVALID_REQUIREMENTS,diagnostic))
    elseif status=="ordinary" and NS.Catalog.Contains(id) then
      self:Warn(L.UNSUPPORTED_TOOLTIP)
    elseif status=="unavailable" then
      self:Warn(L.TOOLTIP_UNAVAILABLE)
    end
    return
  end
  local ticket,err=self.integration:Prepare(id,parsed)
  if not ticket then self:Warn(err); return end
  local opened,openError=self.integration:OpenIfCurrent(ticket)
  if opened then return end
  if opened==nil then self:Warn(openError); return end
  ticket.link=link
  self.pending=ticket
  local shown,dialog=pcall(NS.Dialog.Show,NS.Dialog,ticket,parsed)
  if not shown or not dialog then
    self.pending=nil
    self:Warn(L.CONFIRM_FAILED)
  end
end

local function sameRequirements(a,b)
  if not a or a.name~=b.name or #a.alternatives~=#b.alternatives then return false end
  for i,v in ipairs(a.alternatives) do
    if v.name~=b.alternatives[i].name or v.quantity~=b.alternatives[i].quantity then return false end
  end
  return true
end

function Core:Accept(ticket)
  if not ticket or self.pending~=ticket then return end
  self.pending=nil -- consume before any external callback; prevents repeated clicks
  if not NS.Detector:IsOpen() then
    self:Warn(L.AH_CLOSED)
    return
  end
  local current=self:Read(ticket.link)
  if not sameRequirements(current,ticket.parsed) then
    self:Warn(L.TOOLTIP_CHANGED)
    return
  end
  local ok,err=self.integration:Commit(ticket)
  if not ok then self:Warn(err); return end
  local listLabel=ticket.name:gsub("^CS:%s*","")
  self:Message(string.format(ticket.action=="update" and L.LIST_UPDATED or L.LIST_CREATED,listLabel))
end

function Core:Cancel(ticket)
  if ticket and self.pending==ticket then self.pending=nil end
end

local frame=CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" and name==addonName then
    Core:Initialize()
  elseif event=="AUCTION_HOUSE_SHOW" then
    NS.Detector.auctionOpen=true
  elseif event=="AUCTION_HOUSE_CLOSED" then
    NS.Detector.auctionOpen=false
    Core.pending=nil
    NS.Dialog:Hide()
  end
end)