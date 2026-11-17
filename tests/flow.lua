local root = os.getenv("AUCTIONATOR_PATH") or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Auctionator"
local function module(path)
  local f=loadfile("CrateShop/"..path..".lua")
  if f then f("CrateShop",CS) end
end
local handlers, hooks, popup, messages, queried, focused, shifted
local link="|cffffffff|Hitem:248692::::::::|h[Caixa]|h|r"
local function setupFlow(locale)
  GetLocale=function() return locale or "ptBR" end
  module("Localization"); module("CrateCatalog"); module("AuctionatorIntegration")
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
  AuctionHouseFrame=nil; AuctionFrame=nil; AuctionatorShoppingFrame=nil
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
  hooks[#hooks].callback("|Hitem:1:|h[Pedra]|h"); eq(popup,nil); eq(#messages,0)
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
test("aviso de requisitos inválidos inclui motivo e trecho escapado", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function()
    return {lines={{leftText="Caixa"},{leftText="Usar: Encha o caixote com qualquer conjunto da lista a seguir:\n- inválido"}}}
  end
  click()
  eq(m:GetCount(),0); eq(popup,nil)
  assert(messages[1]:find("alternative",1,true),"aviso deve identificar etapa recusada")
  assert(messages[1]:find("-<32>inválido",1,true),"aviso deve identificar trecho recusado")
end)
test("diagnóstico identifica primeiro byte diferente no cabeçalho", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function()
    return {lines={{leftText="Caixa"},{leftText="Usar:  Encha o caixote com qualquer conjunto da lista a seguir:\n- 10 Ouro"}}}
  end
  click(); eq(m:GetCount(),0)
  assert(messages[1]:find("byte 7: 32/69",1,true),"deve mostrar posição e bytes atual/esperado")
end)
test("diagnóstico exibe pipe como número para impedir interpretação pelo chat", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function()
    return {lines={{leftText="Caixa"},{leftText="Usar: Encha o caixote com qualquer conjunto da lista a seguir:|zIQ1:\n- 10 Ouro"}}}
  end
  click(); eq(m:GetCount(),0)
  assert(messages[1]:find("<124>zIQ1:",1,true),"código residual deve aparecer como texto sem pipe")
end)
test("tooltip com cor IQ1 abre confirmação sem gravar antes do aceite", function()
  local m=setupFlow()
  C_TooltipInfo.GetHyperlink=function()
    return {lines={{leftText="Caixa nova"},{leftText="Usar: Encha o caixote com qualquer conjunto da lista a seguir:|cnIQ1:\n- 10 Minérios de Ouro\n- 20 Minérios de Mithril|r"}}}
  end
  click()
  assert(popup,"cor nomeada não deve impedir confirmação")
  eq(m:GetCount(),0); eq(#messages,0)
  cancel(); eq(m:GetCount(),0)
end)

test("campo de pesquisa do Auctionator com foco permite confirmação", function()
  local m=setupFlow()
  local search={GetName=function() return nil end}
  AuctionatorShoppingFrame={SearchOptions={SearchString=search}}
  focused=search
  click(); assert(popup,"pesquisa Auctionator com foco deve permitir confirmação")
  eq(m:GetCount(),0); cancel()
end)
test("campo sem nome alheio continua ignorado", function()
  setupFlow()
  focused={GetName=function() return nil end}
  click(); eq(queried,0); eq(popup,nil)
end)
test("chat visível continua bloqueado mesmo com foco na pesquisa Auctionator", function()
  setupFlow()
  local search={}
  AuctionatorShoppingFrame={SearchOptions={SearchString=search}}
  focused=search
  ChatEdit_GetActiveWindow=function() return {IsShown=function() return true end} end
  click(); eq(queried,0); eq(popup,nil)
end)
test("hook real do Auctionator pode preencher pesquisa antes do CrateShop", function()
  local m=setupFlow()
  local crateHook=hooks[#hooks].callback
  local searches=0
  local search={GetName=function() return nil end}
  AuctionatorShoppingFrame={
    IsVisible=function() return true end,
    DoSearch=function(_,terms)
      eq(terms[1],'"Caixa"'); searches=searches+1
    end,
    SearchOptions={SearchString=search,SetSearchTerm=function(_,term)
      eq(term,'"Caixa"'); focused=search
    end},
  }
  C_Timer={After=function(_,fn) fn() end}
  StackSplitFrame={Hide=function() end}
  local itemLookup=C_Item.GetItemInfo
  C_Item.GetItemInfo=function(value)
    if type(value)=="string" then return "Caixa" end
    return itemLookup(value)
  end
  strfind=string.find; strmatch=string.match
  Auctionator.Shopping.Recents={Save=function() end}
  local root=os.getenv("AUCTIONATOR_PATH") or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Auctionator"
  dofile(root.."/Source/Shopping/Hooks.lua")
  hooks[#hooks].callback(link)
  eq(searches,1); eq(focused,search)
  crateHook(link)
  assert(popup,"hook posterior deve reconhecer caixote mesmo após pesquisa original")
  eq(searches,1); eq(m:GetCount(),0)
  cancel(); eq(searches,1); eq(m:GetCount(),0)
end)

test("cancelar migração mantém nome legado e próximo gesto oferece CS",function()
  local m,db=setupFlow()
  seedLegacyOre(m,db)
  click(); eq(popup.button1.text,"Atualizar lista")
  assert(popup.text:find("CS: Minérios de Especialista",1,true))
  cancel()
  assert(m:GetIndexForName("CrateShop: Minérios de Especialista"))
  eq(m:GetIndexForName("CS: Minérios de Especialista"),nil)
  click(); accept()
  eq(m:GetIndexForName("CrateShop: Minérios de Especialista"),nil)
  assert(m:GetIndexForName("CS: Minérios de Especialista"))
end)
test("próximo Shift clique após apagar oferece criar e cancelar não recria",function()
  local m,db=setupFlow()
  click(); accept()
  m:Delete(db.lists[248692].name)
  click(); eq(popup.button1.text,"Criar lista")
  cancel(); eq(m:GetCount(),0)
  click(); accept(); eq(m:GetCount(),1)
  assert(m:GetIndexForName("CS: Minérios de Especialista"))
end)

-- Portuguese fixtures are client captures; English fixtures are sourced reconstructions.
for _,locale in ipairs({"ptBR","ptPT","enUS","enGB","deDE"}) do
  test("localized dialog and confirmation: "..locale,function()
    local m=setupFlow(locale)
    local portuguese=locale=="ptBR" or locale=="ptPT"
    click()
    eq(popup.button1.text,portuguese and "Criar lista" or "Create list")
    eq(StaticPopupDialogs[popup.key].button2,portuguese and "Cancelar" or "Cancel")
    assert(popup.text:find("Caixote Extraviado: Minérios de Especialista",1,true))
    assert(popup.text:find(portuguese and "2 alternativas" or "2 alternatives",1,true))
    accept(); eq(m:GetCount(),1)
    eq(messages[1],"|cffc99b51CS:|r "..(portuguese and "Lista criada: " or "List created: ").."Minérios de Especialista.")
    click(); eq(popup.button1.text,portuguese and "Atualizar lista" or "Update list")
    accept(); eq(m:GetCount(),1)
  end)
  test("unrecognized known crate warns without inventing tooltip: "..locale,function()
    local m=setupFlow(locale)
    C_TooltipInfo.GetHyperlink=function() return {lines={{leftText="Captured requirements unavailable"}}} end
    click(); eq(popup,nil); eq(m:GetCount(),0); eq(#messages,1)
    assert(messages[1]:find((locale=="ptBR" or locale=="ptPT") and "Formato de requisitos não reconhecido" or "Unrecognized requirements format",1,true))
  end)
end

test("missing Portuguese translation falls back to English",function()
  setupFlow("ptPT")
  local translation=rawget(CS.L,"CREATE_LIST")
  CS.L.CREATE_LIST=nil
  click(); eq(popup.button1.text,"Create list")
  CS.L.CREATE_LIST=translation
end)

test("locale reload preserves owned list and manual list without writes",function()
  local m,db=setupFlow("ptBR")
  click(); accept()
  m:Create("Manual"); m:GetByName("Manual"):AppendItems({"unchanged"})
  local record=db.lists[248692]
  local entries=CopyTable(record.items)
  GetLocale=function() return "enUS" end
  module("Localization"); module("AuctionatorIntegration"); module("ConfirmationDialog"); module("Core")
  CS.Core:Initialize(db)
  eq(db.lists[248692],record); eq(m:GetCount(),2)
  local parsed=oreParsed(); parsed.name="Game-provided changed crate name"
  local ticket=assert(CS.Core.integration:Prepare(248692,parsed))
  eq(ticket.action,"update"); eq(ticket.name,record.name)
  eq(m:GetCount(),2); eq(record.items[1],entries[1])
  assert(CS.Core.integration:Commit(ticket)); eq(m:GetCount(),2)
  eq(m:GetByName("Manual"):GetItemByIndex(1),"unchanged")
end)

for _,locale in ipairs({"enUS","enGB"}) do
  test("English tooltip confirms creates and updates without extra search: "..locale,function()
    local m,db=setupFlow(locale)
    C_TooltipInfo.GetHyperlink=function() return {lines=Fixtures.englishOres} end
    C_Item.GetItemInfo=function(id)
      local names={[2776]="Gold Ore",[3858]="Mithril Ore"}
      return names[id],names[id] and ("|Hitem:"..id..":|h[item]|h")
    end
    m:Create("Manual list"); m:GetByName("Manual list"):AppendItems({"Keep me"})
    click(); assert(popup,"English tooltip should open confirmation")
    eq(popup.button1.text,"Create list"); eq(m:GetCount(),1)
    cancel(); eq(m:GetCount(),1)
    click(); accept(); eq(m:GetCount(),2)
    local list=m:GetByName(db.lists[248692].name)
    eq(list:GetItemByIndex(1),'"Gold Ore";;;;;;;;;;;#;;10')
    eq(list:GetItemByIndex(2),'"Mithril Ore";;;;;;;;;;;#;;20')
    click(); eq(popup.button1.text,"Update list"); accept(); eq(m:GetCount(),2)
    eq(m:GetByName("Manual list"):GetItemByIndex(1),"Keep me")
  end)
end
