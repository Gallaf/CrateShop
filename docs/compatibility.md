# Compatibilidade e decisões técnicas

## Evidências locais — 15/11/2026

Inspeção somente leitura em C:\Program Files (x86)\World of Warcraft\_forever_.

- Wow.exe, FileVersion: 1.60.1.70938.
- Interface/AddOns/Auctionator/Auctionator.toc: versão 346, inclui interface 16001.
- Source/Shopping/Hooks.lua: hook seguro em ChatFrameUtil.InsertLink, fallback ChatEdit_InsertLink. O callback ignora foco nomeado e faz a busca normal na aba Shopping visível.
- Source/API/v1/ShoppingLists.lua: verificadas ConvertToSearchString, ConvertFromSearchString, GetShoppingListItems, CreateShoppingList. Esta última apaga lista de mesmo nome e dispara ListImportFinished.
- Source/Shopping/Mixins/ListManager.lua: Create, Delete, GetCount, GetByIndex, GetByName, GetIndexForName; eventos meta/item.
- Source/Shopping/Mixins/List.lua: GetName, IsTemporary, GetAllItems, ClearItems, AppendItems; campo interno data como identidade de sessão, somente leitura pelo CrateShop.
- Source/Tabs/Shopping/Mixins/Main.lua: ListImportFinished expande a lista; SetOnListExpanded chama DoSearch se AUTO_LIST_SEARCH.
- Source/Tabs/Shopping/Mixins/ListsContainer.lua: ListMetaChange e ListItemChange repopulam a visualização, sem expandir/pesquisar.
- Pesquisa nos consumidores em Source, Source_LegacyAH, Source_Forever, Source_Vanilla não revelou outra pesquisa ligada aos eventos meta/item.
- Source/Search/Advanced.lua: serializa busca exata e quantidade. Nomes contendo delimitadores, aspas, markup residual ou quebras são recusados antes da escrita.

A leitura por C_TooltipInfo.GetHyperlink e as duas capturas reais foram fornecidas como validação prévia pelo usuário. Não houve nova execução dessas APIs no cliente nesta sessão. Não se presume compatibilidade de APIs Retail/Classic não inspecionadas.

## Adaptador deliberadamente restrito

A API pública converte os termos e valida a conversão inversa de nome, busca exata e quantidade antes de qualquer escrita. A criação pública não atende ao requisito de nenhuma busca adicional: por isso o adaptador usa o gerenciador interno somente na versão 346, verificando métodos antes de operar.

Criação: manager:Create(name) e list:AppendItems(entries).
Atualização: list:ClearItems() e list:AppendItems(entries).
Reversão: manager:Delete(name) para criação ou Clear/Append dos itens anteriores para atualização.

Os eventos normais desses métodos permanecem ativos. Não se dispara ListImportFinished, não se expande lista e não se substituem globais, eventos ou configurações. Não há chamadas de pesquisa/compra nem escrita direta em SavedVariables do Auctionator.

O hook do CrateShop é um observador posterior seguro e não modifica argumentos, retorno ou busca original. Além de Shift e AH aberta, rejeita qualquer foco de teclado e janela ativa de edição do chat visível. Ausência do hook suportado desativa detecção com aviso.

Mudança de versão do Auctionator exige reinspeção antes de liberar o adaptador. O bloqueio é proposital mesmo que as funções continuem existindo.

## Parser e dados ausentes

Parser puro recebe data.lines e retorna resultado ou ordinary/invalid.
Remove cores WoW, normaliza CR/LF, separa quebras internas e preserva nomes UTF-8. O parser aceita inteiros positivos exatamente representáveis até 2^53−1, ordem e contagem variáveis. O adaptador recusa quantidades cuja serialização Lua/Auctionator perca precisão, mesmo dentro desse teto. Duplicatas, marcador repetido, bloco vazio e linhas não interpretadas dentro do bloco lógico são inválidos.

O formato observado concentra o bloco em uma linha lógica. Também são aceitas alternativas contíguas em linhas lógicas seguintes quando o marcador está separado; uma linha lógica externa que não é alternativa encerra esse bloco. Quando o marcador já tem alternativas na própria linha lógica, a fronteira dessa linha encerra o bloco; uma recompensa externa com formato semelhante não é incorporada. Nível, preço e extras em linhas externas não viram materiais. Não há inferência pelo nome/ID do item.

Não é possível detectar um tooltip silenciosamente truncado exatamente após uma alternativa válida sem metadados adicionais. O addon não afirma completude além do conteúdo recebido. Se o formato mudar, deve ser revisado antes de ampliar o suporte.

Sem dados de tooltip não há timer, loop ou gravação. Uma mensagem orienta novo Shift+clique após carregamento e é limitada junto aos demais avisos.

## Identidade, obsolescência e atomicidade

O vínculo persistente é Item ID → nome + cópia ordenada das entradas. Antes de atualizar exige correspondência integral. Alterações manuais e renomeações não são incorporadas automaticamente. Outras listas permanecem intactas.

Durante a confirmação são comparados de novo tooltip, nome, entradas, vínculo e identidade do objeto de dados da lista. Isso detecta remoção/recriação idêntica durante o diálogo. Entre sessões, a identidade do objeto Lua desaparece: uma lista recriada com nome e conteúdo exatamente iguais não pode ser distinguida da original pelo vínculo persistente disponível. A associação não constitui um identificador nativo permanente do Auctionator.

As entradas são todas validadas/convertidas antes da primeira alteração. A execução é síncrona, com trava contra reentrada e ticket consumido antes de callbacks. Não há yield nem gravação em Cancelar.

O Auctionator não oferece transação de listas. Callbacks recebem eventos normais; criação pode ficar brevemente vazia até AppendItems. Se ocorrer erro, tenta-se reverter usando os métodos, mas erro persistente nos callbacks pode fazer a própria reversão falhar. O usuário recebe aviso explícito para conferir a lista; o vínculo não é promovido em caso de falha. Não se promete atomicidade diante de encerramento do cliente, interferência reentrante de outros addons ou erro persistente da dependência.

## Verificação e pendências

- TDD parser: observado estado inicial com 14 falhas e 1 teste passando; depois 15 passando.
- TDD integração: 13 falhas por adaptador ausente, depois passando.
- TDD fluxo: 10 falhas por controlador ausente, depois passando.
- Harness Lua 5.1 via Lupa: 41 testes passando, usando mixins, API de listas e serializador **reais instalados**, lidos do disco.
- Fronteiras simuladas: EventBus, frames/eventos WoW, tooltip, metadata e StaticPopup. Um evento de importação ou uso da API pública de criação faz o harness falhar.
- Nenhum teste usa banco, SavedVariables pessoais ou dados econômicos.
- Inspeção estática não equivale a teste dentro do Forever. O roteiro no README é pendente, incluindo taint, posição/legibilidade do diálogo, lifecycle real dos frames e persistência entre sessões.
## Revisão final

Revisão independente somente leitura realizada nesta sessão. Encontrou incorporação indevida de alternativa externa após bloco inline; corrigida com regressão observada falhando e depois passando.
Regressões adicionais reproduziram e corrigiram confirmação presa após erro do diálogo e perda de precisão em quantidades extremas no serializador real.
Verificação final: 41 testes em Lua 5.1, sintaxe dos cinco módulos, referências TOC e ausência de BOM/whitespace indevido.
A revisão não confirmou o FrameXML do StaticPopup nesta build; aparência e ciclo real do diálogo continuam no roteiro de jogo, sem alegação de teste real.

Decisões de execução: reutilizado o diretório solicitado, criado vazio; implementação direta nesta sessão e uma revisão independente; sem worktree extra. Nenhum commit foi criado, conforme autorização do pedido. A pasta .tools contém somente ferramenta de desenvolvimento ignorada pelo Git.
