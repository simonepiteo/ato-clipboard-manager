# ATO - Clipboard Manager

[![Version](https://img.shields.io/github/v/release/simonepiteo/ato-clipboard-manager?sort=semver)](https://github.com/simonepiteo/ato-clipboard-manager/releases/latest)

ATO Clipboard Manager is a modern, open-source clipboard manager for macOS, built natively with Swift, SwiftUI, and AppKit. It keeps text and image clipboard history available for the current session, lets you quickly reuse previous items, and requires no third-party dependencies.

---

## 💻 Demo

<img src="readme_example.gif" alt="Demo" width="800"/>

---

## ✨ Features

- Save and browse text and image clipboard history for the current session
- Search text entries instantly
- Switch between grid and list layouts
- Select the first nine items with keyboard shortcuts (`⌘1`–`⌘9`)
- Open the popover globally with `⌘⇧V`
- Optionally paste a selected item into the previously active app
- Move the selected item to the top of the history
- Customize language, display mode, history size, and automatic paste behavior
- Open Settings with `⌘⌥S`
- Clear clipboard history
- Native macOS menu bar and popover integration
- Persistent preferences with `UserDefaults`
- English and Italian localization

Clipboard history is stored in memory only and is cleared when the app quits.

---

## 🛠️ Roadmap / To-Do

- [x] Save text and image history
- [x] Customizable settings
- [x] Search clipboard history
- [x] Auto-paste mode
- [ ] Run at startup
- [ ] Pin favorite items
- [ ] Customizable keyboard shortcuts
- [ ] Rich media support (files, links, etc.)
- [ ] Auto-update support

---

## 🚀 Getting Started

### Requirements

- macOS 13 Ventura or later
- Swift 5.9 or later, included with Xcode 15 or the corresponding Command Line Tools

### Run from source

1. Clone the repository:

   ```sh
   git clone https://github.com/simonepiteo/ato-clipboard-manager.git
   cd ato-clipboard-manager
   ```

2. Build and run the native macOS app:

   ```sh
   swift run
   ```

ATO appears in the menu bar with a clipboard icon. Copy some text or an image, then press `⌘⇧V` or click the icon to open the history.

### Build the app bundle

```sh
./scripts/build-app.sh
```

The release build is created at `dist/ATO Clipboard Manager.app`. To create a DMG installer instead, run:

```sh
./scripts/build-dmg.sh
```

Automatic paste requires Accessibility permission so ATO can simulate `⌘V` in the previously active app. macOS prompts for it when the feature is first used; it can also be enabled under **System Settings → Privacy & Security → Accessibility**.

### Run the tests

```sh
swift test
```

---

## License

See [LICENSE](LICENSE).
