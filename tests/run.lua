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
assert(loadfile("CrateShop/TooltipParser.lua"))("CrateShop", CS)
dofile("tests/parser.lua")
for _, path in ipairs({"tests/integration.lua", "tests/flow.lua"}) do
  local chunk = loadfile(path)
  if chunk then chunk() end
end
print(passed .. " passed; " .. failed .. " failed")
if failed > 0 then error("test suite failed") end