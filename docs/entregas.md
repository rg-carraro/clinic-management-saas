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
