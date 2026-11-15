local _, NS = ...
local Integration = {}
NS.Integration = Integration

local function copy(items)
  local result = {}
  for i,v in ipairs(items) do result[i]=v end
  return result
end
local function same(a,b)
  if type(a)~="table" or type(b)~="table" or #a~=#b then return false end
  for i,v in ipairs(a) do if v~=b[i] then return false end end
  return true
end
local function requireMethods(object, names)
  if type(object)~="table" then return false end
  for _,name in ipairs(names) do
    if type(object[name])~="function" then return false end
  end
  return true
end

function Integration.New(db)
  local self = {db=db, busy=false}
  setmetatable(self, {__index=Integration})
  return self
end

function Integration:Compatible()
  local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  local version = metadata and metadata("Auctionator", "Version")
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  local manager = Auctionator and Auctionator.Shopping and Auctionator.Shopping.ListManager
  if version ~= "346"
    or not requireMethods(api, {"ConvertToSearchString", "ConvertFromSearchString", "GetShoppingListItems"})
    or not requireMethods(manager, {"Create","Delete","GetCount","GetByIndex","GetByName","GetIndexForName"})
    or not requireMethods(AuctionatorShoppingListMixin, {"GetAllItems","ClearItems","AppendItems","IsTemporary"})
    or type(self.db)~="table" or type(self.db.lists)~="table" then
    error("Integração incompatível. É necessário Auctionator 346 e suas interfaces de listas verificadas.")
  end
  return manager, api
end

-- Names are checked case-insensitively as a conservative collision policy.
function Integration:Find(manager, name)
  local found
  for i=1,manager:GetCount() do
    local list=manager:GetByIndex(i)
    if list:GetName():lower()==name:lower() then
      if found then error("Há listas com nomes ambíguos; nenhuma será alterada.") end
      found=list
    end
  end
  return found
end

function Integration:Inspect(id, parsed)
  local manager,api=self:Compatible()
  if type(id)~="number" or id<1 or id~=math.floor(id)
    or type(parsed)~="table" or type(parsed.name)~="string"
    or type(parsed.alternatives)~="table" or #parsed.alternatives==0 then
    error("Dados do caixote inválidos.")
  end
  local record=self.db.lists[id]
  local name=record and record.name or ("CrateShop: "..parsed.name:gsub("^Caixote Extraviado:%s*", ""))
  if type(name)~="string" or name=="" then error("Identidade da lista inválida.") end
  local list=self:Find(manager,name)
  if record then
    if not list or list:GetName()~=record.name or list:IsTemporary()
      or not same(list:GetAllItems(),record.items) then
      error("A lista associada foi alterada, renomeada ou removida. Nenhuma lista será sobrescrita.")
    end
  elseif list then
    error("Já existe uma lista com esse nome sem associação ao CrateShop. Renomeie-a antes de continuar.")
  end
  local items,seen={},{}
  for _,v in ipairs(parsed.alternatives) do
    if type(v.name)~="string" or v.name=="" or v.name:find('[;|"\r\n]')
      or type(v.quantity)~="number" or v.quantity<1 or v.quantity>9007199254740991
      or v.quantity~=math.floor(v.quantity) or seen[v.name] then
      error("Alternativa inválida ou incompatível com a busca exata do Auctionator.")
    end
    seen[v.name]=true
    local item=api.ConvertToSearchString("CrateShop",{
      searchString=v.name, isExact=true, quantity=v.quantity
    })
    if type(item)~="string" or item=="" then error("Falha ao preparar as alternativas.") end
    local decoded=api.ConvertFromSearchString("CrateShop",item)
    if type(decoded)~="table" or decoded.searchString~=v.name
      or decoded.isExact~=true or decoded.quantity~=v.quantity then
      error("O Auctionator não preservou nome e quantidade da alternativa. Nenhuma lista será gravada.")
    end
    items[#items+1]=item
  end
  return {id=id, name=name, items=items, before=list and list:GetAllItems(),
    identity=list and list.data, record=record, manager=manager,
    action=record and "update" or "create"}
end

function Integration:Prepare(id, parsed)
  if self.busy then return nil,"Uma gravação já está em andamento." end
  local ok,ticket=pcall(self.Inspect,self,id,parsed)
  if not ok then return nil,tostring(ticket) end
  -- Keep a private, immutable copy of the source to revalidate on confirmation.
  ticket.parsed={name=parsed.name, alternatives={}}
  for i,v in ipairs(parsed.alternatives) do
    ticket.parsed.alternatives[i]={name=v.name, quantity=v.quantity}
  end
  return ticket
end

function Integration:Commit(ticket)
  if self.busy or type(ticket)~="table" or ticket.used then
    return nil,"Confirmação já utilizada ou indisponível."
  end
  ticket.used=true
  self.busy=true
  local touched, current, list
  local ok,err=pcall(function()
    current=self:Inspect(ticket.id,ticket.parsed)
    if current.manager~=ticket.manager or current.name~=ticket.name
      or current.record~=ticket.record or current.identity~=ticket.identity
      or not same(current.items,ticket.items)
      or (current.before and not same(current.before,ticket.before)) then
      error("Os dados mudaram. Faça Shift+clique novamente para confirmar.")
    end
    touched=true
    if ticket.action=="create" then current.manager:Create(ticket.name) end
    list=current.manager:GetByName(ticket.name)
    if ticket.action=="update" then list:ClearItems() end
    list:AppendItems(copy(ticket.items))
    if not same(list:GetAllItems(),ticket.items) then error("A lista gravada não corresponde às alternativas.") end
    self.db.lists[ticket.id]={name=ticket.name, items=copy(ticket.items)}
  end)
  local rollback=true
  if not ok and touched then
    rollback=pcall(function()
      if ticket.action=="create" then
        if current.manager:GetIndexForName(ticket.name) then current.manager:Delete(ticket.name) end
      else
        local original=current.manager:GetByName(ticket.name)
        if original.data~=ticket.identity then error("A identidade mudou durante a gravação.") end
        original:ClearItems()
        original:AppendItems(copy(ticket.before))
        assert(same(original:GetAllItems(),ticket.before))
      end
    end)
  end
  self.busy=false
  if not ok then
    return nil, "Não foi possível gravar a lista. "..tostring(err)
      .. (rollback and "" or " A reversão também falhou; confira a lista no Auctionator antes de tentar novamente.")
  end
  return true
end
