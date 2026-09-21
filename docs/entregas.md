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
