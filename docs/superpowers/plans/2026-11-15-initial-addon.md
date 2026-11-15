# CrateShop Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline. O pedido autoriza execução contínua e dispensa nova aprovação de design; não fazer commits.

**Goal:** Criar e atualizar listas de alternativas de caixotes após confirmação.
**Architecture:** Parser puro; adaptador Auctionator 346; controlador de confirmação; detector por hook seguro. SavedVariables próprias guardam Item ID, nome e cópia das entradas aprovadas.
**Tech Stack:** Lua 5.1, TOC 16001; Lupa somente para desenvolvimento.
**Spec:** docs/specification.txt

## Global Constraints
- Não modificar instalação, outros repositórios ou SavedVariables existentes.
- Sem buscas adicionais, compras, catálogo fixo ou dependências de execução.
- Não fazer push, remoto, publicação ou commit.
- Dependência obrigatória Auctionator; recusar versões internas não verificadas.

## Review Focus
- Mesmo nome com conteúdo alterado: recusar atualização.
- Remoção/recriação durante confirmação: recusar dados obsoletos.
- Falha de callback após mutação: rollback por métodos, com limites explícitos.
- Linha inválida depois de uma válida: recusar bloco inteiro.
- Chat focado e clique repetido: não abrir/substituir confirmação nem duplicar escrita.

### Task 1: Parser
Files: CrateShop/TooltipParser.lua, tests/parser.lua.
Interface: Parse(lines) -> result {name, alternatives {name, quantity}} ou nil, ordinary/invalid.
- [x] Escrever testes das capturas, formato variável, ambiguidades e linhas extras.
- [x] Executar e observar falha por parser ainda ausente.
- [x] Implementar parser estrutural e executar suite até passar.

### Task 2: Integração e fluxo
Files: CrateShop/AuctionatorIntegration.lua, Core.lua, CrateDetector.lua, ConfirmationDialog.lua, CrateShop.toc; tests/integration.lua, tests/flow.lua.
Interfaces: Integration.New(db); Prepare(id, parsed); Commit(ticket). Core.Observe(link), Accept(), Cancel().
- [x] Escrever harness com mixins reais instalados e fronteiras do cliente simuladas.
- [x] Observar falhas antes de implementar integração e fluxo.
- [x] Implementar propriedade conservadora, revalidação, rollback limitado e diálogo.
- [x] Testar cancelamento, colisões, atualização, renomeação, falhas, hooks e ausência de pesquisa.

### Task 3: Entrega
Files: README.md, docs/compatibility.md.
- [x] Revisar código e dependências; executar todos os testes Lua 5.1.
- [x] Registrar evidências locais e checklist pendente no Forever.
- [x] Conferir TOC, sintaxe, Git e arquivos entregues sem instalar.
## Resultado e decisões de execução

- Task 1: completa. RED 14 falhas/1 sucesso, GREEN 15/0; regressão de limite do bloco adicionada após revisão.
- Task 2: completa. RED integração 13 falhas; RED fluxo 10 falhas; GREEN inicial 38/0.
- Task 3: completa. Revisão independente encontrou P2 do bloco externo, corrigido via RED→GREEN. Erro de diálogo e arredondamento também cobertos por regressões RED→GREEN.
- Verificação final: python tests/run.py → 41/0; python tests/check_package.py → sintaxe Lua 5.1, cinco módulos, TOC e texto válidos.
- Ruling: execução direta autorizada no pedido dispensa aprovação adicional do plano; repositório novo sem histórico/commits, portanto revisão usou os arquivos presentes em vez de intervalo de SHAs. Nenhum commit, push ou remoto.
- Ruling: API pública CreateShoppingList incompatível com nenhuma busca adicional; usado adaptador interno restrito ao Auctionator 346, com eventos normais. Custo: reinspeção obrigatória para liberar outra versão.
- Ruling: falta de tooltip orienta repetir gesto, sem retries; identidade de listas idênticas entre sessões e truncagem silenciosa não são detectáveis com as informações disponíveis. Limites expostos na documentação.

## Autorização posterior de integração

Após a entrega local, o proprietário indicou Gallaf/CrateShop como origin e autorizou commit, envio, criação de PR e merge. Como o remoto estava vazio, a integração usa um commit raiz vazio em main e mantém a implementação no PR da branch codex/initial-addon. As restrições anteriores de não enviar/commitar registram a etapa inicial e foram substituídas por essa autorização explícita.
