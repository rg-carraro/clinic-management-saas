> Estado em 21/09/2026: Fundação, Identidade/tenancy e código do MVP Essencial
> implementados. O fechamento e as evidências de validação estão em
> [Registro de entregas](entregas.md). Este documento preserva o plano original;
> o escopo executado e os limites estão em [Implementação](implementacao.md).

# Plano para o Codex — Fundação e Etapa 1
Objetivo
Construir a base técnica do SaaS para clínicas, seguindo as skills do projeto, sem avançar para módulo clínico e mantendo a segurança e o multi-tenancy como prioridade.

## 1) Fase inicial: Fundação
Meta
Preparar a estrutura do projeto para desenvolvimento sustentável e seguro.

Tarefas
Criar monorepo com:
app_flutter
api_backend
shared_contracts
docs
infra
Configurar ambientes:
dev
staging
prod
Definir arquitetura em camadas:
presentation
application
domain
infrastructure
shared
Configurar:
lint
formatter
test runner
CI básico
Definir variáveis de ambiente e segredos
Criar ADRs iniciais para decisões arquiteturais
Definir política de feature flags e entitlements
Entregáveis
Estrutura do repositório pronta
README técnico
Configuração base de build/test
Base de ambiente e segurança
## 2) Etapa 1: Identidade e tenancy
Meta
Permitir cadastro, login, organização e segregação por tenant.

Requisitos
Cadastro/login/logout
Recuperação de senha
Organização/tenant
Usuários com RBAC:
OWNER
ADMIN
PROFESSIONAL
STAFF
Isolamento de dados por tenant no backend
Trial de 7 dias
Entitlement básico
FOUNDER
Segurança por design
Entidades principais
Account
Organization
User
Role
Membership
TenantContext
Session
AuthToken
Plan
Subscription
Entitlement
Regras críticas
Todas as requisições precisam validar:
identidade do usuário
tenant
papel
permissão
entitlement
Nenhuma feature deve depender apenas de esconder botão no frontend
Usuário de Tenant A nunca acessa Tenant B
Entregáveis
Auth API
Tenant isolation
RBAC base
Trial logic
Entitlements base
## 3) Etapa 2: MVP Essencial
Meta
Construir o núcleo operacional do consultório.

Módulos
Pacientes/clientes
Agenda
Atendimentos
Valores individuais por atendimento
Pagamentos parciais e totais
Saldo consolidado
WhatsApp manual
Dashboard
Relatórios básicos
Entidades principais
Patient
Appointment
Attendance
Payment
Balance
Invoice/Charge
Service/Procedure
Professional
Schedule
Regras de negócio
Cada atendimento guarda seu valor histórico
Pagamento parcial é permitido
Saldo deve ser calculado corretamente
WhatsApp não deve conter dados clínicos
## 4) Infra/segurança
O que o Codex deve manter sempre
sem secrets hardcoded
validar tenant em cada request
manter logs sem dados sensíveis
nunca implementar regras de acesso no frontend sozinho
usar migrations versionadas
testar cenários de segurança
Testes obrigatórios
Tenant A não acessa Tenant B
STAFF não executa ação de PROFESSIONAL sem permissão
feature Pro não funciona só no cliente
trial não reinicia por reinstalação
FOUNDER permanece ativo
pagamentos e saldo corretos
offset de sync offline sem duplicar registros
## 5) Sequência recomendada para o Codex
Ordem realista
Criar estrutura do monorepo
Criação da API base
Modelagem de domínio
Auth + tenant + RBAC
Trial + entitlements
Pacientes
Agenda
Atendimentos
Pagamentos e saldos
Dashboard e relatórios
WhatsApp manual
Offline/sync e cloud
Planos/assinaturas e seats
Pro tier
Site institucional
## 6) Prompt pronto para o Codex
Use este prompt:

"Crie a Fundação do projeto clinic-management-saas seguindo as skills do repo.
Objetivo: montar estrutura de monorepo com Flutter app e backend API, seguindo arquitetura em camadas, multi-tenancy, RBAC OWNER/ADMIN/PROFESSIONAL/STAFF, segurança by design, trial 7 dias, entitlements ESSENTIAL/PRO, cloud como fonte canônica e offline/sync.

Antes de codificar, apresente:

arquitetura proposta;
estrutura de pastas;
modelo de domínio inicial;
threat surface inicial e controles;
plano da etapa atual;
critérios de aceite.
Implementar primeiro:

estrutura do monorepo
ambiente dev/staging/prod
configs de lint/test
API base
autenticação
tenant/organization
usuários e RBAC
trial + entitlements
modelos essenciais de domínio
Após cada etapa informar:

arquivos alterados
migrations
testes
checks de segurança
build
pendências
Não avançar para módulo clínico. Não usar dados clínicos em logs, notificações ou mensagens. Respeitar a separação MVP administrativo e financeiro."

## 7) Critérios de aceite da Fundação
monorepo com app e API organizados
ambientes configurados
CI/teste básico funcionando
auth e tenant implementados
RBAC funcionando
trial e entitlement base ativos
isolamento de tenant validado
sem secrets hardcoded
documentação e arquitetura iniciais disponíveis
## 8) Recomendação final
A melhor próxima etapa é começar pela Fundação e depois pela Etapa 1, sem tentar montar o MVP completo de uma vez. Isso reduz risco, mantém a segurança e permite validar o sistema antes de entrar em agenda, atendimentos e financeiro.

Próxima etapa do roadmap: Cloud/offline/sync, em entrega separada, após o aceite
do MVP. O MVP atual exige conexão e não inclui módulo clínico.
