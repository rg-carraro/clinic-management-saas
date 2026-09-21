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
