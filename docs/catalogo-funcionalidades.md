# Catálogo de funcionalidades

Estado em 22/09/2026. `beta` indica implementação disponível para homologação;
não significa implantação em produção. Web tem validação local anterior; Android tem APK debug compilado e testes
de widgets. Execução com API real na IDE ainda requer homologação. iOS não foi
compilado. Assinatura e distribuição em lojas continuam pendentes.

| Nome comercial | Descrição | Tier | Status | Plataformas | Entitlement |
| --- | --- | --- | --- | --- | --- |
| Pacientes | Cadastro, edição e arquivamento administrativo | ESSENTIAL/PRO | beta | Web, Android, iOS | patients |
| Agenda | Agendar, reagendar, cancelar e impedir sobreposição | ESSENTIAL/PRO | beta | Web, Android, iOS | agenda |
| Atendimentos | Conclusão com valor histórico preservado | ESSENTIAL/PRO | beta | Web, Android, iOS | attendances |
| Financeiro | Pagamentos parciais/totais e saldo consolidado | ESSENTIAL/PRO | beta | Web, Android, iOS | finance |
| WhatsApp manual | Lembrete e cobrança editáveis, sem envio automático | ESSENTIAL/PRO | beta | Web, Android, iOS | whatsapp |
| Dashboard | Indicadores administrativos e financeiros | ESSENTIAL/PRO | beta | Web, Android, iOS | dashboard |
| Relatórios básicos | Resumo por período, cópia CSV no app e CSV na API | ESSENTIAL/PRO | beta | Web, Android, iOS; API | reports |
| Equipe e múltiplas agendas | Adicionar/revogar acessos em Configurações, papéis e profissionais | PRO | beta | Web, Android, iOS; API | team |
| Offline/sync | Cache, fila persistida e resolução de conflitos | A definir | planned | Web, Android, iOS | A definir |
| Assinaturas e seats | Contratação, provedores e preços configuráveis | ESSENTIAL/PRO | planned | A definir | A definir |
| Pro avançado | Automações e relatórios avançados | PRO | planned | A definir | A definir |

O backend valida tenant, permissão e entitlement; o catálogo não substitui esses
controles. Trial dura sete dias; FOUNDER mantém a licença ativa, respeitando o
tier concedido. Preços de referência não representam cobrança implementada.
