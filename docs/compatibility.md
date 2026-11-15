# Compatibilidade e decisões técnicas

## Estado atual

CrateShop 0.2.1: cliente Forever 1.60.1.70938, interface 16001 e Auctionator numérico 346 ou superior. Interfaces inspecionadas nas versões 346 e 347; o harness atual lê as fontes reais da 347 instalada. A versão mínima foi pedida pelo usuário; a presença dos métodos não certifica o comportamento de implementações futuras.

O escopo vigente inclui catálogo versionado, prefixo CS:, migração de listas próprias e reimportação quando o nome associado não existir. Essas decisões substituem as exigências iniciais correspondentes em specification.txt. A confirmação antes de gravar permanece obrigatória.

## Evidências das interfaces

Inspeção somente leitura em Interface/AddOns/Auctionator:

| Fonte | Contrato relevante |
| --- | --- |
| Auctionator.toc | Versão e interface do addon instalado. |
| Source/Shopping/Hooks.lua | Hook seguro em ChatFrameUtil.InsertLink, fallback ChatEdit_InsertLink; pesquisa original do Shift+clique. |
| Source/API/v1/ShoppingLists.lua | Conversão pública de termos, leitura de listas e criação que substitui nome existente e emite ListImportFinished. |
| Source/Shopping/Mixins/ListManager.lua | Create, Delete, Sort, GetCount, GetByIndex, GetByName e GetIndexForName; eventos meta/item. |
| Source/Shopping/Mixins/List.lua | GetName, IsTemporary, GetAllItems, Rename, ClearItems e AppendItems; data como identidade de sessão. |
| Source/Tabs/Shopping/Mixins/Main.lua | ListImportFinished expande a lista e pode iniciar busca por AUTO_LIST_SEARCH. |
| Source/Tabs/Shopping/Mixins/ListsContainer.lua | Eventos meta/item repopulam sem expandir/pesquisar. |
| Source/Search/Advanced.lua | Serialização de busca exata e quantidade. |

Os consumidores também foram pesquisados em Source_LegacyAH, Source_Forever e Source_Vanilla. Nenhum arquivo de outro addon foi alterado.

## Integração sem pesquisa adicional

A API pública converte os termos; a conversão inversa confere nome, busca exata e quantidade. A criação pública não atende ao comportamento exigido, então o adaptador usa métodos internos verificados:

- Criar: Create e AppendItems.
- Atualizar: ClearItems e AppendItems.
- Migrar nome: Rename e Sort.
- Reverter: Delete da lista nova ou restauração das entradas/nome anteriores.

Eventos normais desses métodos permanecem ativos. O CrateShop não emite ListImportFinished, não expande listas, não chama pesquisa/compra, não altera configurações nem escreve diretamente em SavedVariables do Auctionator. Expandir ou pesquisar manualmente continua seguindo as configurações do jogador.

A versão mínima, APIs e métodos usados são conferidos antes da operação. Metadata ausente/não numérica, versão antiga ou interface incompleta bloqueiam com mensagem útil.

## Detecção, parser e nomes

O hook é somente observador e não modifica retorno/argumentos do handler original. Exige AH aberta, Shift e hyperlink de item. Chat visível/focado e outros campos são ignorados. A exceção é a identidade exata de AuctionatorShoppingFrame.SearchOptions.SearchString: esse campo sem nome pode manter foco durante a busca normal. Liberá-lo evita exigir que o usuário limpe o filtro.

O parser usa o marcador real, divide CR/LF e quebras internas, remove cores hexadecimais e nomeadas (incluindo |cnIQ1:) e preserva rótulos localizados. Aceita inteiros positivos representáveis, rejeitando duplicatas, marcador repetido, bloco vazio e alternativas inválidas sem aceitar parcialmente o bloco.

Um bloco inline termina na própria linha lógica; linhas externas semelhantes a alternativas não são incorporadas. Se o marcador estiver isolado, podem seguir alternativas em linhas lógicas contíguas até uma linha externa não alternativa. Truncagem silenciosa após uma alternativa válida não é comprovadamente detectável pelo parser.

Os rótulos plurais não são nomes pesquisáveis. O catálogo fornece IDs/quantidades e o cliente fornece nomes canônicos, com conferência do ID no link. A comparação de contagem e multiconjunto de quantidades detecta divergências numéricas; não detecta troca de materiais com mesmo perfil numérico. Veja [catálogo e procedência](catalog.md).

Sem tooltip/nome carregado, não há lista parcial, timer ou loop. Para materiais, RequestLoadItemDataByID é solicitado no máximo uma vez por ID na sessão. O usuário aguarda e repete o gesto. Avisos são limitados a um a cada cinco segundos.

O diagnóstico de rejeição informa motivo, linha e trecho; espaços/controles/pipes são exibidos numericamente para impedir interpretação como markup pelo chat. Na comparação de cabeçalho, também informa a primeira divergência de bytes.

## Propriedade e ciclo das listas

CrateShopDB liga Item ID do caixote a nome da lista, cópia ordenada das entradas e, nas novas gravações, versão do catálogo. O prefixo não comprova propriedade.

A lista própria existente precisa coincidir integralmente com o vínculo. Edição, reordenação, nome ambíguo ou colisão de destino bloqueiam a operação. Colisões também são verificadas ignorando caixa ASCII.

No próximo Shift+clique, uma lista própria intacta CrateShop: é preparada para CS:. Confirmar migra o nome e atualiza as entradas; Cancelar não muda nada. Listas legadas em plural são atualizáveis sob a mesma proteção.

Se o nome associado não for encontrado, é oferecida nova criação no destino CS: livre. Não exige limpar a associação por comando. Uma lista renomeada manualmente é preservada e pode coexistir com a nova CS:, pois o vínculo persistente não distingue renomeação de exclusão.

Antes do aceite são conferidos tooltip, versão do catálogo, nomes/termos, vínculo, origem/destino, ação e identidade do objeto da lista. Remoção/recriação durante o diálogo invalida o ticket; novo gesto permite preparar a recuperação. Entre sessões, uma lista recriada com nome e conteúdo exatamente iguais não pode ser distinguida da original com os dados disponíveis.

## Atomicidade e limites

Entradas são preparadas/validadas antes da primeira alteração, com trava síncrona contra reentrada e ticket consumido antes de callbacks. Não há yield nem escrita ao cancelar/fechar AH.

O Auctionator não oferece transação nativa. Eventos podem expor uma lista brevemente vazia durante criação/atualização. Erros provocam tentativa de reversão pelos métodos normais; falha persistente de callbacks também pode impedir reversão completa. Nesse caso há aviso explícito para conferir a lista, e o vínculo não é promovido. Não se promete atomicidade diante de encerramento do cliente ou interferência reentrante de terceiros.

O TOC usa ícone nativo 236994, sem imagem redistribuída. Metadados/arquivos novos podem exigir reabrir o cliente para atualizar a exibição.

## Verificações realizadas

- Testes de comportamento foram escritos e observados falhando antes das implementações pertinentes.
- Suíte final de 83 testes em Lua 5.1 via Lupa, com mixins, serializador, API e hook reais instalados do Auctionator.
- Fronteiras simuladas: C_Item, tooltip, EventBus, eventos/frames WoW, metadata e StaticPopup. Usar a criação pública ou emitir evento de importação faz o harness falhar.
- Sintaxe dos seis módulos, referências TOC, BOM/whitespace e diff verificados.
- Revisões independentes somente leitura do catálogo e do ciclo das listas, sem bugs acionáveis ao término. Conferência numérica independente: 30 caixotes e 96 alternativas coincidem com a fonte declarada.
- Nenhum teste carrega SavedVariables pessoais; .tools é somente desenvolvimento e fica fora do Git.

## Validação no cliente e cobertura restante

As evidências foram fornecidas pelo usuário, não por automação do jogo:

- Captura de diálogo de Plantas de Profissional com cinco alternativas e aviso para escolher um conjunto.
- Confirmação de funcionamento na aba Comprar do Auctionator após correção do foco.
- Captura de atualização da lista com cinco nomes canônicos, x10 em cada entrada e resultados para os cinco materiais.
- Aviso de cache frio para IDs 3369/3356 seguido de atualização bem-sucedida após novo gesto.
- Usuário confirmou funcionamento do incremento 0.2.1 (CS:/recuperação/ícone) antes de solicitar a integração; não forneceu detalhamento visual separado de cada cenário.

Permanecem sem comprovação individual no cliente: minérios com quantidades distintas, todos os caminhos de cancelamento/colisão/edição/obsolescência, persistência entre sessões, aparência isolada do ícone e ausência de busca adicional no instante do aceite com AUTO_LIST_SEARCH ligado/desligado. Esses comportamentos têm cobertura parcial ou integral no harness, mas não são apresentados como teste real no Forever.
