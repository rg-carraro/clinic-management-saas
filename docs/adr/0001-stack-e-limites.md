# ADR 0001 — Stack e fronteiras do MVP

Status: aceita para implementação.

Flutter atende às plataformas previstas. FastAPI fornece validação e OpenAPI;
SQLAlchemy/Alembic permitem PostgreSQL e migrations versionadas. Python 3.13 é
isolado do Python 3.9 já existente na máquina. Dependências serão fixadas por lock.

Escolhemos sessões opacas revogáveis em vez de JWT para simplificar revogação e
mudanças de acesso. O tenant vem de header explícito validado contra membership.
Nenhum endpoint aceita tenant do corpo para decidir o escopo.

Dinheiro usa centavos inteiros BRL. Atendimento guarda valor e nome do serviço
históricos. Pagamentos não são removidos ou editados no MVP; estorno fica fora
do escopo e requer futura trilha contábil explícita. Registros financeiros não
são apagados por exclusão de pacientes; estes são arquivados.

Entitlements comerciais e feature flags são independentes: flags podem desativar
uma função, nunca conceder acesso sem assinatura/permissão. Trial libera ESSENTIAL.
FOUNDER não expira automaticamente. Concessão comercial é operação administrativa
do servidor, não campo editável pelo usuário.

SQLite é um facilitador local. PostgreSQL é obrigatório em staging/prod e na
integração CI. Testes concorrentes financeiros usam PostgreSQL.
