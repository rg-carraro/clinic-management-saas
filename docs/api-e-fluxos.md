# API e fluxos do MVP

OpenAPI: `shared_contracts/openapi.json`. Em dev, Swagger em `/docs`.
Rotas públicas: `/health`, `/ready` e autenticação/reset. As demais exigem
`Authorization: Bearer TOKEN` e `X-Tenant-ID` de um vínculo ativo.
Uma sessão pode selecionar somente organizações retornadas por seu login.

| Área | Rotas principais | Regras |
| --- | --- | --- |
| Identidade | POST `/v1/auth/register`, `/login`, `/logout` (com prefixo auth) | Senha 12–128 caracteres, rate limit e sessão de 12h |
| Recuperação | POST `/v1/auth/password/forgot`, `/reset` | Código expira em 30 min; uso único; revoga sessões |
| Contexto | GET `/v1/me` | Papel, organização, trial e entitlements atuais |
| Equipe | GET/POST `/v1/members`; POST `/{id}/deactivate` | Pro e OWNER/ADMIN; OWNER protegido |
| Pacientes | GET/POST `/v1/patients`; PATCH `/{id}` | Arquivamento preserva histórico; sem dados clínicos |
| Catálogo | GET/POST `/v1/services`, `/professionals`; PATCH `/services/{id}` | Escrita OWNER/ADMIN; Essencial tem uma agenda |
| Agenda | GET/POST `/v1/appointments`; PATCH `/{id}`; POST `/{id}/cancel` | Horários com fuso; sem sobreposição por profissional |
| Atendimento | POST `/v1/appointments/{id}/complete` | OWNER/ADMIN/PROFESSIONAL; recepção não conclui |
| Financeiro | GET `/v1/attendances`, `/payments?attendance_id=…`; POST `/payments` | Centavos inteiros, transação e Idempotency-Key obrigatória |
| Saldo | GET `/v1/patients/{id}/balance`, `/v1/dashboard` | Derivado de atendimentos e pagamentos reais |
| Relatório | GET `/v1/reports/summary?start=…&end=…&format=json` | Epoch UTC, início inclusivo/fim exclusivo; até 366 dias; CSV opcional |
| WhatsApp | GET `/v1/patients/{id}/whatsapp?kind=balance` ou `reminder` | Telefone país+DDD, texto administrativo, envio manual |

Listas de pacientes, agenda e atendimentos usam `limit` (1–100) e `offset`.
O aplicativo carrega as páginas necessárias; agenda filtra pelo dia selecionado.
Profissional só altera sua agenda e seus atendimentos/pagamentos; leituras
administrativas são compartilhadas dentro da clínica conforme o papel.
STAFF pode cadastrar pacientes, agendar e registrar recebimentos; não pode
concluir atendimento, editar catálogo ou gerir equipe.

## Fluxo manual de aceite

1. Criar conta e entrar. Em Configurações, cadastrar o próprio profissional e um
   serviço com valor de R$ 150,00. Cadastrar paciente com telefone de teste.
2. Agendar hoje, concluir o atendimento e conferir R$ 150,00 no financeiro.
3. Registrar Pix de R$ 50,00: saldo deve ser R$ 100,00. Registrar os R$ 100,00
   restantes: saldo zero. O servidor recusa pagamento acima do saldo.
4. Alterar o valor padrão para R$ 200,00: atendimento antigo continua R$ 150,00.
5. Abrir WhatsApp: revisar o texto e fechar sem enviar a terceiros durante teste.
6. Conferir dashboard e relatório. Valores por atendimento usam a data do
   atendimento; recebimentos usam a data real do registro do pagamento. O saldo
   consolidado inclui todos os períodos e é identificado assim na interface.
7. Criar outra clínica e tentar usar IDs da primeira: API nega acesso.
8. Sair: o token anterior deve retornar 401. Recuperar senha via SMTP de teste.

Repetir pagamento após falha de rede usa a mesma chave de operação enquanto o
formulário está aberto. Consulte pagamentos/saldo antes de iniciar uma nova
operação se o resultado anterior for incerto. Conclusão de atendimento também
é idempotente pelo agendamento e não cria cobrança duplicada.

## Limites explícitos

MVP online, BRL, sem prontuário, gateway de assinatura, estorno financeiro ou
sincronização offline. Não há emissão fiscal; Attendance representa o valor a
receber. Integração WhatsApp apenas abre uma mensagem, nunca envia automaticamente.
Armazenamento protegido, TLS, SMTP, backup/restore e assinatura das lojas devem
ser provisionados antes de uso real em produção.
