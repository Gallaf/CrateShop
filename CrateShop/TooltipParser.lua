local _, NS = ...
local Parser = {}
NS.Parser = Parser
local function invalid(reason, line, text, expected)
  return nil, "invalid", {reason=reason, line=line, text=text, expected=expected}
end
local marker = "Encha o caixote com qualquer conjunto da lista a seguir:"

local function clean(text)
  return (text:gsub("|cn[%a_][%w_]*:", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    :gsub("\r\n", "\n"):gsub("\r", "\n"):match("^%s*(.-)%s*$"))
end

-- A logical tooltip line can contain the entire requirements block.
-- Within that line every nonempty fragment after the marker must parse.
function Parser.Parse(lines)
  if type(lines) ~= "table" then return nil, "ordinary" end
  local fragments, found, start, owner = {}, 0
  for i, line in ipairs(lines) do
    if type(line) == "table" and type(line.leftText) == "string" then
      for text in (clean(line.leftText) .. "\n"):gmatch("(.-)\n") do
        text = clean(text)
        fragments[#fragments + 1] = {text=text, owner=i}
        local _, count = text:gsub(marker, "")
        if count > 0 then
          found = found + count
          start, owner = #fragments, i
          if text ~= marker and text ~= "Usar: " .. marker then
            return invalid("marker", i, text, "Usar: "..marker)
          end
        end
      end
    end
  end
  if found == 0 then return nil, "ordinary" end
  if found ~= 1 or not fragments[1] or fragments[1].text == "" or start == 1 then
    return invalid("structure", owner, fragments[start] and fragments[start].text)
  end
  local result = {name=fragments[1].text, alternatives={}}
  local inline = false
  for i=start+1,#fragments do
    if fragments[i].owner~=owner then break end
    if fragments[i].text~="" then inline=true end
  end
  local seen, ended = {}, false
  for i = start + 1, #fragments do
    local f = fragments[i]
    if inline and f.owner~=owner then break end
    if f.text ~= "" and not ended then
      if f.owner ~= owner and f.text:sub(1,1) ~= "-" then
        ended = true
      else
        local digits, name = f.text:match("^%-%s+(%d+)%s+(.+)$")
        name = name and clean(name)
        local quantity = digits and tonumber(digits)
        if not quantity or quantity < 1 or quantity > 9007199254740991
          or quantity ~= math.floor(quantity) or not name or name == ""
          or name:find("|", 1, true) or seen[name] then
          return invalid("alternative", f.owner, f.text)
        end
        seen[name] = true
        result.alternatives[#result.alternatives + 1] = {name=name, quantity=quantity}
      end
    end
  end
  if #result.alternatives == 0 then return invalid("empty", owner, fragments[start].text) end
  return result
end
