local _, NS = ...
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
    -- More conservative than Auctionator: any focused edit control is ignored,
    -- including unnamed controls, as is a visible chat edit window.
    if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then return end
    local chat=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if chat and chat:IsShown() then return end
    -- A secure post-hook must never interfere with the original link handler.
    local ok,err=pcall(core.Observe,core,link)
    if not ok then core:Warn("Não foi possível interpretar este item. "..tostring(err)) end
  end
  if type(hooksecurefunc)~="function" then
    core:Warn("Hook seguro indisponível; detecção desativada.")
  elseif ChatFrameUtil and type(ChatFrameUtil.InsertLink)=="function" then
    hooksecurefunc(ChatFrameUtil,"InsertLink",observe)
  elseif type(ChatEdit_InsertLink)=="function" then
    hooksecurefunc(_G,"ChatEdit_InsertLink",observe)
  else
    core:Warn("Integração de links indisponível; detecção desativada.")
  end
end