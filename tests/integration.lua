-- Uses installed Auctionator source read-only, never the player's SavedVariables.
local root = os.getenv("AUCTIONATOR_PATH") or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Auctionator"
function CopyTable(t)
  local out = {}
  for k,v in pairs(t) do out[k] = type(v) == "table" and CopyTable(v) or v end
  return out
end
function CreateAndInitFromMixin(mixin, ...)
  local object = {}
  for k,v in pairs(mixin) do object[k]=v end
  object:Init(...)
  return object
end
function tIndexOf(t, value) for k,v in ipairs(t) do if v==value then return k end end end
dofile(root .. "/Source/Shopping/Mixins/ListManager.lua")
dofile(root .. "/Source/Shopping/Mixins/List.lua")
function strjoin(separator, ...) return table.concat({...}, separator) end
function strsplit(separator, text)
  local out={}
  for part in (text..separator):gmatch("(.-)"..separator) do out[#out+1]=part end
  return unpack(out)
end
local integration = loadfile("CrateShop/AuctionatorIntegration.lua")
if integration then integration("CrateShop", CS) end

function setupIntegration()
  local data, events, failEvent = {}, {}, nil
  Auctionator = {
    Shopping={Events={ListMetaChange="meta",ListItemChange="items",ListImportFinished="import"}},
    API={v1={}},
    EventBus={
      RegisterSource=function() end,
      Fire=function(_, source, event)
        events[#events+1]=event
        assert(event ~= "import", "automatic search event forbidden")
        if failEvent == event then failEvent=nil; error("injected event failure") end
      end
    }
  }
  C_AddOns = {GetAddOnMetadata=function() return "346" end}
  local manager=CreateAndInitFromMixin(AuctionatorShoppingListManagerMixin,
    function() return data end, function(value) data=value end)
  Auctionator.Shopping.ListManager=manager
  Auctionator.Search={}
  Auctionator.Constants={AdvancedSearchDivider=";"}
  Auctionator.API.InternalVerifyID=function(caller) eq(caller,"CrateShop") end
  Auctionator.API.ComposeError=function(caller,message) error(message) end
  dofile(root .. "/Source/Search/Advanced.lua")
  dofile(root .. "/Source/API/v1/ShoppingLists.lua")
  Auctionator.API.v1.CreateShoppingList=function() error("public creation can search") end
  local db={lists={}}
  local adapter=assert(CS.Integration, "integration not implemented").New(db)
  return adapter, manager, db, events, function(event) failEvent=event end
end
function oreParsed() return assert(CS.Parser.Parse(Fixtures.ores)) end

test("criação prepara sem escrever e grava todas alternativas uma vez", function()
  local a,m,db=setupIntegration()
  local ticket=assert(a:Prepare(100,oreParsed()))
  eq(m:GetCount(),0); eq(ticket.action,"create")
  assert(a:Commit(ticket)); eq(m:GetCount(),1)
  local list=m:GetByName("CrateShop: Minérios de Especialista")
  eq(list:GetItemCount(),2)
  eq(list:GetItemByIndex(2),'"Minérios de Mithril";;;;;;;;;;;#;;20')
  assert(db.lists[100]); assert(not a:Commit(ticket)); eq(m:GetCount(),1)
end)
test("colisão com lista alheia inclusive caixa diferente não escreve", function()
  local a,m=setupIntegration()
  m:Create("crateshop: minérios de especialista")
  assert(not a:Prepare(100,oreParsed()))
  eq(m:GetCount(),1)
end)
test("atualiza própria preservando lista alheia", function()
  local a,m=setupIntegration()
  m:Create("Minha"); m:GetByName("Minha"):AppendItems({"preservado"})
  assert(a:Commit(assert(a:Prepare(100,oreParsed()))))
  local p=oreParsed(); p.alternatives[1].quantity=42
  local t=assert(a:Prepare(100,p)); eq(t.action,"update")
  assert(a:Commit(t))
  eq(m:GetByName("CrateShop: Minérios de Especialista"):GetItemByIndex(1),'"Minérios de Ouro";;;;;;;;;;;#;;42')
  eq(m:GetByName("Minha"):GetItemByIndex(1),"preservado"); eq(m:GetCount(),2)
end)
for _, change in ipairs({"edit","rename","remove"}) do
  test("preserva lista própria após jogador "..change, function()
    local a,m=setupIntegration()
    assert(a:Commit(assert(a:Prepare(100,oreParsed()))))
    local name="CrateShop: Minérios de Especialista"
    if change=="edit" then m:GetByName(name):AppendItems({"manual"})
    elseif change=="rename" then m:GetByName(name):Rename("Outro nome")
    else m:Delete(name) end
    assert(not a:Prepare(100,oreParsed()))
  end)
end
test("recusa confirmação obsoleta após edição", function()
  local a,m=setupIntegration()
  assert(a:Commit(assert(a:Prepare(100,oreParsed()))))
  local t=assert(a:Prepare(100,oreParsed()))
  m:GetByName(t.name):AppendItems({"manual"})
  assert(not a:Commit(t)); eq(m:GetByName(t.name):GetItemCount(),3)
end)
test("recusa remoção e recriação idêntica durante confirmação", function()
  local a,m=setupIntegration()
  assert(a:Commit(assert(a:Prepare(100,oreParsed()))))
  local t=assert(a:Prepare(100,oreParsed()))
  local entries=m:GetByName(t.name):GetAllItems()
  m:Delete(t.name); m:Create(t.name); m:GetByName(t.name):AppendItems(entries)
  assert(not a:Commit(t))
end)
test("colisão surgida durante confirmação não sobrescreve", function()
  local a,m=setupIntegration()
  local t=assert(a:Prepare(100,oreParsed()))
  m:Create(t.name); m:GetByName(t.name):AppendItems({"manual"})
  assert(not a:Commit(t)); eq(m:GetByName(t.name):GetItemByIndex(1),"manual")
end)
test("recusa dependência ausente ou versão desconhecida", function()
  local a,m=setupIntegration()
  Auctionator.API.v1.ConvertToSearchString=nil
  assert(not a:Prepare(100,oreParsed())); eq(m:GetCount(),0)
  a,m=setupIntegration()
  C_AddOns.GetAddOnMetadata=function() return "999" end
  assert(not a:Prepare(100,oreParsed())); eq(m:GetCount(),0)
end)
test("converte todas entradas antes de escrever", function()
  local a,m=setupIntegration()
  local convert=Auctionator.API.v1.ConvertToSearchString
  Auctionator.API.v1.ConvertToSearchString=function(caller,term)
    if term.quantity==20 then error("conversion failed") end
    return convert(caller,term)
  end
  assert(not a:Prepare(100,oreParsed())); eq(m:GetCount(),0)
end)
test("falha na criação depois de inserir reverte lista vazia", function()
  local a,m,db,events,fail=setupIntegration()
  local t=assert(a:Prepare(100,oreParsed()))
  fail("meta")
  assert(not a:Commit(t)); eq(m:GetCount(),0); eq(db.lists[100],nil)
end)
test("falha depois do append reverte atualização", function()
  local a,m,db,events,fail=setupIntegration()
  assert(a:Commit(assert(a:Prepare(100,oreParsed()))))
  local p=oreParsed(); p.alternatives[1].quantity=99
  local t=assert(a:Prepare(100,p))
  fail("items")
  assert(not a:Commit(t))
  eq(m:GetByName(t.name):GetItemByIndex(1),'"Minérios de Ouro";;;;;;;;;;;#;;10')
  eq(db.lists[100].items[1],'"Minérios de Ouro";;;;;;;;;;;#;;10')
end)
test("conversão não pode arredondar quantidade silenciosamente", function()
  local a,m=setupIntegration()
  local p=oreParsed(); p.alternatives[1].quantity=9007199254740991
  assert(not a:Prepare(100,p),"quantidade arredondada deve impedir criação")
  eq(m:GetCount(),0)
end)
