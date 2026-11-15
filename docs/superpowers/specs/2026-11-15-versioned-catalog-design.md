# Catálogo versionado de caixotes

O usuário aprovou catálogo após confirmar que os nomes dos requisitos são plurais e diferem dos nomes pesquisáveis. Essa autorização substitui somente a exigência original de não usar catálogo fixo. A implementação segue diretamente, conforme dispensa inicial de nova rodada de brainstorming.

Alternativas consideradas: catálogo versionado (escolhido), associação manual de links (não escolhida), resolução por APIs de condições (só expõem predicado para inventário, sem enumeração confirmada).

## Decisões

- Um módulo Lua contém apenas fatos de jogo: Item IDs dos caixotes, materiais e quantidades. Procedência: tabela ns.crates de WhatsItFor_Data_Forever v1.1.40, declarada para o build 1.60.1.70938. Sem copiar código executável nem exigir esse addon em runtime.
- IDs e quantidades do catálogo são autoritativos. Não relacionar nomes por posição nem singularizar strings. Resolver nomes pelo C_Item.GetItemInfo(id), validando o ID do link devolvido.
- Parser continua estrutural. Antes de escrever, comparar contagem e multiconjunto das quantidades do tooltip com o catálogo; divergência explícita bloqueia. Essa validação não detecta mudança silenciosa de materiais com mesmas contagens/quantidades.
- Caixote desconhecido ou material ainda não carregado bloqueia sem fallback. Solicitar dados de cada material ausente no máximo uma vez por sessão, sem timer/loop ou busca na AH.
- Revalidar catálogo, nomes e termos no aceite. Manter tooltip bruto no ticket para detectar mudança. Listas próprias legadas em plural podem ser atualizadas após confirmação se ainda coincidirem com o vínculo salvo.
- Preservar todas as correções locais (cores nomeadas, foco e diagnóstico). Não escrever SavedVariables fora do cliente. Não fazer push/merge sem nova instrução.
- O catálogo limita suporte a novos caixotes: exige atualização versionada. Não identifica mudanças de conteúdo com mesma estrutura numérica.
