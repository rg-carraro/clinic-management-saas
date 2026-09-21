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
