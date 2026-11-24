# Expandir lista existente no Shift+clique

Objetivo: quando a lista própria já estiver atualizada, selecionar e expandir no Auctionator sem diálogo ou escrita. Criação, atualização necessária e migração mantêm confirmação.

Implementação: Core continua lendo o tooltip e preparando o ticket; Integration verifica nome, conteúdo e versão do catálogo antes de abrir. Usar ContainerTabs:SetView(ShoppingListViews.Lists) e ListsContainer:ExpandList, conforme o fluxo nativo inspecionado no Auctionator. Lista já expandida só recebe ScrollToList. Não substituir callbacks nem alterar configurações; a preferência AUTO_LIST_SEARCH governa a expansão nativa. UI ausente/incompatível gera erro localizado, sem gravar.

- [x] Adicionar regressões e observar falha antes da implementação.
- [x] Implementar abertura para lista própria atualizada e preservar proteções existentes.
- [x] Testar criação, expansão, repetição, UI indisponível, lista alterada/ausente e atualização necessária.
- [x] Atualizar documentação e executar suíte Lua 5.1, sintaxe/TOC e diff.

Limite: testes fora do jogo, com método ExpandList do Auctionator instalado e fronteiras de UI simuladas. A aparência e seleção real no cliente dependem de validação do usuário. Não publicar ou integrar ao GitHub neste incremento sem pedido.
