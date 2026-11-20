# Vyron (Flutter Mobile — Android & iOS)

Aplicativo móvel nativo do **Vyron**, migrado integralmente da base React/TypeScript original preservando regras de negócio, identidade visual, responsividade e governança operacional.

> **Escopo estritamente mobile:** alvo primário **Android APK** (instalação direta / sideload, sem Google Play) com compatibilidade preparada para **iOS** futuro (`ios/Runner/Info.plist`). Não há alvo nem dependências Flutter Web neste projeto.

---

## Identidade & Pacotes

- **App Name:** `Vyron` (`Vyron Preview` no flavor `preview`)
- **Android Application ID:** `com.marcuszorzetti.vyron` (`com.marcuszorzetti.vyron.preview` no flavor `preview`)
- **iOS Bundle ID base:** `com.marcuszorzetti.vyron` (`ITSAppUsesNonExemptEncryption = false`)
- **Idiomas:** Português (`PT-BR`) e Inglês (`EN-US`) — paridade completa de 872 chaves.
- **Tema:** Dark-first (`Graphite #292E36`, `Obsidian Black #101216`, `Electric Cobalt #315FEA`, `Titanium #AEB7C2`, `Cool White #F1F2F3`) com suporte completo a Light Mode e tipografia local (`PlusJakartaSans`, `DMSans`, `JetBrainsMono`).

---

## Arquitetura em Camadas (`lib/`)

- `lib/core/` — Tema, tokens, i18n (`pt_br.dart`, `en_us.dart`, `formatters.dart`, `domain_labels.dart`), segurança PBKDF2-SHA256 em `Isolate` + `flutter_secure_storage`, rotas (`GoRouter`) e componentes base (`VyronCard`, `VyronMetricBlock`, `VyronDataTable`, etc.).
- `lib/domain/` — Modelos imutáveis (`Brand`, `Product`, `ContentItem`, `Channel`, `FinanceEntry`, `AutomationAgent`, `JobRun`, `ActivityLog`, `AppNotification`, `AppSettings`, `SystemControl`), engine de regras (Scoring V6.1, separação financeira, herança zero de hash SHA-256, `Stop All` fail-closed) e agregadores puros de séries gráficas.
- `lib/data/` — Seed idempotente localizado e persistência atômica em armazenamento privado do aplicativo (`AtomicStateStorage` via `path_provider`).
- `lib/application/` — `VyronStateNotifier` e `VyronAccessNotifier` (Riverpod).
- `lib/presentation/` — Gate `Vyron Access`, `AdaptiveShell`, gráficos interativos em `CustomPainter` e todos os 11 módulos:
  `Overview`, `Brands`, `Products`, `Content`, `Channels`, `Analytics`, `Finance`, `Automations`, `Activity`, `Notifications` e `Settings`.

---

## Build Android APK (GitHub Actions)

O workflow `.github/workflows/flutter-android-apk.yml` completa o scaffold do Gradle wrapper (`gradlew`, `settings.gradle.kts`, sem sobrescrever `build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt` ou recursos em `res/`), executa `flutter analyze --fatal-infos`, roda `flutter test` e compila o APK para download direto via Artifacts.

### 1. Build Preview (isolado para testes rápidos)

- **Workflow input:** `variant = preview-debug` (ou `auto` sem Secrets configurados)
- **Saída:** `Vyron-flutter-preview-debug.apk`
- **Package ID:** `com.marcuszorzetti.vyron.preview` (`Vyron Preview` — pode coexistir com o `Vyron` oficial no aparelho).

### 2. Build Oficial Assinado (Release Sideload)

Cadastre os 4 Secrets no repositório GitHub (**Settings → Secrets and variables → Actions**):

| Secret | Descrição |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Arquivo `.jks` codificado em Base64 (`base64 -w 0 vyron-release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Senha da keystore |
| `ANDROID_KEY_ALIAS` | Alias da chave de assinatura |
| `ANDROID_KEY_PASSWORD` | Senha da chave privada |

- **Workflow input:** `variant = release` (ou `auto` quando os 4 Secrets existirem)
- **Saída:** `Vyron-flutter-release-signed.apk`
- **Regra de segurança:** builds `release` **nunca** fazem fallback silencioso para a chave `debug` — se algum Secret estiver ausente, o workflow falha explicitamente.

---

## Comandos Locais (ambiente com Flutter SDK)

```bash
cd vyron_flutter
flutter pub get
flutter analyze --fatal-infos
flutter test

# APK Preview local
flutter build apk --debug --flavor preview

# APK Release local (após configurar android/keystore.properties)
cp android/keystore.properties.example android/keystore.properties
flutter build apk --release --flavor official
```

Para build iOS futuro (em macOS com Xcode):

```bash
cd vyron_flutter
flutter create --org com.marcuszorzetti --project-name vyron --platforms ios . # se Runner.xcodeproj ainda não existir no clone local
flutter build ios --no-codesign
```
