# Changelog

## 0.4.0 — 2026-11-22 (preparada; não publicada)

- Shift+clique seleciona e expande a lista própria já atualizada no Auctionator, sem diálogo, gravação ou mensagem de atualização.
- Lista já expandida apenas recebe rolagem; atualização necessária e migração preservam confirmação. Listas editadas continuam protegidas.
- Abertura usa a expansão nativa, respeitando AUTO_LIST_SEARCH; criação/atualização continuam sem pesquisa adicional.
- Painel ausente/incompatível gera aviso localizado sem alterar listas. Testes fora do jogo incluem o método ExpandList do Auctionator instalado; seleção visual ainda depende de validação no cliente.

## 0.3.0 — 2026-11-17 (preparada; não publicada)

- Interface em português para ptBR/ptPT e inglês para os demais locales, com fallback inglês por chave.
- Textos próprios centralizados em Lua, com placeholders para valores dinâmicos e preservação dos nomes fornecidos pelo jogo.
- Troca de idioma mantém as associações por Item ID, os nomes das listas próprias e a proteção contra duplicação; alterações continuam exigindo confirmação.
- Parser ampliado para tooltips portugueses e ingleses, com texto inglês extraído do cliente e publicado pelo ForeverDiff. Testes automatizados de plantas/minérios, requisitos inválidos e fluxo inglês; sem execução no cliente inglês. Formatos não reconhecidos continuam bloqueados, sem criar lista.
- Licença MIT, copyright 2026 Gallaf. Avatar original preparado separadamente para a página do CurseForge.
- Validação fora do jogo ampliada para locales, fallback, placeholders/acentos e preservação de listas. O proprietário confirmou funcionamento no Forever após a localização.
- Pacote de distribuição inclui somente arquivos do addon, LICENSE e CHANGELOG; ferramentas, testes, dados pessoais e material de divulgação ficam fora.

- Confirmações do chat encurtadas, com prefixo CS: e sem repetir o prefixo da lista ou explicações já presentes no diálogo. Avisos de erro preservados.

## 0.2.1 — 2026-11-15

- Catálogo versionado com 30 caixotes e 96 alternativas; nomes localizados obtidos pelo ID de cada material, corrigindo buscas exatas com rótulos plurais.
- Suporte a cores nomeadas do Forever, incluindo |cnIQ1:, além das cores hexadecimais.
- Shift+clique funciona com foco no campo de pesquisa do Auctionator; chat e demais campos continuam protegidos.
- Listas usam CS:; listas próprias intactas com prefixo anterior são migradas na próxima confirmação.
- Lista apagada pode ser importada novamente quando o destino está livre, preservando listas manuais e renomeadas.
- Auctionator 346 como versão mínima, com verificação das interfaces e inspeção das versões 346/347.
- Ícone nativo de caixote na lista de addons.
- Diagnósticos de requisitos inválidos, proteção de confirmação obsoleta e tentativa de reversão em falhas, inclusive de renomeação.
- Documentação de origem/atualização do catálogo, uso, migração, validação e limites; 83 testes em Lua 5.1.

Novos caixotes dependem de atualização do catálogo. Confirmar continua obrigatório antes de gravar; o addon não executa compras ou pesquisas adicionais.

## 0.1.0 — 2026-11-15

- Primeira implementação de parser de tooltip, observador seguro de Shift+clique, confirmação e adaptador de Shopping Lists.
- Proteção de propriedade, colisões e alterações obsoletas, com testes e roteiro inicial de validação.
