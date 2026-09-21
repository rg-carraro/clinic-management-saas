# Skill: Plans, Modules & Entitlements

## Tiers iniciais
ESSENTIAL e PRO.

ESSENTIAL — núcleo individual/consultório:
pacientes, agenda, atendimentos, financeiro, pagamentos, saldo, WhatsApp manual, dashboard e relatórios básicos.

PRO — acrescenta recursos organizacionais:
secretária/recepção, múltiplos usuários, permissões avançadas, gestão de equipe, múltiplas agendas, relatórios avançados, automações e visão consolidada.

## Regra arquitetural
Funcionalidade habilitada = entitlement retornado pelo backend.
Não condicionar features somente a botões escondidos no Flutter.
API deve validar permissão + tenant + entitlement.

## Modularidade
Recursos futuros devem poder ser ligados/desligados por feature flags/entitlements sem duplicar aplicativos.
