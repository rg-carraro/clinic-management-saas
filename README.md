# Clinic Management SaaS

MVP administrativo e financeiro para clínicas, com Flutter e FastAPI.
Visão do produto: [00_README.md](00_README.md).
Plano e limites: [docs/implementacao.md](docs/implementacao.md).

## Desenvolvimento

Requisitos: Python 3.13, uv, Flutter stable, PostgreSQL 17 (ou SQLite local).

```powershell
cd api_backend
uv sync --group dev
# Copie infra/environments/dev.env.example para api_backend/.env se necessário.
uv run alembic upgrade head
uv run uvicorn clinic.presentation.api:app --no-access-log
```

```powershell
cd app_flutter
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```

No emulador Android, use `http://10.0.2.2:8000`. Em aparelho físico use uma API
HTTPS alcançável. Builds staging/prod devem definir API_BASE_URL com HTTPS.

## Verificação

```powershell
cd api_backend
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv build
cd ../app_flutter
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

## Operação

Copie o exemplo do ambiente para `api_backend/.env` e configure banco/SMTP.
Com Docker: `docker compose -f infra/compose.yaml up -d db`, execute migrations
com `docker compose -f infra/compose.yaml run --rm api alembic upgrade head`,
então suba a API. Ingresso HTTPS obrigatório fora de dev; não exponha PostgreSQL.
Backups devem usar `pg_dump`, armazenamento criptografado e acesso restrito.
Antes de release, restaure em banco isolado e execute testes/smoke sem dados reais.
Rollback: imagem anterior somente se compatível com o schema; caso contrário,
restauração do backup validado. Nunca aplicar downgrade destrutivo em produção.
Não habilite logs de corpo, Authorization, senha ou dados de pacientes.

## Identidade e planos

Cadastre a clínica pelo app; o servidor inicia um trial ESSENTIAL de 7 dias.
Recuperação de senha depende de SMTP com STARTTLS configurado. Em desenvolvimento,
configure um servidor SMTP de teste; nunca devolvemos ou registramos o token.
A sessão expira em 12 horas e logout/troca de senha revogam acesso no servidor.

FOUNDER e concessões comerciais são operadas fora da API pública, com acesso
restrito ao banco e trilha de auditoria:

```powershell
uv run python -m clinic.operator ORGANIZATION_ID --license FOUNDER --tier ESSENTIAL
```

Pro permite equipe; para adicionar alguém, a pessoa precisa ter uma conta e o
OWNER/ADMIN usa `/v1/members`. Trial não é renovado por reinstalação/login.
Não há gateway de pagamento de assinatura nesta etapa.

## MVP disponível

Pacientes (edição/arquivamento), serviços, profissionais, agenda com conflito de
horários, atendimento com valor histórico, pagamentos parciais/totais, saldo,
dashboard, relatório por período e WhatsApp manual com mensagem editável.

Comece por **Configurações → Profissional e Serviço**, depois **Pacientes → Agenda
→ Concluir atendimento → Financeiro**. O trial inicia no cadastro.
[Fluxos de aceite e API](docs/api-e-fluxos.md) · [Operação](docs/operacao.md).

No checkout preparado nesta máquina, os executáveis locais estão em
`.tools/uv/bin/uv.exe` e `.tools/flutter/bin/flutter.bat`. Esses SDKs e os artefatos
de build são ignorados pelo Git; em outra máquina, instale os requisitos acima.
