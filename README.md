# CrateShop

Addon inicial para WoW Forever em português brasileiro. Lê dinamicamente os requisitos de um caixote e, após confirmação, cria uma Shopping List no Auctionator. Cada entrada é uma **alternativa**: basta preencher um conjunto, não comprar tudo.

## Instalação

Compatibilidade inspecionada: cliente **1.60.1.70938**, interface **16001**, Auctionator **346**.

1. Feche o cliente ou volte à seleção de personagens.
2. Copie somente a pasta interna [CrateShop](CrateShop) para C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\CrateShop.
3. Confira que CrateShop.toc fica diretamente nessa pasta, sem pasta duplicada.
4. Ative Auctionator e CrateShop na seleção de addons.

Não há instalação automática. Nenhum arquivo do jogo ou de outro addon foi alterado.

## Uso

Abra a Casa de Leilões e faça Shift+clique no hyperlink de um caixote. Mantenha o chat sem foco. Confira nome e número de alternativas e escolha **Criar lista** ou **Cancelar**. Uma lista já associada oferece **Atualizar lista**.

As entradas usam nome exato e a quantidade lida do tooltip. O CrateShop não inicia pesquisa nem compra. O Auctionator continua realizando sua busca habitual do Shift+clique; pesquisar/expandir manualmente a lista depois segue as preferências normais dele.

O parser usa a frase “Encha o caixote com qualquer conjunto da lista a seguir:” e alternativas “- quantidade nome”. Novos caixotes funcionam sem atualização **enquanto mantiverem esse formato suportado**. Não existe catálogo de materiais/IDs.

Se o item ainda não estiver carregado, aguarde e repita o gesto. Não há repetição automática. Avisos são limitados a um a cada cinco segundos. Itens comuns com tooltip disponível são ignorados silenciosamente.

## Proteção das listas

CrateShopDB mantém apenas versão do formato e, por Item ID, nome da lista e cópia dos termos criados. O prefixo do nome não prova propriedade. Colisão com lista alheia cancela a operação, inclusive com diferenças de caixa ASCII. Renomeie a lista conflitante manualmente se desejar liberar o nome.

Listas associadas que foram editadas, reordenadas, renomeadas ou removidas são bloqueadas conservadoramente. Não são procuradas por semelhança nem sobrescritas. Para abandonar deliberadamente uma associação, use no jogo, trocando ITEM_ID pelo número do caixote:

~~~lua
/run CrateShopDB.lists[ITEM_ID] = nil
~~~

Isso remove apenas a associação própria. Preserve/renomeie a lista existente antes de tentar criar outra. Não apague SavedVariables do Auctionator.

A confirmação é revalidada contra o tooltip e contra as listas atuais. Cancelamento, Escape e fechamento da Casa de Leilões não gravam. Falhas de gravação tentam reverter pelos métodos do gerenciador; não existe transação nativa do Auctionator. Veja os limites em [compatibilidade](docs/compatibility.md).

## Testes fora do jogo

Na raiz do repositório, com Lua 5.1:

~~~powershell
lua .\tests\run.lua
~~~

O harness lê o código instalado do Auctionator, sem carregar SavedVariables pessoais. Para outra instalação, configure AUCTIONATOR_PATH apontando para a pasta Auctionator. Requer a versão 346.

Alternativa usada nesta entrega, com Python e Lupa locais apenas para desenvolvimento:

~~~powershell
python -m pip install --target .tools lupa
python .\tests\run.py
python .\tests\check_package.py
~~~

.tools é ignorada pelo Git e não deve ser copiada para AddOns. O addon depende somente do Auctionator e das APIs do cliente.

## Roteiro pendente dentro do Forever

1. Ativar erros Lua e verificar carregamento sem erros com Auctionator 346.
2. Abrir a Casa de Leilões, deixar chat sem foco e fazer Shift+clique nos caixotes de plantas e minérios.
3. Conferir nome, cinco/duas alternativas e os botões; cancelar e verificar ausência de lista nova.
4. Repetir, confirmar e conferir nomes exatos e quantidades (minérios: 10 Ouro, 20 Mithril).
5. Observar a busca normal do Auctionator e confirmar que **confirmar a lista não dispara outra busca**, inclusive com AUTO_LIST_SEARCH ligado e desligado.
6. Repetir para atualizar; verificar que nenhuma outra lista muda e cliques repetidos não duplicam.
7. Testar colisão com lista manual, edição, renomeação e remoção da própria; verificar recusa conservadora.
8. Abrir confirmação e fechar AH, usar Escape, mudar tooltip/lista e tentar confirmar; não deve gravar dados obsoletos.
9. Shift+clique em item comum e com chat focado: sem confirmação/spam; conferir que links no chat continuam normais.
10. Recarregar UI e conferir persistência das associações. Validar caixote novo com mesmo formato.

Hooks, diálogos e criação de listas **não foram executados dentro do jogo** nesta entrega. O harness simula as fronteiras do cliente; não certifica comportamento de frames, taint ou SavedVariables gravadas pelo cliente.