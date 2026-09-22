# Registro de entregas

## 1 — Fundação

Estrutura Flutter/API/contratos/docs/infra, configuração dev/staging/prod,
ADR, análise inicial de ameaças, CI, migration 0001 e API `/health`.

Validação local: testes da API, Ruff, migration em SQLite vazio, Alembic check,
wheel/sdist Python, análise/teste Flutter e build Web. Resultados finais desta
entrega são registrados no commit. PostgreSQL é validado também no CI.

Sem implantação remota, sem secrets reais e sem dados de pacientes nos logs.
Android/iOS têm projetos gerados; assinatura/distribuição não fazem parte desta
fundação. iOS só pode ser compilado em macOS.

## 2 — Identidade e tenancy

Migration 0002: contas, organizações, vínculos/papéis, sessões, resets, assinatura,
auditoria e limites de autenticação persistidos. Telas Flutter de cadastro, login
recuperação e logout. Sessões só em memória no cliente; token com hash no banco.
Trial de 7 dias persistido, FOUNDER permanente e entitlements no servidor.
Equipe exige Pro; OWNER não pode ser criado ou removido pela API de equipe.

Recuperação exige SMTP configurado. Sem SMTP em dev a resposta continua genérica,
sem expor código; testes capturam a mensagem em adapter isolado. Produção rejeita
configuração sem SMTP. Nenhum campo público permite promover licença ou plano.

Validação: 9 testes de API (incluindo isolamento, trial/FOUNDER, revogação, reset
único, rate limit e Pro/RBAC), migrations e análise/build de ambas as partes.
A Fundação também passou no CI remoto com PostgreSQL.

## 3 — MVP Essencial e retomada em 21/09/2026

O ponto de retomada foi o commit `c669ec0` (`mvp flutter app`), já presente no
GitHub, com checkout limpo. A implementação estava versionada, mas faltavam o
registro desta entrega e o fechamento do CI. A execução
[35611241869](https://github.com/rg-carraro/clinic-management-saas/actions/runs/35611241869)
passou no backend com PostgreSQL e falhou na formatação Flutter.

### Funcionalidades e arquivos

- API: domínio e aplicação `operations.py`, rotas `operations_routes.py`,
  integração em `api.py` e contrato `shared_contracts/openapi.json`.
- Flutter: repositório administrativo, conversão monetária em centavos,
  formulários e telas de pacientes, catálogo, agenda, atendimento, financeiro,
  dashboard, relatório e WhatsApp manual.
- Migration `0003_administrative_financial_mvp`: pacientes, profissionais,
  serviços, agendamentos, atendimentos e pagamentos, com vínculos por tenant.
- Testes: `test_operations.py`, `test_security_edges.py`, `test_migrations.py`
  e `mvp_test.dart`. Fluxo de homologação em [API e fluxos](api-e-fluxos.md).

No fechamento foram formatados `main.dart`, `home_screen.dart` e `mvp_test.dart`,
e removido um import redundante apontado pelo analisador. O plano original e o
README agora apontam para o estado atual; o [catálogo](catalogo-funcionalidades.md)
registra funcionalidades, tiers, plataformas, entitlements e status.
Nenhuma migration adicional ou mudança de regra de negócio nesta retomada.

### Validação e segurança

- Ruff check e format: aprovados (30 arquivos Python).
- API: 20 testes aprovados, 2 ignorados localmente por exigirem PostgreSQL.
  O CI do commit do MVP passou também com PostgreSQL, incluindo concorrência.
- Migration: upgrade/downgrade/upgrade e comparação com modelos em SQLite
  descartável aprovados; upgrade e Alembic check PostgreSQL passaram no CI.
- Build Python: wheel e sdist gerados com `uv build`.
- `pip-audit`: nenhuma vulnerabilidade conhecida encontrada nas dependências;
  o pacote local `clinic-api` não é auditável no PyPI.
- Flutter: quatro testes aprovados, incluindo pagamento parcial e atualização
  do saldo visível. Formatação aprovada (11 arquivos), análise sem problemas e
  build Web concluído após as correções, incluindo o dry run Wasm do SDK.
- OpenAPI reexportado sem divergência em relação ao arquivo versionado.
- Isolamento de tenant, chaves estrangeiras cruzadas, STAFF sem conclusão de
  atendimento, restrição de agenda do PROFESSIONAL, Pro/feature flags no servidor,
  trial/FOUNDER, reset e revogação estão cobertos pela suíte.
- Financeiro cobre valor histórico, pagamento parcial/total, idempotência,
  rejeição de excesso, relatório e saldo real no WhatsApp. Auditoria e respostas
  de validação não expõem os dados sensíveis usados nos testes.
- Revisados os arquivos versionados: sem `.env`, bancos locais ou chaves privadas
  de assinatura. API e preview local desabilitam logs de acesso sensíveis.

### Limites e continuidade

MVP online e administrativo/financeiro. Offline/sync, cobrança de assinaturas,
seats comerciais, Pro avançado e módulo clínico continuam fora desta entrega.
Gestão de equipe está disponível na API; não há tela de gestão de vínculos.
CSV está disponível na API. Não há estornos nem emissão fiscal.

Há APK debug anterior no diretório ignorado de build; ele não foi recompilado
nesta retomada. Build iOS não foi executado (exige macOS/Xcode). Publicação no
GitHub não implanta produção nem publica nas lojas. TLS, SMTP real, backups com
restauração homologada, banco e assinaturas exigem provisionamento operacional.
Os testes Python emitem avisos de depreciação de Starlette/httpx e AnyIO, sem falhas.

Próximo trabalho: homologar o fluxo manual documentado e planejar Cloud/offline/sync
em entrega separada, preservando a idempotência financeira existente.
