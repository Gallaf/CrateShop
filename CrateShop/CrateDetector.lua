local _, NS = ...
local L = NS.L
local Detector = {auctionOpen=false}
NS.Detector = Detector

function Detector:IsOpen()
  return self.auctionOpen
end

function Detector:Install(core)
  self.auctionOpen = not not (
    (AuctionHouseFrame and AuctionHouseFrame:IsShown())
    or (AuctionFrame and AuctionFrame:IsShown()))
  local function observe(link)
    if not self:IsOpen() or not IsShiftKeyDown() or type(link)~="string"
      or not link:match("|Hitem:%d+:") then return end
    -- Auctionator's unnamed search field can retain focus during Shift-click.
    -- Allow only that verified control; chat and other edit controls stay blocked.
    local focus=GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    local options=AuctionatorShoppingFrame and AuctionatorShoppingFrame.SearchOptions
    local search=options and options.SearchString
    if focus and focus~=search then return end
    local chat=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if chat and chat:IsShown() then return end
    -- A secure post-hook must never interfere with the original link handler.
    local ok,err=pcall(core.Observe,core,link)
    if not ok then core:Warn(string.format(L.INTERPRET_FAILED,tostring(err))) end
  end
  if type(hooksecurefunc)~="function" then
    core:Warn(L.NO_HOOK)
  elseif ChatFrameUtil and type(ChatFrameUtil.InsertLink)=="function" then
    hooksecurefunc(ChatFrameUtil,"InsertLink",observe)
  elseif type(ChatEdit_InsertLink)=="function" then
    hooksecurefunc(_G,"ChatEdit_InsertLink",observe)
  else
    core:Warn(L.NO_LINKS)
  end
end