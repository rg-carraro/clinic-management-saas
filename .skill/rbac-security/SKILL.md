# Skill: RBAC & Security by Design

Papéis iniciais:
OWNER, ADMIN, PROFESSIONAL, STAFF.

## Princípios
- least privilege
- deny by default
- autorização sempre no servidor
- isolamento rigoroso de tenant
- autenticação forte e sessões revogáveis
- rate limiting
- validação de entrada
- proteção contra abuso
- segredos fora do código/repositório
- logs sem conteúdo clínico/sensível desnecessário
- trilha de auditoria para ações críticas
- backups e testes de restauração
- dependências monitoradas e atualizadas
- HTTPS/TLS
- criptografia apropriada para dados armazenados e backups
- tokens protegidos no dispositivo

Ocultar tela/botão NÃO é controle de segurança.
Cada endpoint deve verificar identidade, tenant, papel/permissão e entitlement.
