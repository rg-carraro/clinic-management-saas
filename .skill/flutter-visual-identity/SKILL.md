---
name: flutter-visual-identity
description: Alterar a identidade visual, telas e componentes do app Flutter deste repositório mantendo reuso e consistência entre menus e recursos Android.
---

# Identidade visual Flutter

A paleta azul/branco e a marca em folhas são provisórias. O nome comercial está
em definição; não introduza um nome definitivo sem decisão do usuário.

- Centralize cores, tipografia, bordas e temas Material em
  `app_flutter/lib/presentation/design/app_theme.dart` (`AppBrand`).
- Reutilize `BrandMark`, `SectionHeading`, `EmptyPanel` e `StatusBadge` de
  `components.dart`; extraia novos componentes quando houver reuso real.
- Mantenha estilos de campos, botões, diálogos, calendários e menus no tema;
  evite sobrescritas locais que tornem a troca de marca incompleta.
- Preserve validação, feedback de erro, estados de carregamento, permissões e
  ações financeiras ao alterar o layout. Cor não deve ser a única indicação de status.
- Verifique títulos longos, rolagem com teclado, escala de texto, diálogo em tela
  estreita, drawer no celular e rail em telas amplas. Use conteúdo fictício nas capturas.
- Ao trocar a marca, revise também ícone/splash Android em `android/app/src/main/res`,
  `AndroidManifest.xml` e variações de recursos por versão e modo noturno.
  Não presuma que uma mudança Flutter atualiza automaticamente os recursos nativos.
- O MVP usa tema claro mesmo em modo escuro. Um futuro tema escuro precisa ser
  validado como conjunto, incluindo contraste e abertura nativa.

Decisão e mapa de arquivos: `docs/adr/0002-identidade-visual-e-android.md`.
Build e importação: `app_flutter/README.md`. Registre resultados e limites em
`docs/entregas.md`, seguindo os checks afetados da skill `testing-security-release`.
