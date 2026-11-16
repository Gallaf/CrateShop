local passed, failed = 0, 0
function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1; print("PASS " .. name)
  else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
function eq(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
CS = {}
GetLocale=function() return "ptBR" end
local localization=loadfile("CrateShop/Localization.lua")
if localization then localization("CrateShop",CS) end
assert(loadfile("CrateShop/TooltipParser.lua"))("CrateShop", CS)
dofile("tests/parser.lua")
local catalog=loadfile("CrateShop/CrateCatalog.lua")
if catalog then catalog("CrateShop",CS) end
dofile("tests/catalog.lua")
for _, path in ipairs({"tests/integration.lua", "tests/flow.lua"}) do
  local chunk = loadfile(path)
  if chunk then chunk() end
end
dofile("tests/localization.lua")
print(passed .. " passed; " .. failed .. " failed")
if failed > 0 then error("test suite failed") end