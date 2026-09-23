# Produto SaaS para Clínicas e Profissionais — Skills V5

Nome comercial: em definição. "Atendly" continua apenas como candidato.

## Visão
SaaS Flutter para Android e iOS, preparado para Web, voltado a profissionais de saúde, consultórios e clínicas.

## Modelo comercial
Duas dimensões independentes:
1. quantidade de profissionais (seats);
2. tier de funcionalidades (Essencial / Pro).

Faixas de referência por profissional/mês:
- 1 profissional: R$ 49,90
- 2–5: R$ 44,90 cada
- 6–20: R$ 39,90 cada
- 21–50: R$ 34,90 cada
- 51–100: R$ 29,90 cada
- 101+: proposta comercial, referência a partir de R$ 25,90

Preços, tiers, promoções e entitlements ficam no backend, nunca hardcoded no Flutter.

## Arquitetura
Organization -> Users -> Roles -> Professionals/Staff -> Patients -> Agenda -> Attendances -> Payments.
Flutter -> API -> autorização/tenant -> dados.
Cloud é fonte canônica; banco local suporta cache/offline/sync.

## Segurança
Security by design, least privilege, zero trust entre cliente e API, isolamento de tenants, RBAC, auditoria, proteção de segredos, criptografia em trânsito e controles apropriados em repouso, backups e recuperação.


## Estado do MVP

Fundação, identidade e núcleo administrativo/financeiro implementados. O MVP
atual requer conexão; cache/offline/sync acima descreve a arquitetura futura.
Identidade provisória azul/branco, nome ainda em definição. Android Studio e
APK debug preparados. Consulte [entregas](docs/entregas.md),
[guia Flutter](app_flutter/README.md) e [roteiro de feedback](docs/apresentacao-mvp.md).
