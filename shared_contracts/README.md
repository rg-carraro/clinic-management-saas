# Contratos HTTP

API versionada em `/v1`. OpenAPI em `openapi.json` é exportado pelo backend.
Valores financeiros são inteiros em centavos (BRL). Horários usam ISO 8601 com
fuso; persistência em UTC. Autorização: Bearer e `X-Tenant-ID` validado no backend.
Nunca enviar campos clínicos. Erros não incluem payloads de entrada.
