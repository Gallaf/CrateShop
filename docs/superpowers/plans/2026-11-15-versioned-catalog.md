# CrateShop Versioned Catalog Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans inline, com TDD e revisão independente final. Pedido inicial dispensa aprovação extra do plano.

**Goal:** Gerar buscas exatas com nomes canônicos obtidos por IDs.
**Architecture:** CrateCatalog.lua guarda dados versionados e resolve nomes. AuctionatorIntegration chama Resolve antes de serializar; Core preserva validação do tooltip original.
**Tech Stack:** Lua 5.1 e APIs existentes; sem dependência runtime nova.
**Spec:** docs/superpowers/specs/2026-11-15-versioned-catalog-design.md

## Global Constraints
- Sem singularização heurística, pesquisas/compras automáticas ou alterações em outros addons.
- Preservar correções locais e listas manuais; instalar somente CrateShop.
- Não copiar código do provedor de dados; registrar procedência dos fatos numéricos.
- Sem commit, push ou merge nesta etapa.

## Review Focus
- Ordem do tooltip não define associação com IDs.
- Nome ausente ou link de ID divergente impede gravação.
- Atualizar listas legadas em plural somente se ainda forem próprias e intactas.
- Divergência de tooltip/catálogo e caixote desconhecido bloqueiam.
- Confirmação revalida os termos e versão do catálogo.

### Task 1: Catálogo e resolução
Files: CrateShop/CrateCatalog.lua; tests/catalog.lua; tests/run.lua.
Produces: Catalog.Resolve(crateID, parsed) -> {alternatives={id,name,quantity}, version}, ou erro antes de escrita.
- [x] Escrever testes de IDs reais, nomes singulares compostos, ausência, carga limitada, ID errado, ordem e divergência.
- [x] Observar falha por ausência de catálogo.
- [x] Implementar e passar os testes.

### Task 2: Integração e entrega
Files: AuctionatorIntegration.lua, CrateShop.toc, tests/integration.lua, tests/flow.lua, README e docs.
Consumes: Catalog.Resolve; preserves ticket.parsed original.
- [x] Ajustar fixtures para caixotes reais; reproduzir falha com termos plurais e atualização legada.
- [x] Integrar resolução/revalidação mantendo propriedade, rollback e ausência de pesquisas.
- [x] Executar suíte e checks do pacote; revisão independente das alterações.
- [x] Instalar arquivos próprios verificados e orientar teste de Atualizar lista no cliente.

## Resultado da execução

- Catálogo: oito testes inicialmente falharam; depois passaram.
- Integração: seis regressões falharam antes de usar o catálogo; depois passaram.
- Suite final: 67 testes Lua 5.1, check_package.py, sintaxe de seis módulos, TOC e diff válidos.
- Revisão independente somente leitura: sem bugs acionáveis. Conferência numérica independente confirmou 30 caixotes/96 alternativas idênticos à fonte declarada.
- Decisões rotineiras: catálogo autoritativo de IDs/quantidades, comparação numérica do tooltip sem associação posicional, bloqueio de nomes indisponíveis e atualização explícita da lista legada. Custo/limite: mudanças de materiais com mesmo perfil numérico não são detectadas e novos caixotes precisam atualizar dados.
- Instalação: somente arquivos do CrateShop copiados e conferidos por SHA-256; nenhuma SavedVariable ou arquivo de outro addon alterado.
- Validação real do catálogo/Atualizar lista pendente no cliente. Sem commit/push/merge nesta etapa.

## Integração autorizada

Após validar o funcionamento, o usuário solicitou consolidar a documentação, criar commit, enviar a branch, abrir PR e fazer merge em main. Essa instrução substitui a restrição de integração das etapas locais anteriores. Evidências finais e limites estão em docs/compatibility.md.
