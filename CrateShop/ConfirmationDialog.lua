local _, NS = ...
local L = NS.L
local Dialog = {}
NS.Dialog = Dialog
local key="CRATESHOP_CONFIRM"

function Dialog:Install(core)
  StaticPopupDialogs[key]={
    text="%s",
    button1=L.CREATE_LIST,
    button2=L.CANCEL,
    timeout=0,
    whileDead=true,
    hideOnEscape=true,
    preferredIndex=3,
    OnShow=function(self,data)
      local ticket=data or self.data
      self.button1:SetText(ticket and ticket.action=="update" and L.UPDATE_LIST or L.CREATE_LIST)
    end,
    OnAccept=function(self,data) core:Accept(data or self.data) end,
    OnCancel=function(self,data) core:Cancel(data or self.data) end,
    OnHide=function(self) core:Cancel(self.data) end,
  }
end

function Dialog:Show(ticket, parsed)
  local text=string.format(ticket.action=="update" and L.UPDATE_PROMPT or L.CREATE_PROMPT,
    parsed.name,#parsed.alternatives,ticket.name)
  return StaticPopup_Show(key,text,nil,ticket)
end

function Dialog:Hide()
  StaticPopup_Hide(key)
end