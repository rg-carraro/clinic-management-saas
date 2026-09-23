> Retomada em 22/09/2026: o texto abaixo preserva o pedido inicial. Não recriar
> a fundação. Consulte `docs/entregas.md` e `docs/implementacao.md` para o estado
> atual; a próxima ação de produto é homologar/apresentar o MVP e coletar feedback.
> Para UI, use `.skill/flutter-visual-identity/SKILL.md`; para validação,
> `.skill/testing-security-release/SKILL.md`. Abra `app_flutter` no Android Studio
> conforme `app_flutter/README.md`. As skills locais ficam em `.skill/` e devem
> ser lidas explicitamente; não dependem de instalação global no Codex.

# Prompt inicial Codex — V5

Crie um novo SaaS Flutter/Dart para Android e iOS, preparado para Web, voltado a profissionais de saúde, consultórios e clínicas. O nome comercial está em definição.

AleJoias Vendas SQLite Sync v2 é SOMENTE referência funcional para UX, financeiro, pagamentos, saldo, offline e WhatsApp. Não altere nem converta mecanicamente o projeto original.

Siga as Skills V5 e o roadmap. Comece pela Fundação e não avance etapas sem build/testes.

Requisitos estruturais:
- multi-tenancy
- RBAC OWNER/ADMIN/PROFESSIONAL/STAFF
- autorização server-side
- tiers ESSENTIAL/PRO via entitlements
- seats profissionais e preços configuráveis no backend
- trial 7 dias
- licença FOUNDER
- cloud como fonte canônica + offline/sync
- segurança by design
- módulo clínico fora do MVP

Antes de codificar, apresente:
1. arquitetura proposta;
2. estrutura de pastas;
3. modelo de domínio inicial;
4. threat surface inicial e controles;
5. plano da etapa atual;
6. critérios de aceite.

Após cada etapa informe: arquivos alterados, migrations, testes, checks de segurança, build e pendências.
