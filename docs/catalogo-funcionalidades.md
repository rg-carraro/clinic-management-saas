# Catálogo de funcionalidades

Estado em 21/09/2026. `beta` indica implementação disponível para homologação;
não significa implantação em produção. Web é validada localmente; Android/iOS
compartilham o aplicativo, mas distribuição e assinatura continuam pendentes.

| Nome comercial | Descrição | Tier | Status | Plataformas | Entitlement |
| --- | --- | --- | --- | --- | --- |
| Pacientes | Cadastro, edição e arquivamento administrativo | ESSENTIAL/PRO | beta | Web, Android, iOS | patients |
| Agenda | Agendar, reagendar, cancelar e impedir sobreposição | ESSENTIAL/PRO | beta | Web, Android, iOS | agenda |
| Atendimentos | Conclusão com valor histórico preservado | ESSENTIAL/PRO | beta | Web, Android, iOS | attendances |
| Financeiro | Pagamentos parciais/totais e saldo consolidado | ESSENTIAL/PRO | beta | Web, Android, iOS | finance |
| WhatsApp manual | Lembrete e cobrança editáveis, sem envio automático | ESSENTIAL/PRO | beta | Web, Android, iOS | whatsapp |
| Dashboard | Indicadores administrativos e financeiros | ESSENTIAL/PRO | beta | Web, Android, iOS | dashboard |
| Relatórios básicos | Resumo por período e CSV na API | ESSENTIAL/PRO | beta | Web, Android, iOS; CSV via API | reports |
| Equipe e múltiplas agendas | Vínculos/papéis via API e cadastro de profissionais | PRO | beta | API; agendas no aplicativo | team |
| Offline/sync | Cache, fila persistida e resolução de conflitos | A definir | planned | Web, Android, iOS | A definir |
| Assinaturas e seats | Contratação, provedores e preços configuráveis | ESSENTIAL/PRO | planned | A definir | A definir |
| Pro avançado | Automações e relatórios avançados | PRO | planned | A definir | A definir |

O backend valida tenant, permissão e entitlement; o catálogo não substitui esses
controles. Trial dura sete dias; FOUNDER mantém a licença ativa, respeitando o
tier concedido. Preços de referência não representam cobrança implementada.
