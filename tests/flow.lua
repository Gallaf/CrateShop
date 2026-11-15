local root = os.getenv("AUCTIONATOR_PATH") or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Auctionator"
local function module(path)
  local f=loadfile("CrateShop/"..path..".lua")
  if f then f("CrateShop",CS) end
end
local handlers, hooks, popup, messages, queried, focused, shifted
local link="|cffffffff|Hitem:100::::::::|h[Caixa]|h|r"
local function setupFlow()
  local a,m,db=setupIntegration()
  handlers,hooks,messages,queried={},{},{},0
  focused,shifted=nil,true
  UIParent={}
  DEFAULT_CHAT_FRAME={AddMessage=function(_,text) messages[#messages+1]=text end}
  StaticPopupDialogs={}
  StaticPopup_Show=function(key,text,arg2,data)
    popup={key=key,text=text,data=data,button1={SetText=function(self,text) self.text=text end}}
    StaticPopupDialogs[key].OnShow(popup,data)
    return popup
  end
  StaticPopup_Hide=function(key)
    if popup and popup.key==key then
      local old=popup; popup=nil
      if StaticPopupDialogs[key].OnHide then StaticPopupDialogs[key].OnHide(old) end
    end
  end
  GetTime=function() return 123 end
  CreateFrame=function()
    return {
      RegisterEvent=function() end,
      SetScript=function(_,name,fn) handlers[name]=fn end,
    }
  end
  IsShiftKeyDown=function() return shifted end
  GetCurrentKeyBoardFocus=function() return focused end
  ChatEdit_GetActiveWindow=function() return nil end
  ChatFrameUtil={InsertLink=function() end}
  ChatEdit_InsertLink=function() end
  hooksecurefunc=function(target,key,fn) hooks[#hooks+1]={target=target,key=key,callback=fn} end
  C_TooltipInfo={GetHyperlink=function(actual)
    eq(actual,link); queried=queried+1
    return {lines=Fixtures.ores}
  end}
  AuctionHouseFrame=nil; AuctionFrame=nil
  module("ConfirmationDialog"); module("CrateDetector"); module("Core")
  assert(CS.Core,"flow not implemented")
  handlers.OnEvent(nil,"ADDON_LOADED","CrateShop")
  CrateShopDB=db
  -- Reinitialize with the fresh, empty database, as on ADDON_LOADED.
  CS.Core:Initialize(db)
  handlers.OnEvent(nil,"AUCTION_HOUSE_SHOW")
  popup=nil
  return m,db
end
local function click() assert(#hooks>0,"secure hook missing"); hooks[#hooks].callback(link) end
local function accept()
  local old=assert(popup,"confirmation missing")
  StaticPopupDialogs[old.key].OnAccept(old,old.data)
end
local function cancel()
  local old=assert(popup,"confirmation missing")
  StaticPopupDialogs[old.key].OnCancel(old,old.data)
end
test("Shift clique só grava após confirmação e clique repetido não duplica", function()
  local m=setupFlow()
  click(); eq(m:GetCount(),0); assert(popup.text:find("2",1,true))
  assert(popup.text:find("alternativas",1,true)); assert(popup.text:find("um conjunto",1,true))
  click(); eq(queried,1)
  accept(); eq(m:GetCount(),1); accept(); eq(m:GetCount(),1)
end)
test("cancelar não altera nem cria lista", function()
  local m=setupFlow(); click(); cancel(); eq(m:GetCount(),0)
  click(); assert(popup); eq(queried,2)
end)
test("botão oferece atualização para lista própria", function()
  setupFlow(); click(); accept(); click()
  eq(popup.button1.text,"Atualizar lista")
end)
test("chat focado Shift ausente AH fechada e não item são ignorados", function()
  setupFlow()
  focused={GetName=function() return "ChatEditBox" end}; click(); eq(queried,0)
  focused=nil; shifted=false; click(); eq(queried,0)
  shifted=true; handlers.OnEvent(nil,"AUCTION_HOUSE_CLOSED"); click(); eq(queried,0)
  handlers.OnEvent(nil,"AUCTION_HOUSE_SHOW")
  hooks[#hooks].callback("|Hspell:1|h[spell]|h"); eq(queried,0)
end)
test("fallback usa somente ChatEdit_InsertLink", function()
  setupFlow()
  ChatFrameUtil=nil; hooks={}
  CS.Detector:Install(CS.Core)
  eq(#hooks,1); eq(hooks[1].key,"ChatEdit_InsertLink")
end)
test("item comum não abre diálogo nem emite mensagem", function()
  setupFlow()
  C_TooltipInfo.GetHyperlink=function() return {lines={{leftText="Pedra"},{leftText="Preço"}}} end
  click(); eq(popup,nil); eq(#messages,0)
end)
test("requisitos inválidos avisam sem criar lista", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function()
    return {lines={{leftText="Caixa"},{leftText="Usar: Encha o caixote com qualquer conjunto da lista a seguir:\n- inválido"}}}
  end
  click(); eq(popup,nil); eq(m:GetCount(),0); eq(#messages,1)
end)
test("tooltip indisponível tem aviso limitado e nenhum loop de tentativa", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function() queried=queried+1; return nil end
  click(); click(); eq(queried,2); eq(#messages,1); eq(m:GetCount(),0)
end)
test("dados tooltip alterados entre abertura e confirmação são recusados", function()
  local m=setupFlow(); click()
  C_TooltipInfo.GetHyperlink=function() return {lines=Fixtures.herbs} end
  accept(); eq(m:GetCount(),0)
end)
test("fechar AH invalida confirmação", function()
  local m=setupFlow(); click()
  local old=popup
  handlers.OnEvent(nil,"AUCTION_HOUSE_CLOSED")
  StaticPopupDialogs[old.key].OnAccept(old,old.data)
  eq(m:GetCount(),0)
end)
test("erro ao abrir diálogo não prende futuras confirmações", function()
  local m=setupFlow()
  local show=StaticPopup_Show
  StaticPopup_Show=function() error("popup indisponível") end
  click(); eq(m:GetCount(),0)
  StaticPopup_Show=show
  click(); assert(popup,"nova confirmação deve ser permitida")
end)
