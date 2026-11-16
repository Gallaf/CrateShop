# CrateShop

Addon para WoW Forever com interface em português ou inglês. Reconhece os requisitos no tooltip e usa um catálogo versionado de IDs para criar, após confirmação, uma Shopping List no Auctionator com os nomes corretos dos materiais. Cada entrada é uma **alternativa**: basta preencher um conjunto, não comprar tudo.

## Idioma da interface e limite do parser

`GetLocale()` seleciona português para `ptBR` e `ptPT` (mesmas traduções por enquanto). Qualquer outro locale, incluindo `enUS`, `enGB` e `deDE`, usa inglês. Inglês também é o fallback por chave quando falta uma tradução portuguesa. Os textos ficam em `CrateShop/Localization.lua`, sem bibliotecas externas, com placeholders para valores dinâmicos. O TOC deve carregar esse arquivo primeiro; após atualizar, feche e reabra o cliente.

A tradução cobre diálogos, botões, confirmações, avisos, erros e diagnósticos próprios. Não há comandos slash ou ajuda interna implementados atualmente. CrateShop, APIs e comandos existentes são preservados. Nomes de caixotes e materiais continuam exatamente como fornecidos pelo jogo; a tradução da interface não fornece termos de pesquisa nem traduz materiais.

**Interface em inglês não significa suporte a tooltip inglês.** As capturas e o parser atuais validam somente o marcador português “Encha o caixote com qualquer conjunto da lista a seguir:” e suas alternativas. Não há captura real inglesa no repositório; nenhuma frase inglesa foi presumida. Um caixote conhecido no catálogo com formato não reconhecido gera erro no idioma selecionado e não cria lista. Itens comuns continuam silenciosos. Caixotes desconhecidos com formato não reconhecido não podem ser identificados com segurança e também são ignorados.

Trocar o idioma não escreve, traduz nem recria listas existentes. O vínculo continua sendo pelo Item ID do caixote, com as mesmas verificações de propriedade e deduplicação. Ao confirmar uma atualização, uma lista própria existente mantém o nome salvo, mesmo se o jogo fornecer um nome diferente após mudar o locale; a migração já existente de `CrateShop:` para `CS:` permanece. Nomes canônicos dos materiais só são atualizados mediante confirmação, pelas APIs do jogo.

## Instalação

Compatibilidade inspecionada: cliente **1.60.1.70938**, interface **16001**, Auctionator **346 ou superior** (interfaces inspecionadas nas versões 346 e 347).

1. Feche o cliente ou volte à seleção de personagens.
2. Copie somente a pasta interna [CrateShop](CrateShop) para C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\CrateShop.
3. Confira que CrateShop.toc fica diretamente nessa pasta, sem pasta duplicada.
4. Ative Auctionator e CrateShop na seleção de addons. O CrateShop usa o ícone nativo de caixote (236994), sem assets adicionais.

## Uso

Abra a Casa de Leilões e faça Shift+clique no hyperlink de um caixote. Mantenha o chat sem foco. Confira nome e número de alternativas e escolha **Criar lista** ou **Cancelar**. Uma lista já associada oferece **Atualizar lista**. Após concluir, o chat exibe uma confirmação curta, como “CS: Lista atualizada: Plantas de Profissional.” Avisos de erro continuam visíveis.

As entradas usam os IDs/quantidades do catálogo e nomes exatos localizados obtidos do cliente. O CrateShop não inicia pesquisa nem compra. O Auctionator continua realizando sua busca habitual do Shift+clique; pesquisar/expandir manualmente a lista depois segue as preferências normais dele.

O parser usa a frase “Encha o caixote com qualquer conjunto da lista a seguir:” e alternativas “- quantidade nome”. **Novos caixotes exigem inclusão no catálogo**, além de manterem esse formato suportado. A versão atual cobre 30 caixotes; consulte [origem, limites e atualização dos dados](docs/catalog.md).

Se o caixote ou o nome de algum material ainda não estiver carregado, aguarde e repita o gesto. A operação é bloqueada integralmente até obter todos os nomes; para materiais, a solicitação de carga é limitada a uma por ID na sessão. Não há repetição automática. Avisos são limitados a um a cada cinco segundos. Itens comuns com tooltip disponível são ignorados silenciosamente.

## Proteção das listas

CrateShopDB mantém versão do formato e, por Item ID, nome da lista, cópia dos termos criados e, nas novas gravações, versão do catálogo. O prefixo do nome não prova propriedade. Colisão com lista alheia cancela a operação, inclusive com diferenças de caixa ASCII. Renomeie a lista conflitante manualmente se desejar liberar o nome.

Listas associadas editadas ou reordenadas continuam bloqueadas para preservar alterações manuais.

No próximo Shift+clique, uma lista própria intacta com prefixo antigo CrateShop: oferece **Atualizar lista** para migrar para **CS:** e atualizar os materiais na mesma confirmação. Não é criada uma segunda lista durante a migração. Colisões com outro nome CS: são recusadas.

Se o nome salvo não for encontrado, o próximo Shift+clique oferece **Criar lista** novamente, desde que o nome CS: esteja livre. Não é necessário apagar a associação por comando. Se você renomeou a lista manualmente, ela permanece intacta e a nova importação pode criar outra lista CS:; a ausência do nome anterior não distingue exclusão de renomeação.

A confirmação é revalidada contra o tooltip e contra as listas atuais. Cancelamento, Escape e fechamento da Casa de Leilões não gravam. Falhas de gravação tentam reverter pelos métodos do gerenciador; não existe transação nativa do Auctionator. Veja os limites em [compatibilidade](docs/compatibility.md).

## Atualizar listas criadas em plural

Após instalar a versão 0.2.1, feche e reabra o cliente para garantir o carregamento do novo arquivo listado no TOC e faça Shift+clique no mesmo caixote. Escolha **Atualizar lista** para substituir os termos plurais pelos nomes canônicos e migrar o prefixo para CS:. A lista existente deve continuar idêntica à cópia que o CrateShop salvou. Se foi apagada, será oferecida nova criação em vez de atualização; não é necessário limpar o vínculo. Listas manuais permanecem protegidas.

## Testes fora do jogo

Na raiz do repositório, com Lua 5.1:

~~~powershell
lua .\tests\run.lua
~~~

A suíte verifica os locales `ptBR`, `ptPT`, `enUS`, `enGB` e `deDE`, inglês sem `GetLocale`, fallback de chave ausente, placeholders/acentos, aviso de formato não reconhecido e preservação/deduplicação de listas após troca de locale. Os tooltips portugueses usados nesses testes são as capturas já disponíveis; os testes não simulam uma suposta frase inglesa.

O harness lê o código instalado do Auctionator, sem carregar SavedVariables pessoais. Para outra instalação, configure AUCTIONATOR_PATH apontando para a pasta Auctionator. Requer Auctionator 346 ou superior; o harness lê a versão e as fontes da instalação indicada.

Alternativa usada nesta entrega, com Python e Lupa locais apenas para desenvolvimento:

~~~powershell
python -m pip install --target .tools lupa
python .\tests\run.py
python .\tests\check_package.py
~~~

.tools é ignorada pelo Git e não deve ser copiada para AddOns. O addon depende somente do Auctionator e das APIs do cliente.

## Roteiro de validação dentro do Forever

A localização foi verificada fora do jogo. Ainda é necessário validar no Forever a aparência e os acentos dos diálogos/avisos nos dois idiomas, a seleção de locale real, a preservação das listas entre sessões e obter uma captura real inglesa antes de ampliar o parser.

1. Ativar erros Lua e verificar carregamento sem erros com Auctionator 346 ou superior.
2. Abrir a Casa de Leilões, deixar chat sem foco e fazer Shift+clique nos caixotes de plantas e minérios.
3. Conferir nome, cinco/duas alternativas e os botões; cancelar e verificar ausência de lista nova.
4. Repetir, confirmar e conferir nomes exatos e quantidades (minérios: 10 Ouro, 20 Mithril).
5. Observar a busca normal do Auctionator e confirmar que **confirmar a lista não dispara outra busca**, inclusive com AUTO_LIST_SEARCH ligado e desligado.
6. Repetir para atualizar; verificar que nenhuma outra lista muda e cliques repetidos não duplicam.
7. Testar colisão com lista manual e edição da própria (recusa); apagar a própria e reimportar (nova criação); renomear manualmente e conferir preservação da renomeada.
8. Abrir confirmação e fechar AH, usar Escape, mudar tooltip/lista e tentar confirmar; não deve gravar dados obsoletos.
9. Shift+clique em item comum e com chat focado: sem confirmação/spam; conferir que links no chat continuam normais.
10. Recarregar UI e conferir persistência das associações. Validar bloqueio de caixote fora do catálogo e o carregamento dos nomes dos materiais.

O usuário confirmou no Forever a atualização da lista de plantas, os cinco materiais canônicos com dez unidades e resultados de busca, além da recuperação de cache frio e da correção de foco na aba do Auctionator. Também confirmou funcionamento após o incremento 0.2.1. Isso não substitui a conferência individual de todos os cenários acima: o harness não certifica persistência entre sessões, taint nem ausência de pesquisas adicionais no cliente. Consulte [evidências e limites](docs/compatibility.md).

As mudanças da versão estão no [changelog](CHANGELOG.md).
