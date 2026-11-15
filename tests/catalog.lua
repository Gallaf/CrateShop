CanonicalNames={
  [3820]="Estrangulalga", [2453]="Ervamossa", [3355]="Ácera-agreste",
  [3369]="Musgo de Tumba", [3356]="Sangue-real",
  [2776]="Minério de Ouro", [3858]="Minério de Mithril",
}
function setupItemData()
  local requests={}
  C_Item={
    GetItemInfo=function(id)
      return CanonicalNames[id], CanonicalNames[id] and ("|Hitem:"..id..":|h[item]|h")
    end,
    RequestLoadItemDataByID=function(id) requests[#requests+1]=id end,
  }
  return requests
end
local function catalog()
  return assert(CS.Catalog,"catálogo ainda não implementado")
end
test("plantas resolvem cinco IDs sem singularização de compostos",function()
  setupItemData()
  local r=catalog().Resolve(248686,assert(CS.Parser.Parse(Fixtures.herbs)))
  eq(#r.alternatives,5)
  eq(r.alternatives[1].id,3820); eq(r.alternatives[1].name,"Estrangulalga")
  eq(r.alternatives[4].id,3369); eq(r.alternatives[4].name,"Musgo de Tumba")
  eq(r.alternatives[5].id,3356); eq(r.alternatives[5].name,"Sangue-real")
  eq(r.alternatives[5].quantity,10)
  assert(type(r.version)=="string" and r.version~="")
end)
test("minérios resolvem IDs e quantidades diferentes",function()
  setupItemData()
  local r=catalog().Resolve(248692,assert(CS.Parser.Parse(Fixtures.ores)))
  eq(r.alternatives[1].id,2776); eq(r.alternatives[1].quantity,10)
  eq(r.alternatives[2].id,3858); eq(r.alternatives[2].quantity,20)
  eq(r.alternatives[2].name,"Minério de Mithril")
end)
test("ordem dos requisitos não associa nome a ID por posição",function()
  setupItemData()
  local p=assert(CS.Parser.Parse(Fixtures.ores))
  p.alternatives[1],p.alternatives[2]=p.alternatives[2],p.alternatives[1]
  local r=catalog().Resolve(248692,p)
  eq(r.alternatives[1].name,"Minério de Ouro"); eq(r.alternatives[1].quantity,10)
  eq(r.alternatives[2].name,"Minério de Mithril"); eq(r.alternatives[2].quantity,20)
end)
test("caixote fora do catálogo não usa texto plural como fallback",function()
  setupItemData()
  assert(not pcall(catalog().Resolve,999999,assert(CS.Parser.Parse(Fixtures.herbs))))
end)
test("contagem e quantidades divergentes bloqueiam",function()
  setupItemData()
  local p=assert(CS.Parser.Parse(Fixtures.ores))
  p.alternatives[2].quantity=19
  assert(not pcall(catalog().Resolve,248692,p))
  table.remove(p.alternatives)
  assert(not pcall(catalog().Resolve,248692,p))
end)
test("material indisponível bloqueia e solicita carga uma única vez",function()
  local requests=setupItemData()
  local available=C_Item.GetItemInfo
  C_Item.GetItemInfo=function(id) if id~=3356 then return available(id) end end
  local p=assert(CS.Parser.Parse(Fixtures.herbs))
  assert(not pcall(catalog().Resolve,248686,p))
  assert(not pcall(catalog().Resolve,248686,p))
  eq(#requests,1); eq(requests[1],3356)
  C_Item.GetItemInfo=available
  eq(catalog().Resolve(248686,p).alternatives[5].name,"Sangue-real")
end)
test("nome ou link inconsistente não confirma identidade do material",function()
  setupItemData()
  local original=C_Item.GetItemInfo
  C_Item.GetItemInfo=function(id)
    if id==2776 then return "Item errado","|Hitem:1:|h[Item errado]|h" end
    return original(id)
  end
  assert(not pcall(catalog().Resolve,248692,assert(CS.Parser.Parse(Fixtures.ores))))
end)
test("APIs de itens indisponíveis não produzem nomes fictícios",function()
  C_Item=nil
  assert(not pcall(catalog().Resolve,248692,assert(CS.Parser.Parse(Fixtures.ores))))
end)
