-- Uses installed Auctionator source read-only, never the player's SavedVariables.
local root = os.getenv("AUCTIONATOR_PATH") or "C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Auctionator"
local tocFile=assert(io.open(root.."/Auctionator.toc","r"))
local installedVersion=assert(tocFile:read("*a"):match("## Version:%s*(%S+)"))
tocFile:close()
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
  setupItemData()
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
  C_AddOns = {GetAddOnMetadata=function() return installedVersion end}
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
  local ticket=assert(a:Prepare(248692,oreParsed()))
  eq(m:GetCount(),0); eq(ticket.action,"create")
  assert(a:Commit(ticket)); eq(m:GetCount(),1)
  local list=m:GetByName("CS: Minérios de Especialista")
  eq(list:GetItemCount(),2)
  eq(list:GetItemByIndex(2),'"Minério de Mithril";;;;;;;;;;;#;;20')
  assert(db.lists[248692]); assert(not a:Commit(ticket)); eq(m:GetCount(),1)
end)
test("colisão com lista alheia inclusive caixa diferente não escreve", function()
  local a,m=setupIntegration()
  m:Create("cs: minérios de especialista")
  assert(not a:Prepare(248692,oreParsed()))
  eq(m:GetCount(),1)
end)
function seedLegacyOre(m,db)
  local name="CrateShop: Minérios de Especialista"
  local entries={'"Minérios de Ouro";;;;;;;;;;;#;;10','"Minérios de Mithril";;;;;;;;;;;#;;20'}
  m:Create(name); m:GetByName(name):AppendItems(entries)
  db.lists[248692]={name=name,items=CopyTable(entries)}
end
test("atualiza lista própria legada em plural preservando lista alheia", function()
  local a,m,db=setupIntegration()
  m:Create("Minha"); m:GetByName("Minha"):AppendItems({"preservado"})
  seedLegacyOre(m,db)
  local t=assert(a:Prepare(248692,oreParsed())); eq(t.action,"update")
  assert(a:Commit(t))
  eq(m:GetByName(t.name):GetItemByIndex(1),'"Minério de Ouro";;;;;;;;;;;#;;10')
  eq(m:GetByName(t.name):GetItemByIndex(2),'"Minério de Mithril";;;;;;;;;;;#;;20')
  eq(m:GetByName("Minha"):GetItemByIndex(1),"preservado"); eq(m:GetCount(),2)
  eq(t.name,"CS: Minérios de Especialista")
  eq(m:GetIndexForName("CrateShop: Minérios de Especialista"),nil)
  eq(db.lists[248692].name,"CS: Minérios de Especialista")
end)
for _, change in ipairs({"edit"}) do
  test("preserva lista própria após jogador "..change, function()
    local a,m=setupIntegration()
    assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
    local name="CS: Minérios de Especialista"
    if change=="edit" then m:GetByName(name):AppendItems({"manual"})
    elseif change=="rename" then m:GetByName(name):Rename("Outro nome")
    else m:Delete(name) end
    assert(not a:Prepare(248692,oreParsed()))
  end)
end
test("recusa confirmação obsoleta após edição", function()
  local a,m=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  local t=assert(a:Prepare(248692,oreParsed()))
  m:GetByName(t.name):AppendItems({"manual"})
  assert(not a:Commit(t)); eq(m:GetByName(t.name):GetItemCount(),3)
end)
test("recusa remoção e recriação idêntica durante confirmação", function()
  local a,m=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  local t=assert(a:Prepare(248692,oreParsed()))
  local entries=m:GetByName(t.name):GetAllItems()
  m:Delete(t.name); m:Create(t.name); m:GetByName(t.name):AppendItems(entries)
  assert(not a:Commit(t))
end)
test("colisão surgida durante confirmação não sobrescreve", function()
  local a,m=setupIntegration()
  local t=assert(a:Prepare(248692,oreParsed()))
  m:Create(t.name); m:GetByName(t.name):AppendItems({"manual"})
  assert(not a:Commit(t)); eq(m:GetByName(t.name):GetItemByIndex(1),"manual")
end)
test("recusa dependência ausente ou versão inferior à mínima", function()
  local a,m=setupIntegration()
  Auctionator.API.v1.ConvertToSearchString=nil
  assert(not a:Prepare(248692,oreParsed())); eq(m:GetCount(),0)
  a,m=setupIntegration()
  C_AddOns.GetAddOnMetadata=function() return "345" end
  assert(not a:Prepare(248692,oreParsed())); eq(m:GetCount(),0)
end)
test("converte todas entradas antes de escrever", function()
  local a,m=setupIntegration()
  local convert=Auctionator.API.v1.ConvertToSearchString
  Auctionator.API.v1.ConvertToSearchString=function(caller,term)
    if term.quantity==20 then error("conversion failed") end
    return convert(caller,term)
  end
  assert(not a:Prepare(248692,oreParsed())); eq(m:GetCount(),0)
end)
test("falha na criação depois de inserir reverte lista vazia", function()
  local a,m,db,events,fail=setupIntegration()
  local t=assert(a:Prepare(248692,oreParsed()))
  fail("meta")
  assert(not a:Commit(t)); eq(m:GetCount(),0); eq(db.lists[248692],nil)
end)
test("falha depois do append restaura lista legada e vínculo anterior", function()
  local a,m,db,events,fail=setupIntegration()
  seedLegacyOre(m,db)
  local t=assert(a:Prepare(248692,oreParsed()))
  fail("items")
  assert(not a:Commit(t))
  eq(m:GetByName("CrateShop: Minérios de Especialista"):GetItemByIndex(1),'"Minérios de Ouro";;;;;;;;;;;#;;10')
  eq(m:GetIndexForName("CS: Minérios de Especialista"),nil)
  eq(db.lists[248692].items[1],'"Minérios de Ouro";;;;;;;;;;;#;;10')
end)
test("conversão deve preservar quantidade do catálogo", function()
  local a,m=setupIntegration()
  local convert=Auctionator.API.v1.ConvertToSearchString
  Auctionator.API.v1.ConvertToSearchString=function(caller,term)
    local altered=CopyTable(term); altered.quantity=term.quantity+1
    return convert(caller,altered)
  end
  assert(not a:Prepare(248692,oreParsed()))
  eq(m:GetCount(),0)
end)
test("material sem nome impede qualquer criação", function()
  local a,m=setupIntegration()
  C_Item.GetItemInfo=function() return nil end
  assert(not a:Prepare(248692,oreParsed()))
  eq(m:GetCount(),0)
end)
test("catálogo desconhecido não cria lista com termos do tooltip", function()
  local a,m=setupIntegration()
  assert(not a:Prepare(999999,oreParsed()))
  eq(m:GetCount(),0)
end)
test("mudança de versão do catálogo invalida confirmação", function()
  local a,m=setupIntegration()
  local t=assert(a:Prepare(248692,oreParsed()))
  local original=CS.Catalog.version
  CS.Catalog.version="changed"
  local ok=a:Commit(t)
  CS.Catalog.version=original
  assert(not ok); eq(m:GetCount(),0)
end)
test("mudança de nome canônico durante confirmação impede gravação", function()
  local a,m=setupIntegration()
  local t=assert(a:Prepare(248692,oreParsed()))
  local original=C_Item.GetItemInfo
  C_Item.GetItemInfo=function(id)
    local name,link=original(id)
    return name.." alterado",link
  end
  assert(not a:Commit(t)); eq(m:GetCount(),0)
end)

for _,version in ipairs({"346","347","400"}) do
  test("aceita Auctionator "..version.." com interfaces completas",function()
    local a,m=setupIntegration()
    C_AddOns.GetAddOnMetadata=function() return version end
    assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
    eq(m:GetCount(),1)
  end)
end
for _,version in ipairs({"345","0","desconhecida","347-preview"}) do
  test("recusa metadado de versão inválido ou antigo: "..version,function()
    local a,m=setupIntegration()
    C_AddOns.GetAddOnMetadata=function() return version end
    assert(not a:Prepare(248692,oreParsed())); eq(m:GetCount(),0)
  end)
end
test("versão posterior continua exigindo interfaces antes da escrita",function()
  local a,m=setupIntegration()
  C_AddOns.GetAddOnMetadata=function() return "400" end
  m.Create=false
  assert(not a:Prepare(248692,oreParsed())); eq(m:GetCount(),0)
end)

test("preparar migração não renomeia nem altera vínculo",function()
  local a,m,db=setupIntegration()
  seedLegacyOre(m,db)
  local record=db.lists[248692]
  local t=assert(a:Prepare(248692,oreParsed()))
  eq(t.action,"update"); eq(t.name,"CS: Minérios de Especialista")
  eq(m:GetCount(),1)
  assert(m:GetIndexForName("CrateShop: Minérios de Especialista"))
  eq(m:GetIndexForName("CS: Minérios de Especialista"),nil)
  eq(db.lists[248692],record); eq(record.name,"CrateShop: Minérios de Especialista")
end)
test("migração protege colisão no nome CS",function()
  local a,m,db=setupIntegration()
  seedLegacyOre(m,db)
  m:Create("CS: Minérios de Especialista")
  m:GetByName("CS: Minérios de Especialista"):AppendItems({"manual"})
  assert(not a:Prepare(248692,oreParsed()))
  eq(m:GetCount(),2)
  eq(m:GetByName("CS: Minérios de Especialista"):GetItemByIndex(1),"manual")
  eq(db.lists[248692].name,"CrateShop: Minérios de Especialista")
end)
test("falha durante renomeação reverte nome e preserva associação antiga",function()
  local a,m,db,events,fail=setupIntegration()
  seedLegacyOre(m,db)
  local t=assert(a:Prepare(248692,oreParsed()))
  fail("meta")
  assert(not a:Commit(t))
  eq(m:GetCount(),1)
  eq(m:GetIndexForName("CS: Minérios de Especialista"),nil)
  eq(m:GetByName("CrateShop: Minérios de Especialista"):GetItemByIndex(1),'"Minérios de Ouro";;;;;;;;;;;#;;10')
  eq(db.lists[248692].name,"CrateShop: Minérios de Especialista")
end)
test("lista removida permite nova importação sem limpar associação",function()
  local a,m,db=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  local record=db.lists[248692]
  m:Delete(record.name)
  local t=assert(a:Prepare(248692,oreParsed()))
  eq(t.action,"create"); eq(t.name,"CS: Minérios de Especialista")
  eq(m:GetCount(),0); eq(db.lists[248692],record)
  assert(a:Commit(t)); eq(m:GetCount(),1)
  eq(db.lists[248692].name,"CS: Minérios de Especialista")
end)
test("lista legada removida recria diretamente com CS",function()
  local a,m,db=setupIntegration()
  seedLegacyOre(m,db); m:Delete("CrateShop: Minérios de Especialista")
  local t=assert(a:Prepare(248692,oreParsed()))
  eq(t.action,"create"); assert(a:Commit(t))
  eq(m:GetCount(),1); assert(m:GetIndexForName("CS: Minérios de Especialista"))
end)
test("reimportação não adota lista manual com mesmo nome",function()
  local a,m,db=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  local name=db.lists[248692].name
  m:Delete(name); m:Create(name); m:GetByName(name):AppendItems({"manual"})
  assert(not a:Prepare(248692,oreParsed()))
  eq(m:GetByName(name):GetItemByIndex(1),"manual")
end)
test("lista renomeada pelo jogador é preservada ao reimportar",function()
  local a,m,db=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  m:GetByName(db.lists[248692].name):Rename("Meu nome")
  local t=assert(a:Prepare(248692,oreParsed()))
  eq(t.action,"create"); assert(a:Commit(t))
  eq(m:GetCount(),2)
  eq(m:GetByName("Meu nome"):GetItemByIndex(1),'"Minério de Ouro";;;;;;;;;;;#;;10')
end)
test("remoção durante confirmação exige novo gesto antes de reimportar",function()
  local a,m,db=setupIntegration()
  assert(a:Commit(assert(a:Prepare(248692,oreParsed()))))
  local t=assert(a:Prepare(248692,oreParsed()))
  m:Delete(t.name)
  assert(not a:Commit(t)); eq(m:GetCount(),0)
  local fresh=assert(a:Prepare(248692,oreParsed()))
  eq(fresh.action,"create"); assert(a:Commit(fresh)); eq(m:GetCount(),1)
end)
