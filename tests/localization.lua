local function loadLocale(locale)
  local ns={}
  GetLocale=locale and function() return locale end or nil
  assert(loadfile("CrateShop/Localization.lua"))("CrateShop",ns)
  return ns.L
end

test("missing GetLocale defaults to English",function()
  eq(loadLocale(nil).CANCEL,"Cancel")
  eq(loadLocale("frFR").CANCEL,"Cancel")
end)

test("all translations preserve placeholder types and can be formatted",function()
  local english,portuguese=loadLocale("enUS"),loadLocale("ptBR")
  local function signature(text)
    local result,args={},{}
    for spec in text:gmatch("%%([sd])") do
      result[#result+1]=spec
      args[#args+1]=spec=="d" and 12 or "Game name 100% é"
    end
    return table.concat(result),args
  end
  for key,text in pairs(english) do
    local expected,args=signature(text)
    local translated=assert(rawget(portuguese,key),key)
    eq(signature(translated),expected)
    assert(string.format(text,unpack(args)))
    assert(string.format(translated,unpack(args)))
  end
  eq(string.format(portuguese.LIST_CREATED,"Nome 100% é"),"Lista criada: Nome 100% é.")
  eq(portuguese.TOOLTIP_CHANGED,"O tooltip mudou ou está indisponível. Faça Shift+clique novamente.")
end)
