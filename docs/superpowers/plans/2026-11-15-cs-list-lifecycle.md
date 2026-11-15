# CS list lifecycle

Escopo aprovado: prefixo CS:, migração no próximo Shift+clique e reimportação quando o nome associado não for encontrado. A confirmação original continua obrigatória antes da escrita; o usuário não pediu removê-la.

- [x] RED: migração própria intacta, colisão, cancelamento, falha após Rename/Append, recriação de lista removida e proteção de dados obsoletos.
- [x] Implementar nome desejado separado do nome de origem. Rename/Sort pelos métodos nativos; rollback tenta restaurar nome e conteúdo. Ausência de origem permite criar somente se destino estiver livre.
- [x] GREEN: suíte completa e pacote, documentação e revisão independente.
- [x] Instalar somente arquivos do CrateShop e orientar /reload.

Decisão: uma lista renomeada pode ser indistinguível de uma lista apagada pela associação persistente. Preservar a renomeada e oferecer criação no destino livre; nunca adotá-la por prefixo ou conteúdo semelhante. Migração e recuperação só promovem novo vínculo após gravação bem-sucedida.

Resultado: 83 testes Lua 5.1 passando; check_package.py e git diff --check válidos. Revisão independente concluída sem bugs acionáveis, incluindo Rename/Sort reais do Auctionator 347. Fonte e destino dos dois arquivos instalados conferidos por SHA-256. Ícone configurado no TOC com textura nativa 236994; confirmação visual no cliente pendente. Sem commit/push/merge nesta etapa.

## Integração autorizada

Após validar o funcionamento, o usuário solicitou consolidar a documentação, criar commit, enviar a branch, abrir PR e fazer merge em main. Essa instrução substitui a restrição de integração das etapas locais anteriores. Evidências finais e limites estão em docs/compatibility.md.
