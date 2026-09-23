# ADR 0002 — Identidade provisória e execução Android

Data: 22/09/2026. Status: adotado para o MVP, marca sujeita a revisão.

## Contexto

O MVP será apresentado para coletar requisitos. Precisa de aparência coerente em
todos os menus e execução simples no Android Studio, sem fixar uma marca comercial.

## Decisão

Manter Flutter/Material 3 com tema próprio claro azul e branco, cartões brancos,
fundo suave e marca provisória em folhas. Não adicionar bibliotecas ou fontes
externas para esta repaginação. O tema claro também é usado com sistema escuro.

| Responsabilidade | Arquivo |
| --- | --- |
| Paleta, tipografia, raio e temas Material | `app_flutter/lib/presentation/design/app_theme.dart` |
| Marca, títulos, estados vazios e status | `app_flutter/lib/presentation/design/components.dart` |
| Acesso, cadastro e recuperação | `app_flutter/lib/presentation/auth_screen.dart` |
| Seis áreas do MVP e navegação responsiva | `app_flutter/lib/presentation/home_screen.dart` |
| Formulários compartilhados | `app_flutter/lib/presentation/editor.dart` |
| Ícone nativo | `app_flutter/android/app/src/main/res/drawable/brand_icon.xml` |
| Abertura e variações Android | `app_flutter/android/app/src/main/res/` e `AndroidManifest.xml` |
| Execução na IDE | `app_flutter/.run/MVP Android Emulator.run.xml` |
| Endereço da API | `app_flutter/lib/shared/config.dart` |

`API_BASE_URL` explícita prevalece. Sem definição, Android usa `10.0.2.2:8000`
e os demais alvos usam `localhost:8000`, ambos HTTP de desenvolvimento.
Staging/prod continuam exigindo HTTPS na inicialização. Aparelho físico precisa
de URL alcançável configurada. HTTP local está permitido apenas no manifest debug.

## Consequências

Uma futura marca pode substituir tokens/componentes sem reescrever regras de
negócio. Os recursos nativos Android precisam de atualização própria. O layout
usa drawer em telas estreitas e rail a partir de 900 pixels lógicos.
Sessões seguem em memória; conexão com a API é obrigatória.

Build APK debug e testes de widgets não substituem homologação com API real,
assinatura de produção ou testes iOS. Capturas locais ficam em `.tools`, ignorado
pelo Git; a rotina de captura está em `app_flutter/test/mvp_test.dart`.

## Verificação e continuidade

Evidências em [entregas](../entregas.md). Guia da IDE em
[README Flutter](../../app_flutter/README.md). O feedback da apresentação será
registrado pelo [roteiro](../apresentacao-mvp.md), antes de redefinir prioridades.
