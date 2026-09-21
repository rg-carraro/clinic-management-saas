# Skill: Development Roadmap

## Etapa 0 — Fundação
- novo projeto Flutter/Dart
- ambientes dev/staging/prod
- arquitetura em camadas
- CI, lint, testes e gestão de configuração
- nenhum segredo no repositório

## Etapa 1 — Identidade e tenancy
- cadastro/login/logout/recuperação
- Organization/Tenant
- OWNER/ADMIN/PROFESSIONAL/STAFF
- isolamento de dados no servidor
- trial de 7 dias e entitlement básico

## Etapa 2 — MVP Essencial
- pacientes/clientes
- agenda
- atendimentos
- valores individuais
- pagamentos parciais/totais
- saldo consolidado
- WhatsApp manual
- dashboard básico
- relatórios básicos

## Etapa 3 — Cloud/offline/sync
- banco local
- fila offline
- sincronização idempotente
- conflitos
- troca de aparelho
- backup/restore conforme arquitetura

## Etapa 4 — Assinaturas e seats
- planos configuráveis no backend
- quantidade de profissionais
- faixas de preço
- licença FOUNDER
- providers WEB/GOOGLE_PLAY/APPLE desacoplados
- webhooks e reconciliação

## Etapa 5 — Pro
- secretária/recepção
- permissões avançadas
- múltiplas agendas
- gestão de equipe
- relatórios avançados
- automações
- visão consolidada da clínica

## Etapa 6 — Site institucional/comercial
- landing page
- funcionalidades/tier
- preços
- cadastro/login
- área do assinante
- contratação quando aplicável
- documentação de privacidade/termos

## Etapa 7 — Clínico especializado
Somente após requisitos específicos de profissão, privacidade, segurança, auditoria, retenção e conformidade.
