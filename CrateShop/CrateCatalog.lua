-- Numeric game facts: What's It For? data v1.1.40, Forever 1.60.1.70938.
-- Provenance and update procedure: docs/catalog.md. No runtime dependency.
local _, NS = ...
local Catalog = {version="2026-11-15.1", build="1.60.1.70938"}
NS.Catalog = Catalog

-- [crate item ID] = { {material item ID, required quantity}, ... }
local crates = {
  [248682]={{2447,20},{765,20},{2449,10},{785,10},{2450,10}},
  [248683]={{2770,20},{2771,20}},
  [248684]={{2589,40},{2318,20}},
  [248685]={{10940,20},{10939,4},{10978,6},{11084,2}},
  [248686]={{3820,10},{2453,10},{3355,10},{3369,10},{3356,10}},
  [248687]={{2775,10},{2772,20}},
  [248688]={{2592,20},{4306,40},{2319,20}},
  [248689]={{11083,20},{11082,4},{11138,6},{11139,2}},
  [248690]={{3357,20},{3818,10},{3821,10},{3358,10}},
  [248691]={{3819,10},{4625,10},{8831,20},{8836,10}},
  [248692]={{2776,10},{3858,20}},
  [248693]={{4338,40},{4234,20}},
  [248694]={{11137,20},{11135,4},{11177,6},{11178,2}},
  [248695]={{13464,10},{8838,20},{8839,10},{8845,10},{8846,10}},
  [248696]={{13463,20},{13465,20},{13466,20},{13467,20}},
  [248697]={{7911,10},{10620,20},{11099,20}},
  [248698]={{14047,40},{4304,20},{8170,20}},
  [248699]={{11176,20},{11175,4},{14343,6},{14344,2}},
  [248702]={{4231,2},{2996,20}},
  [248703]={{2840,20},{3576,20},{2841,10}},
  [248704]={{4359,16},{4361,16},{4363,4}},
  [248705]={{2997,6},{4305,10},{4233,2}},
  [248706]={{2842,10},{3575,20}},
  [248707]={{4371,8},{4375,7},{4382,4},{10558,45}},
  [248708]={{4339,8},{4236,2}},
  [248709]={{3860,20},{3859,15},{3577,10}},
  [248710]={{4387,8},{10559,5},{10560,12},{10561,5}},
  [248711]={{14048,8},{8172,2}},
  [248712]={{11371,2},{6037,10},{12359,20}},
  [248713]={{15994,5},{18631,5},{16000,2}},
}
local requested = {}

function Catalog.Resolve(crateID, parsed)
  local options=crates[crateID]
  if not options then
    error("Caixote fora do catálogo "..Catalog.version..". Atualize o CrateShop para obter suporte.",0)
  end
  if type(parsed)~="table" or type(parsed.alternatives)~="table"
    or #parsed.alternatives~=#options then
    error("O tooltip diverge do catálogo de materiais. Nenhuma lista será gravada.",0)
  end
  local expected,received={},{}
  for i,option in ipairs(options) do expected[i]=option[2] end
  for i,alternative in ipairs(parsed.alternatives) do
    if type(alternative)~="table" or type(alternative.name)~="string" or alternative.name==""
      or type(alternative.quantity)~="number" or alternative.quantity<1
      or alternative.quantity~=math.floor(alternative.quantity) then
      error("Requisitos inválidos para comparação com o catálogo.",0)
    end
    received[i]=alternative.quantity
  end
  table.sort(expected); table.sort(received)
  for i,quantity in ipairs(expected) do
    if received[i]~=quantity then
      error("As quantidades do tooltip divergem do catálogo. Nenhuma lista será gravada.",0)
    end
  end
  if not C_Item or type(C_Item.GetItemInfo)~="function" then
    error("API de nomes de itens indisponível. Nenhuma lista será gravada.",0)
  end
  local result={version=Catalog.version,alternatives={}}
  local missing={}
  for _,option in ipairs(options) do
    local id,quantity=option[1],option[2]
    local name,link=C_Item.GetItemInfo(id)
    if type(name)~="string" or name=="" or type(link)~="string" then
      missing[#missing+1]=tostring(id)
      if not requested[id] and type(C_Item.RequestLoadItemDataByID)=="function" then
        requested[id]=true
        C_Item.RequestLoadItemDataByID(id)
      end
    else
      if tonumber(link:match("|Hitem:(%d+):"))~=id then
        error("O cliente devolveu uma identidade de material inconsistente. Nenhuma lista será gravada.",0)
      end
      result.alternatives[#result.alternatives+1]={id=id,name=name,quantity=quantity}
    end
  end
  if #missing>0 then
    error("Nomes de materiais ainda não carregados (IDs: "..table.concat(missing,", ")
      .."). Aguarde e faça Shift+clique novamente.",0)
  end
  return result
end
