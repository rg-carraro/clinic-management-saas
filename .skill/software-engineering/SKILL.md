---
name: software-engineering
description: Aplicar as convenções de arquitetura e manutenção deste monorepo Flutter e FastAPI ao implementar mudanças.
---

# Skill: Software Engineering Standards

- arquitetura em camadas e responsabilidades claras
- SOLID quando aplicável, sem abstração excessiva
- código revisável e mudanças pequenas
- lint/format automatizados
- testes unitários, integração e fluxos críticos
- migrations versionadas
- API versionada/compatível
- feature flags para rollout quando necessário
- ambientes separados dev/staging/prod
- CI com build/test/security checks
- observabilidade sem vazar dados sensíveis
- documentação de decisões arquiteturais (ADR)
- changelog/release notes
- rollback planejado
- sem credenciais hardcoded
- dependências mínimas e justificadas

## Interface e ambientes Flutter

- Preserve tema e componentes compartilhados em `app_flutter/lib/presentation/design`;
  consulte a skill `flutter-visual-identity` quando alterar a interface.
- Abra `app_flutter` como projeto Flutter; mantenha configurações compartilháveis em
  `.run/`, sem versionar `.idea`, SDKs ou `local.properties`.
- `API_BASE_URL` explícita tem precedência; Android usa o host do emulador em dev.
  Não transforme `10.0.2.2` em endereço de produção ou de aparelho físico.
- Documente mudanças de arquitetura em `docs/adr` e o resultado em `docs/entregas.md`.
