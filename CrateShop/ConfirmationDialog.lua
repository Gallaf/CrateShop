local _, NS = ...
local Dialog = {}
NS.Dialog = Dialog
local key="CRATESHOP_CONFIRM"

function Dialog:Install(core)
  StaticPopupDialogs[key]={
    text="%s",
    button1="Criar lista",
    button2="Cancelar",
    timeout=0,
    whileDead=true,
    hideOnEscape=true,
    preferredIndex=3,
    OnShow=function(self,data)
      local ticket=data or self.data
      self.button1:SetText(ticket and ticket.action=="update" and "Atualizar lista" or "Criar lista")
    end,
    OnAccept=function(self,data) core:Accept(data or self.data) end,
    OnCancel=function(self,data) core:Cancel(data or self.data) end,
    OnHide=function(self) core:Cancel(self.data) end,
  }
end

function Dialog:Show(ticket, parsed)
  local verb=ticket.action=="update" and "Atualizar" or "Criar"
  local text=parsed.name.."\n\n"..#parsed.alternatives
    .." alternativas: basta escolher um conjunto.\nNão é necessário comprar todos os materiais."
    .."\n\n"..verb.." a lista:\n"..ticket.name.."?"
  return StaticPopup_Show(key,text,nil,ticket)
end

function Dialog:Hide()
  StaticPopup_Hide(key)
end