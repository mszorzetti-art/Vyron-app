# Vyron — Guia de Geração e Instalação do APK Android

> **Importante sobre o ambiente do Google AI Studio:**  
> O container de execução do Google AI Studio possui Node.js, mas **não possui Java (JDK) nem Android SDK** instalados. Por isso, o arquivo binário `.apk` não pôde ser compilado diretamente aqui dentro — todo o projeto Android nativo já está configurado, sincronizado e pronto para gerar o APK em um único clique na nuvem (gratuitamente pelo navegador) ou localmente via Android Studio / Gradle.

---

## O que já está configurado neste projeto

- **Empacotamento nativo exclusivo para Android:** Capacitor 8 (`@capacitor/core`, `@capacitor/cli`, `@capacitor/android`) em `capacitor.config.ts` e `android/`.
- **Identidade do app:** Nome `Vyron`, pacote `com.marcuszorzetti.vyron`, `minSdkVersion 24` (Android 7.0+) e `targetSdkVersion 36`.
- **Ícones e Splash Screen oficiais:** Símbolo geométrico Electric Cobalt (`#315FEA`) sobre Obsidian Black (`#101216`) aplicados em todas as densidades (`mipmap-*` e `drawable-*`).
- **Preservação integral:** Toda a interface, gráficos interativos, idiomas (`PT-BR` / `EN-US`), dados locais (`localStorage`) e autenticação (`Vyron Access` com WebCrypto `https://localhost`) permanecem idênticos à versão web.
- **Segurança no AndroidManifest:** `android:allowBackup="false"`, `android:usesCleartextTraffic="false"` e `webContentsDebuggingEnabled: false`.
- **Assinatura Release preparada sem segredos no repositório:** `android/app/build.gradle` suporta variáveis de ambiente (GitHub Actions) ou `android/keystore.properties` (local, ignorado no `.gitignore`).

---

## Opção 1 — Gerar e baixar o APK direto pelo navegador (mesmo no celular)

O projeto já inclui o workflow `.github/workflows/android-apk.yml`, que compila o app em servidores Linux gratuitos do GitHub Actions com Java 21 + Android SDK.

### Passo 1: Subir o projeto para um repositório privado no GitHub
Crie um repositório **privado** no GitHub e envie os arquivos deste projeto para a branch `main`.

### Passo 2 (Recomendado para uso contínuo): Configurar assinatura Release
Se você rodar o workflow sem configurar Secrets, ele gera um **`Vyron-debug.apk`** pronto para instalar e testar.  
Para gerar **`Vyron-release-signed.apk`** com assinatura definitiva (que permite instalar futuras atualizações por cima sem desinstalar o app):

1. Em um computador com Java (`keytool`), gere sua keystore permanente uma única vez:
   ```bash
   keytool -genkeypair -v -keystore vyron-release.jks -alias vyron -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Converta o arquivo `.jks` para Base64 (Linux/macOS: `base64 -w 0 vyron-release.jks`; Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("vyron-release.jks"))`).
3. No GitHub, acesse **Settings → Secrets and variables → Actions** do repositório privado e crie 4 Secrets:
   - `ANDROID_KEYSTORE_BASE64`: conteúdo Base64 da `.jks`
   - `ANDROID_KEYSTORE_PASSWORD`: senha da keystore
   - `ANDROID_KEY_ALIAS`: `vyron`
   - `ANDROID_KEY_PASSWORD`: senha da chave
4. Guarde o arquivo `vyron-release.jks` e as senhas em local seguro (cofre de senhas/backup). **Nunca envie `.jks` para o Git.**

### Passo 3: Rodar o build e baixar no celular
1. Pelo navegador (desktop ou celular), abra seu repositório no GitHub e toque na aba **Actions**.
2. Selecione **Build Vyron Android APK** → **Run workflow** (o modo `auto` gera Release assinado se os Secrets existirem, ou Debug caso contrário).
3. Quando o workflow ficar verde (~2–4 min), entre na execução e role até **Artifacts**.
4. Toque em `vyron-android-apk-release-signed` (ou `vyron-android-apk-debug`) para baixar o `.zip` e extraia o arquivo `.apk` no celular.

---

## Opção 2 — Compilar localmente (Android Studio ou Terminal)

Requer **Node.js 22+**, **JDK 21** e **Android SDK** instalados na máquina.

### Via Terminal (Gradle)
```bash
npm install
npm run android:prepare
```
- **Para APK Debug (testes rápidos):**
  ```bash
  cd android && ./gradlew assembleDebug
  # Saída: android/app/build/outputs/apk/debug/app-debug.apk
  ```
- **Para APK Release assinado:**
  1. Copie `android/keystore.properties.example` para `android/keystore.properties` e preencha `storeFile`, `storePassword`, `keyAlias` e `keyPassword`.
  2. Execute:
     ```bash
     cd android && ./gradlew assembleRelease
     # Saída: android/app/build/outputs/apk/release/app-release.apk
     ```

### Via Android Studio
1. Execute `npm install && npm run android:prepare` na raiz do projeto.
2. Abra a pasta `android/` no **Android Studio**.
3. Aguarde o *Gradle Sync* finalizar.
4. No menu superior, use **Build → Build Bundle(s) / APK(s) → Build APK(s)** (ou **Build → Generate Signed Bundle / APK → APK** para versão assinada).

---

## Como instalar o `.apk` no seu celular Android

1. Baixe ou transfira o `.apk` (`Vyron-release-signed.apk` ou `Vyron-debug.apk`) para o aparelho.
2. Abra o arquivo pelo aplicativo **Arquivos** / **Meus Arquivos** ou diretamente pelas notificações de download do navegador.
3. Na primeira vez, o Android pedirá autorização: toque em **Configurações** e ative **Permitir desta fonte** (*Instalar apps desconhecidos*).
4. Volte e toque em **Instalar**. O app aparecerá na tela inicial com o ícone oficial **Vyron**.

---

## Como atualizar o Vyron no futuro sem perder seus dados

Para atualizar o aplicativo no celular mantendo todas as alterações salvas no `localStorage` e configurações locais:

1. **Não altere** o `applicationId` (`com.marcuszorzetti.vyron`).
2. **Use sempre a mesma keystore** (`vyron-release.jks`).
3. Antes de gerar o novo APK, incremente o `versionCode` (ex.: de `1` para `2`) e atualize o `versionName` (ex.: `"1.0.1"`) em `android/app/build.gradle`.
4. Rode `npm run android:prepare` (ou faça push para o GitHub) e instale o novo APK por cima do antigo.
