local marker = "Usar: Encha o caixote com qualquer conjunto da lista a seguir:"
Fixtures = {
  herbs = {
    {leftText="Caixote Extraviado: Plantas de Profissional"},
    {leftText=marker .. "\n- 10 Estrangulalgas\n- 10 Ervamossas\n- 10 Áceras-agrestes\n- 10 Musgos-de-tumba\n- 10 Sangues-reais"},
    {leftText="Requer o Nível 10"},
  },
  ores = {
    {leftText="Caixote Extraviado: Minérios de Especialista"},
    {leftText=marker .. "\n- 10 Minérios de Ouro\n- 20 Minérios de Mithril"},
    {leftText="Requer o Nível 20"},
  }
}
test("captura plantas preserva cinco alternativas localizadas", function()
  local p = assert(CS.Parser.Parse(Fixtures.herbs))
  eq(p.name, "Caixote Extraviado: Plantas de Profissional")
  eq(#p.alternatives, 5)
  eq(p.alternatives[3].name, "Áceras-agrestes")
  eq(p.alternatives[5].quantity, 10)
end)
test("captura minérios preserva quantidades distintas", function()
  local p = assert(CS.Parser.Parse(Fixtures.ores))
  eq(#p.alternatives, 2)
  eq(p.alternatives[2].name, "Minérios de Mithril")
  eq(p.alternatives[2].quantity, 20)
end)
test("novo nome cores CRLF ordem e quantidade variáveis", function()
  local p = assert(CS.Parser.Parse({
    {leftText="|cffaabbccCaixa desconhecida|r"},
    {leftText="|cff00ff00" .. marker .. "|r\r\n- 37 Material ç\n\n- 1 Outro material"}
  }))
  eq(p.name, "Caixa desconhecida")
  eq(#p.alternatives, 2)
  eq(p.alternatives[1].quantity, 37)
  eq(p.alternatives[1].name, "Material ç")
end)
test("alternativas em linhas lógicas separadas e extras externas", function()
  local p = assert(CS.Parser.Parse({
    {leftText="Caixa"}, {leftText="Preço 123"},
    {leftText=marker}, {leftText="- 2 Prata"}, {leftText="- 9 Ouro"},
    {leftText="Requer o Nível 20"}, {leftText="- 100 Recompensa"}
  }))
  eq(#p.alternatives, 2)
end)
test("item comum é silencioso inclusive nome parecido", function()
  local p, status = CS.Parser.Parse({{leftText="Caixote Extraviado"}, {leftText="Nível 10"}})
  eq(p, nil); eq(status, "ordinary")
end)
local invalid = {
  {"bloco vazio", {{leftText="Caixa"},{leftText=marker}}},
  {"zero", {{leftText="Caixa"},{leftText=marker.."\n- 0 Ouro"}}},
  {"negativo", {{leftText="Caixa"},{leftText=marker.."\n- -2 Ouro"}}},
  {"decimal", {{leftText="Caixa"},{leftText=marker.."\n- 1.5 Ouro"}}},
  {"nome ausente", {{leftText="Caixa"},{leftText=marker.."\n- 2 "}}},
  {"parcial", {{leftText="Caixa"},{leftText=marker.."\n- 2 Ouro\n- inválido"}}},
  {"texto interno desconhecido", {{leftText="Caixa"},{leftText=marker.."\n- 2 Ouro\ncontinua?\n- 3 Prata"}}},
  {"marcador repetido", {{leftText="Caixa"},{leftText=marker.."\n- 2 Ouro"},{leftText=marker.."\n- 3 Prata"}}},
  {"alternativa duplicada", {{leftText="Caixa"},{leftText=marker.."\n- 2 Ouro\n- 3 Ouro"}}},
  {"quantidade imprecisa", {{leftText="Caixa"},{leftText=marker.."\n- 9007199254740992 Ouro"}}},
}
for _, case in ipairs(invalid) do
  test("recusa " .. case[1], function()
    local p, status = CS.Parser.Parse(case[2])
    eq(p, nil); eq(status, "invalid")
  end)
end
test("linha externa com formato de recompensa não amplia bloco inline", function()
  local p=assert(CS.Parser.Parse({
    {leftText="Caixa"},
    {leftText="Usar: Encha o caixote com qualquer conjunto da lista a seguir:\n- 2 Ouro"},
    {leftText="- 100 Recompensa"}
  }))
  eq(#p.alternatives,1); eq(p.alternatives[1].name,"Ouro")
end)
