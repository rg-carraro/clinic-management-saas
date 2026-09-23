# Aplicativo Flutter — Android Studio

## Abrir e executar

1. No Android Studio, habilite os plugins **Flutter** e **Dart**.
2. Use **Open** e selecione a pasta `app_flutter` deste repositório.
3. Configure o Flutter SDK em `C:\Users\rgcar\git\clinic-management-saas\.tools\flutter`
   nesta máquina. O SDK usado nesta entrega é Flutter 3.47.5 / Dart 3.13.4.
4. Aguarde a resolução das dependências (Pub get). Use o JDK integrado do
   Android Studio e instale os SDKs solicitados pelo Gradle, se necessário.
5. Selecione **MVP Android Emulator**, escolha um emulador Android e pressione Run.
   A configuração está versionada em `.run/`. A execução padrão de `lib/main.dart`
   também usa `http://10.0.2.2:8000` no Android.

O arquivo `android/local.properties` já aponta para os SDKs desta máquina, mas é
local e ignorado pelo Git. Em outro computador, a IDE deve gerar os caminhos locais.
Abra `app_flutter/android` separadamente apenas se precisar trabalhar no módulo
nativo; o projeto principal a abrir é `app_flutter`.

## API para a apresentação

Em um terminal na raiz do repositório:

```powershell
cd api_backend
..\.tools\uv\bin\uv.exe sync --group dev
..\.tools\uv\bin\uv.exe run alembic upgrade head
..\.tools\uv\bin\uv.exe run uvicorn clinic.presentation.api:app --no-access-log
```

Mantenha esse terminal aberto. O emulador acessa a API do computador por
`10.0.2.2`. O app requer conexão; sessões ficam em memória.
Para aparelho físico, use uma API HTTPS acessível e substitua o argumento da
configuração Run por `--dart-define=API_BASE_URL=https://seu-endereco`.
Para staging/prod, acrescente `--dart-define=APP_ENV=staging` ou `prod`.

## Gerar APK de apresentação

No terminal, dentro de `app_flutter`:

```powershell
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat build apk --debug
```

Saída: `build/app/outputs/flutter-apk/app-debug.apk`. Na IDE, use a configuração
Flutter acima para compilar e instalar no emulador. O APK debug usa HTTP local;
para demonstrar em um celular fora do computador, gere com a URL HTTPS da API.
A assinatura release ainda é de desenvolvimento e não serve para publicação.

## Identidade visual

O tema está em `lib/presentation/design/app_theme.dart`: paleta, tipografia,
bordas e estilos de botões, campos, menus, calendários e diálogos. Componentes
compartilhados ficam em `design/components.dart`. Azul e branco são provisórios;
o nome comercial continua em definição. A marca em forma de folhas é provisória.
Ícone e abertura Android ficam em `android/app/src/main/res`; atualize também
esses recursos quando a marca definitiva for escolhida. O tema é claro, inclusive
com o sistema em modo escuro, para manter consistência nesta apresentação.

Veja [roteiro de apresentação](../docs/apresentacao-mvp.md).
