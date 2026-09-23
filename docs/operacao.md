# Operação e validação

## Ambientes

`infra/environments` contém exemplos dev/staging/prod sem credenciais.
Nunca versionar `.env`, banco local, backups ou chaves de assinatura.
Dev usa SQLite; staging/prod exigem PostgreSQL e HTTPS. Habilite TLS no banco
quando atravessar redes não confiáveis. Separe credenciais e bancos por ambiente.
O operador deve restringir rede/acesso e criptografar discos e backups.

A API usa processos sem access log por padrão. Proxies devem remover query strings
sensíveis dos logs e jamais registrar corpos, senhas ou Authorization. Configure
limite de corpo no ingresso (por exemplo 1 MiB), limites de conexão e HTTPS.
Sirva o app com `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff` e
HTTPS. URLs de recuperação contêm segredo temporário; não use analytics nessas páginas.

## Backup e restauração

1. `pg_dump --format=custom` com conexão obtida do secret manager; saída fora do git.
2. Armazenar criptografado, restringir acesso e aplicar retenção definida pelo operador.
3. Em banco isolado, restaurar com `pg_restore --no-owner --no-acl`.
4. Conferir migrations, contagens, saldo e login usando dados de teste mascarados.
5. Somente promover uma restauração depois de validada. Nunca restaurar sobre
   produção como teste nem executar downgrade destrutivo para rollback.

CI valida PostgreSQL, migrations, isolamento e concorrência de pagamentos.
O teste de migrations faz upgrade/downgrade/upgrade em SQLite descartável e compara
schema com os modelos. Os testes de integração usam exclusivamente um banco cujo
nome termina em `_test`; nunca configurar credenciais de produção nesse parâmetro.

## Builds

Web: `flutter build web --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.seu-dominio`.
Android de desenvolvimento: `flutter build apk --debug` com API alcançável.
O template Android ainda usa chave de debug para build release: configure assinatura
própria antes de distribuir. iOS exige macOS/Xcode e assinatura Apple.
Builds de produção recusam API sem HTTPS em tempo de inicialização do aplicativo.

Preview local sem logs de URLs: `python infra/serve_web.py`, depois abra
`http://localhost:8080` com a API em `http://localhost:8000`.


## Homologação Android do MVP

Importação e comandos: [guia Android Studio](../app_flutter/README.md).
No emulador, o padrão de desenvolvimento é `http://10.0.2.2:8000`; em aparelho
físico configure `API_BASE_URL` HTTPS acessível. A API deve estar ligada.
O APK fica em `app_flutter/build/app/outputs/flutter-apk/app-debug.apk`, ignorado
pelo Git. Não há release de loja nesta entrega. Faça o fluxo com dados fictícios
antes da apresentação, conforme [roteiro](apresentacao-mvp.md).
