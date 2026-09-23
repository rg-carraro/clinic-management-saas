# Implementação até o MVP

## Escopo e sequência

Seguir os itens 1, 2 e 3 do plano anexado: Fundação, Identidade/tenancy e MVP
Essencial. Cada entrega recebe validação, commit e push próprios. No roadmap das
skills, correspondem às etapas 0, 1 e 2. Offline/sync completo, cobrança de
assinaturas, seats comerciais, Pro avançado e módulo clínico ficam para depois.

## Arquitetura proposta antes da implementação

- `app_flutter/`: Flutter, Material 3, Android/iOS e Web. Camadas presentation,
  application, domain, infrastructure e shared. Sessão em memória no MVP;
  nenhum token em armazenamento web persistente. Reentrada exige login.
- `api_backend/`: Python 3.13, FastAPI, SQLAlchemy e Alembic. PostgreSQL em
  ambientes implantados; SQLite apenas para testes rápidos e desenvolvimento.
- `shared_contracts/`: OpenAPI exportado do backend e regras do contrato.
- `infra/`: imagens, configuração por ambiente e procedimentos operacionais.
- `docs/`: decisões, ameaças, aceite e resultados das etapas.

Cloud é a fonte canônica. O MVP requer conexão; não exibirá confirmação de
gravação offline. Preparar pagamentos com chave de idempotência, sem declarar
que isso substitui a futura fila de sincronização.

## Modelo inicial

User representa a identidade da conta. Organization representa o tenant.
Membership associa User, Organization e Role (OWNER, ADMIN, PROFESSIONAL, STAFF).
Session e PasswordReset armazenam somente hashes dos tokens. Subscription mantém
trial, tier ESSENTIAL/PRO e licença FOUNDER; entitlements são derivados no servidor.
Professional e Service organizam a agenda. Patient contém apenas cadastro
administrativo. Appointment reserva horário. Attendance registra serviço e valor
histórico. Payment abate um atendimento; saldo e relatório são projeções, sem
uma segunda fonte de verdade financeira.

## Superfície de ameaça e controles

| Risco | Controle planejado |
| --- | --- |
| Acesso entre tenants | Tenant validado pela sessão e membership; todas as consultas com escopo; testes adversariais |
| Elevação de privilégio | RBAC e entitlement no servidor, negação por padrão |
| Roubo/reutilização de token | Tokens aleatórios, hash no banco, expiração, logout e revogação após troca de senha |
| Abuso de autenticação | Hash Argon2, limites por IP/identidade, erros genéricos e reset de uso único |
| Trial/FOUNDER adulterado | Campos comerciais fora dos contratos públicos; timestamps persistidos no servidor |
| Duplicação de cobrança | Transação, bloqueio concorrente, chave de idempotência e valores inteiros |
| Exposição de dados | Sem corpo de requisição nos logs, sem campos clínicos, TLS no ingresso, backups protegidos |
| Segredos/release inseguro | Exemplos sem credenciais reais, CI, configuração validada e dependências fixadas |

## Critérios de aceite por entrega

1. Fundação: monorepo, API health, aplicativo inicial, ambientes, migrations,
   lint/test/build, CI e documentação. Validar migration em banco vazio.
2. Identidade: cadastro/login/logout/reset, sessão revogável, isolamento,
   papéis, trial de 7 dias, FOUNDER e entitlements. Testar tentativas cruzadas,
   expiração, revogação, promoção indevida e acesso Pro pelo cliente manipulado.
3. MVP: pacientes, profissionais/serviços, agenda, conclusão de atendimento,
   valor histórico, pagamentos parciais/totais, saldo, dashboard, relatórios e
   WhatsApp manual editável. Testar duplicação, saldo, tenant e autorização.

## Limites de implantação

Publicar commits não significa implantar um serviço. Produção depende de banco,
domínio/TLS, SMTP, armazenamento/backups com criptografia e credenciais do operador.
iOS exige build em macOS e assinatura Apple; Android distribuível exige assinatura.
Documentar os builds realmente executados e qualquer validação indisponível.

## Apresentação e identidade provisória

O MVP recebeu tema azul/branco reutilizável em todas as áreas e recursos Android.
A decisão e o mapa de arquivos estão na [ADR 0002](adr/0002-identidade-visual-e-android.md).
O [guia Flutter](../app_flutter/README.md) orienta importação no Android Studio,
execução da API e build. O [roteiro de apresentação](apresentacao-mvp.md) organiza
feedback para as próximas fases; não amplia o escopo clínico ou offline.
