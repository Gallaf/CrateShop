# Tooltips ingleses: evidências e implementação

## Fonte consultada em 2026-11-17

ForeverDiff declara ler os dados do cliente Blizzard, sem fornecer uma captura desta sessão do usuário. Foram consultados os registros:

- [Waylaid Crate: Journeyman Herbs, item 248686](https://foreverdiff.com/items/waylaid-crate-journeyman-herbs-248686/): cinco alternativas, dez unidades de cada material.
- [Waylaid Crate: Expert Ore, item 248692](https://foreverdiff.com/items/waylaid-crate-expert-ore-248692/): Gold Ore x10 e Mithril Ore x20.

Os registros identificam o build 1.60.1.70532 de 2026-10-22. O marcador publicado é `Use: Fill the crate with any bundle from the following list:`. Não é uma tradução presumida do texto português. A compatibilidade com builds posteriores depende da preservação desse formato; não se afirma que o cliente inglês atual foi executado.

## Decisão

TooltipParser reconhece dois cabeçalhos explícitos: o português já capturado e o inglês publicado. A seleção não depende de GetLocale: o idioma da interface e o texto do item são fronteiras diferentes. Aceita também o marcador sem o prefixo Usar:/Use:, mantendo o comportamento existente.

As regras de quantidade, remoção de cores, limites de bloco, duplicatas e rejeição integral permanecem comuns aos dois idiomas. Marcadores repetidos, inclusive em idiomas diferentes, são recusados. Não há reconhecimento genérico por nome de caixote nem tradução de materiais.

As fixtures inglesas transcrevem os textos publicados, mas reconstroem as quebras internas e a distribuição em linhas a partir do formato observado em português. Portanto, são fixtures de dados publicados, não capturas reais de C_TooltipInfo no cliente inglês. A página apresenta o texto achatado; isso não comprova o layout das linhas retornadas pela API.

O catálogo existente continua responsável por IDs/quantidades; C_Item.GetItemInfo fornece nomes canônicos no idioma do jogo. Não foram alterados catálogo, persistência, propriedade das listas ou métodos de integração. Listas próprias existentes continuam protegidas pelo vínculo atual.

## Verificação e limites

Foram adicionados testes de parser para plantas, minérios com quantidades distintas, quantidade variável de alternativas, cores, cabeçalho sem prefixo, bloco vazio, requisito parcial, zero, duplicação e marcador ambíguo. Os casos novos falharam antes da implementação.

O harness de fluxo em enUS/enGB verifica confirmação, cancelamento, criação e atualização de minérios usando nomes canônicos ingleses simulados e os métodos/serializador reais do Auctionator instalado. Uma lista manual é preservada. O harness proíbe a criação pública que pode pesquisar e o evento de importação que dispara pesquisa.

Esses testes não executam WoW nem comprovam a renderização inglesa real ou a resolução real de cache. Não se exige alterar o idioma do usuário. Uma futura captura inglesa pode complementar a evidência, sem ser condição para os testes automatizados ou para distribuir este suporte documentado.
