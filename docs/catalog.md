# Catálogo de caixotes

## Escopo e procedência

CrateShop 0.2.1 inclui catálogo 2026-11-15.1 para o build de dados Forever 1.60.1.70938.
Contém 30 caixotes preenchíveis, com 96 alternativas: IDs 248682–248699 e 248702–248713.

Fonte dos fatos numéricos (ID de caixote, ID de material, quantidade): seção ns.crates de WhatsItFor_Data_Forever/Data.lua, versão v1.1.40, autor declarado Kalinauskas. O cabeçalho declara geração para Forever 1.60.1.70938. O TOC da fonte declara GPL-3.0-or-later. Foram transcritas somente as relações numéricas de jogo; não foram incluídos código executável, estruturas de interface, funções, textos ou o restante da base desse addon.

SHA-256 do arquivo de origem inspecionado:
84beed3332867942712c0a6ec4e39c9dc93e37ccc98f429ee611840e968d5077

O arquivo instalado foi lido somente como fonte desta revisão de dados. O CrateShop não carrega, importa ou exige WhatsItFor no jogo. Não há atualização pela rede.

## Resolução e limites

O catálogo é a fonte de IDs e quantidades; C_Item.GetItemInfo fornece o nome localizado canônico de cada ID, com conferência do ID no hyperlink devolvido. Não há regras para remover S ou converter plural em singular.

O tooltip continua sendo lido e interpretado integralmente para reconhecer a estrutura. Sua contagem de alternativas e o multiconjunto das quantidades devem coincidir com o catálogo. A ordem não é usada para relacionar rótulos plurais a IDs.

Essa validação detecta divergências numéricas, mas **não detecta troca de materiais com mesmas quantidades e contagem**. A correção depende da atualização e revisão da versão do catálogo; não se afirma equivalência semântica automática entre rótulo plural e ID.

Caixote ausente do catálogo é recusado com mensagem explícita. Caixote não identificado/sem bloco suportado continua sendo ignorado como item comum. Se algum nome não estiver carregado, a operação não cria lista parcial. RequestLoadItemDataByID é solicitado uma única vez por material durante a sessão, quando disponível; não há timers, loops, buscas nem fallback para texto plural. Aguarde e repita Shift+clique.

## Listas da versão anterior

O vínculo de propriedade existente é preservado. Uma lista própria em plural, ainda idêntica à cópia salva no CrateShopDB, oferece Atualizar lista e recebe os nomes canônicos somente após confirmação. Não é necessário apagar a lista nem a associação.

Se o usuário editou ou reordenou a lista, continua valendo o bloqueio conservador descrito no README. Na versão 0.2.1, o próximo gesto migra a lista própria intacta de CrateShop: para CS: após confirmação. Se o nome associado sumiu, oferece nova criação quando CS: estiver livre; uma lista renomeada manualmente permanece intacta. A versão do catálogo passa a acompanhar o vínculo após gravação, como campo opcional; o formato anterior continua legível.

## Atualização dos dados

1. Obter uma fonte identificada e compatível com o build desejado.
2. Revisar os IDs/quantidades e o suporte do cliente; não inferir conteúdo pelo nome.
3. Alterar as relações em CrateCatalog.lua e incrementar Catalog.version e build de procedência.
4. Adicionar ou ajustar fixtures de comportamento, incluindo novo caixote e nomes localizados.
5. Executar toda a suíte e check_package.py; revisar o diff numérico.
6. Validar no cliente a atualização de lista própria e buscas individuais. Atualização do addon não altera listas automaticamente.

## Validação no jogo

Validado por captura do usuário com Auctionator 347: recuperação após aviso de nomes não carregados, atualização da lista de plantas, cinco nomes canônicos com dez unidades cada e resultados para os cinco materiais. Os nomes exibidos são Estrangulalga, Ervamossa, Ácera-agreste, Musgo de Tumba e Sangue-real.

Ainda observar, antes de expandir ou clicar em material, que a confirmação não dispara busca adicional.

Também validar minérios com dez Ouro/vinte Mithril, cache frio com repetição manual limitada e bloqueio de um caixote não cadastrado. Os testes fora do jogo simulam C_Item e não substituem essa conferência.

Revisão independente concluída sem bugs acionáveis, com conferência numérica de todos os 30 caixotes e 96 alternativas contra a fonte declarada. Suíte atual: 83 testes Lua 5.1 e check_package.py passando. O usuário confirmou funcionamento após o incremento 0.2.1, sem detalhamento individual de todos os cenários.
