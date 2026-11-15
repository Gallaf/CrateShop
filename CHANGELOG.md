# Changelog

## Não publicado

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
