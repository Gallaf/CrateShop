local _, NS = ...
local L = NS.L
local Integration = {}
local MIN_AUCTIONATOR_VERSION = 346
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
  local versionNumber=type(version)=="string" and tonumber(version:match("^%d+$"))
  if not versionNumber or versionNumber<MIN_AUCTIONATOR_VERSION then
    error(string.format(L.VERSION_REQUIRED,MIN_AUCTIONATOR_VERSION,tostring(version or L.UNAVAILABLE)),0)
  end
  if not requireMethods(api, {"ConvertToSearchString", "ConvertFromSearchString", "GetShoppingListItems"})
    or not requireMethods(manager, {"Create","Delete","Sort","GetCount","GetByIndex","GetByName","GetIndexForName"})
    or not requireMethods(AuctionatorShoppingListMixin, {"GetName","GetAllItems","ClearItems","AppendItems","Rename","IsTemporary"})
    or type(self.db)~="table" or type(self.db.lists)~="table" then
    error(L.NO_INTERFACES,0)
  end
  return manager, api
end

-- Names are checked case-insensitively as a conservative collision policy.
function Integration:Find(manager, name)
  local found
  for i=1,manager:GetCount() do
    local list=manager:GetByIndex(i)
    if list:GetName():lower()==name:lower() then
      if found then error(L.AMBIGUOUS_LISTS) end
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
    error(L.BAD_CRATE)
  end
  local record=self.db.lists[id]
  local name="CS: "..parsed.name:gsub("^Caixote Extraviado:%s*", "")
  if name=="CS: " then error(L.BAD_IDENTITY,0) end
  local list
  if record then
    if type(record)~="table" or type(record.name)~="string" then
      error(L.BAD_ASSOCIATION,0)
    end
    list=self:Find(manager,record.name)
    if list and (list:GetName()~=record.name or list:IsTemporary()
      or not same(list:GetAllItems(),record.items)) then
      error(L.EDITED_LIST,0)
    end
  end
  if list then name=record.name:gsub("^CrateShop:","CS:") end
  local destination=self:Find(manager,name)
  if destination and (not list or destination.data~=list.data) then
    error(L.COLLISION,0)
  end
  if not NS.Catalog or type(NS.Catalog.Resolve)~="function" then
    error(L.NO_CATALOG,0)
  end
  local resolved=NS.Catalog.Resolve(id,parsed)
  local items,seen={},{}
  for _,v in ipairs(resolved.alternatives) do
    if type(v.name)~="string" or v.name=="" or v.name:find('[;|"\r\n]')
      or type(v.quantity)~="number" or v.quantity<1 or v.quantity>9007199254740991
      or v.quantity~=math.floor(v.quantity) or seen[v.name] then
      error(L.BAD_ALTERNATIVE)
    end
    seen[v.name]=true
    local item=api.ConvertToSearchString("CrateShop",{
      searchString=v.name, isExact=true, quantity=v.quantity
    })
    if type(item)~="string" or item=="" then error(L.PREPARE_FAILED) end
    local decoded=api.ConvertFromSearchString("CrateShop",item)
    if type(decoded)~="table" or decoded.searchString~=v.name
      or decoded.isExact~=true or decoded.quantity~=v.quantity then
      error(L.SEARCH_CHANGED)
    end
    items[#items+1]=item
  end
  return {id=id, name=name, sourceName=list and list:GetName(), items=items,
    catalogVersion=resolved.version, before=list and list:GetAllItems(),
    identity=list and list.data, record=record, manager=manager,
    action=list and "update" or "create"}
end

function Integration:Prepare(id, parsed)
  if self.busy then return nil,L.BUSY end
  local ok,ticket=pcall(self.Inspect,self,id,parsed)
  if not ok then return nil,tostring(ticket) end
  -- Keep a private, immutable copy of the source to revalidate on confirmation.
  ticket.parsed={name=parsed.name, alternatives={}}
  for i,v in ipairs(parsed.alternatives) do
    ticket.parsed.alternatives[i]={name=v.name, quantity=v.quantity}
  end
  return ticket
end

-- Opening is a UI action only; obsolete contents and legacy names still need confirmation.
function Integration:OpenIfCurrent(ticket)
  if ticket.action~="update" or ticket.sourceName~=ticket.name
    or ticket.record.catalogVersion~=ticket.catalogVersion
    or not same(ticket.before,ticket.items) then return false end
  if self.busy then return nil,L.BUSY end
  self.busy=true
  local ok,err=pcall(function()
    local manager=self:Compatible()
    local list=self:Find(manager,ticket.sourceName)
    if manager~=ticket.manager or not list or list.data~=ticket.identity
      or self.db.lists[ticket.id]~=ticket.record or list:IsTemporary()
      or not same(list:GetAllItems(),ticket.items) then error(L.DATA_CHANGED,0) end
    local frame=AuctionatorShoppingFrame
    local container=frame and frame.ListsContainer
    local tabs=frame and frame.ContainerTabs
    local views=Auctionator.Constants.ShoppingListViews
    if not frame or type(frame.IsShown)~="function" or not frame:IsShown()
      or not requireMethods(container,{"ExpandList","GetExpandedList","ScrollToList"})
      or not requireMethods(tabs,{"SetView"}) or not views or views.Lists==nil then
      error(L.NO_LIST_UI,0)
    end
    tabs:SetView(views.Lists)
    local expanded=container:GetExpandedList()
    if expanded and expanded.data==list.data then
      container:ScrollToList(list)
    else
      -- Native callbacks deliberately respect the player's AUTO_LIST_SEARCH preference.
      container:ExpandList(list)
    end
  end)
  self.busy=false
  if not ok then return nil,string.format(L.OPEN_LIST_FAILED,tostring(err)) end
  return true
end

function Integration:Commit(ticket)
  if self.busy or type(ticket)~="table" or ticket.used then
    return nil,L.USED_CONFIRMATION
  end
  ticket.used=true
  self.busy=true
  local touched, current, list
  local ok,err=pcall(function()
    current=self:Inspect(ticket.id,ticket.parsed)
    if current.sourceName~=ticket.sourceName or current.action~=ticket.action
      or current.catalogVersion~=ticket.catalogVersion
      or current.manager~=ticket.manager or current.name~=ticket.name
      or current.record~=ticket.record or current.identity~=ticket.identity
      or not same(current.items,ticket.items)
      or (current.before and not same(current.before,ticket.before)) then
      error(L.DATA_CHANGED)
    end
    if ticket.action=="update" then
      list=current.manager:GetByName(ticket.sourceName)
    end
    touched=true
    if ticket.action=="create" then
      current.manager:Create(ticket.name)
      list=current.manager:GetByName(ticket.name)
    else
      if ticket.sourceName~=ticket.name then
        list:Rename(ticket.name)
        current.manager:Sort()
      end
      list:ClearItems()
    end
    list:AppendItems(copy(ticket.items))
    if list:GetName()~=ticket.name or not same(list:GetAllItems(),ticket.items) then
      error(L.SAVED_MISMATCH,0)
    end
    self.db.lists[ticket.id]={name=ticket.name, items=copy(ticket.items), catalogVersion=ticket.catalogVersion}
  end)
  local rollback=true
  if not ok and touched then
    rollback=pcall(function()
      if ticket.action=="create" then
        if current.manager:GetIndexForName(ticket.name) then current.manager:Delete(ticket.name) end
      else
        local original=current.manager:GetByName(list:GetName())
        if original.data~=ticket.identity then error(L.IDENTITY_CHANGED) end
        original:ClearItems()
        original:AppendItems(copy(ticket.before))
        if original:GetName()~=ticket.sourceName then
          original:Rename(ticket.sourceName)
          current.manager:Sort()
        end
        assert(original:GetName()==ticket.sourceName and same(original:GetAllItems(),ticket.before))
      end
    end)
  end
  self.busy=false
  if not ok then
    return nil, string.format(rollback and L.SAVE_FAILED or L.ROLLBACK_FAILED,tostring(err))
  end
  return true
end
