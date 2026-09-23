---
name: testing-security-release
description: Validar entregas deste projeto com testes afetados, build e revisão dos controles de segurança, registrando evidências e limites.
---

# Skill: Testing, Security & Release Gates

Nenhuma etapa é concluída sem:
- build
- testes afetados
- revisão de isolamento de tenant
- revisão de autorização
- ausência de segredos
- migrations testadas
- regressão de financeiro
- logs revisados
- documentação atualizada

Testes críticos:
- Tenant A não acessa Tenant B
- STAFF não executa ação de PROFESSIONAL sem permissão
- feature Pro não funciona apenas manipulando o cliente
- trial não reinicia por reinstalação
- FOUNDER permanece ativo
- seats/preço corretos
- pagamentos parciais e saldo corretos
- WhatsApp usa saldo real
- offline/sync não duplica registros
- sessão/token revogado deixa de funcionar

## Evidências proporcionais à mudança

- Para UI Flutter: formatar, executar análise e testes afetados; verificar navegação,
  formulários e diálogos em celular, além do layout amplo quando alterado.
- Quando houver entrega Android, compilar o APK após a última alteração de código
  ou recurso nativo. Não apresentar um APK anterior como resultado atual.
- Capturas geradas com `CAPTURE_UI` são auxiliares de inspeção. Usar
  `--update-goldens` não comprova regressão visual; conferir as imagens.
- Distinguir testes de widget, execução com API real, build debug e release assinado.
  Registrar checks não executados e por quê; não inferir homologação pelo build.
- Migrations e suíte backend são necessárias quando afetadas. Em mudanças apenas
  de apresentação, revisar a preservação de tenant/RBAC/entitlements e registrar
  que a suíte backend anterior não foi reexecutada.
- Antes de publicar, revisar o diff e arquivos preparados; manter APKs, caches,
  bancos, credenciais e chaves fora do Git. Publicar exige autorização do usuário;
  seguir a autorização já fornecida e nunca forçar push para resolver divergência.
