# ATO Clipboard Manager — versione nativa Swift

ATO è un clipboard manager per macOS realizzato interamente con **Swift, SwiftUI e AppKit**. Non richiede Node.js, React Native, CocoaPods o dipendenze di terze parti.

## Funzionalità

- cronologia in memoria di testi e immagini;
- ricerca istantanea negli elementi testuali;
- vista a griglia o lista;
- selezione rapida con `⌘1`–`⌘9`;
- apertura globale dalla barra menu con `⌘⇧V`;
- finestra impostazioni con `⌘⌥S`;
- incolla automatica opzionale nell'app usata in precedenza;
- interfaccia in italiano e inglese;
- preferenze persistenti tramite `UserDefaults`.

La cronologia non viene salvata su disco e viene eliminata alla chiusura dell'app, così il contenuto della clipboard resta locale alla sessione.

## Requisiti

- macOS 13 Ventura o successivo;
- Xcode 15 o successivo, oppure i relativi Command Line Tools;
- Swift 5.9 o successivo.

Verifica l'ambiente con:

```sh
swift --version
xcodebuild -version
```

## Avvio in sviluppo

Clona il repository, seleziona il branch nativo e avvia il pacchetto:

```sh
git clone https://github.com/simonepiteo/ato-clipboard-manager.git
cd ato-clipboard-manager
git switch feat/native-swift-rewrite
swift run
```

ATO compare nella barra menu con l'icona della clipboard. Copia un testo o un'immagine, poi premi `⌘⇧V` o fai clic sull'icona.

Per aprire e modificare il progetto in Xcode:

```sh
open Package.swift
```

## Test

```sh
swift test
```

## Creare l'app

Rendi eseguibili gli script una sola volta, poi genera il bundle:

```sh
chmod +x scripts/build-app.sh scripts/build-dmg.sh
./scripts/build-app.sh
```

Il risultato si trova in `dist/ATO Clipboard Manager.app`. Lo script compila in modalità release, crea il bundle macOS, genera l'icona e applica una firma ad hoc. Puoi trascinare direttamente l'app nella cartella `/Applications` per un uso locale.

## Creare il file di installazione DMG

```sh
./scripts/build-dmg.sh
```

Il file installabile viene creato come `dist/ATO-Clipboard-Manager-0.1.3.dmg`. Aprilo e trascina **ATO Clipboard Manager** sul collegamento **Applications**.

### Firma Developer ID e notarizzazione

Per distribuire l'app ad altre persone senza avvisi Gatekeeper serve un certificato “Developer ID Application” associato a un account Apple Developer:

```sh
export CODE_SIGN_IDENTITY="Developer ID Application: Nome Cognome (TEAMID)"
./scripts/build-dmg.sh
```

Per firmare, inviare automaticamente il DMG ad Apple e allegare il ticket di notarizzazione:

```sh
export CODE_SIGN_IDENTITY="Developer ID Application: Nome Cognome (TEAMID)"
export APPLE_ID="nome@example.com"
export APPLE_TEAM_ID="TEAMID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/build-dmg.sh
```

La password specifica per l'app si crea da [account.apple.com](https://account.apple.com). Non salvare queste variabili o credenziali nel repository.

## Permessi macOS

La lettura e scrittura della clipboard non richiede permessi. Se abiliti l'incolla automatico, macOS chiede l'accesso in **Impostazioni di Sistema → Privacy e sicurezza → Accessibilità**: serve esclusivamente per simulare `⌘V` nell'app usata in precedenza.

## Struttura

```text
Package.swift
Sources/ATOClipboardManager/
  AppDelegate.swift       barra menu, popover e finestre
  ClipboardStore.swift    osservazione e scrittura NSPasteboard
  HotKeyManager.swift     scorciatoia globale Carbon
  PopoverView.swift       cronologia, ricerca e menu
  SettingsView.swift      preferenze SwiftUI
Tests/
scripts/
  build-app.sh            genera il bundle .app
  build-dmg.sh            genera il file installabile .dmg
```

## Licenza

Il progetto è distribuito secondo i termini indicati nel file [LICENSE](LICENSE).
