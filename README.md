# ATO - Clipboard Manager

[![Version](https://img.shields.io/github/v/release/simonepiteo/ato-clipboard-manager?sort=semver)](https://github.com/simonepiteo/ato-clipboard-manager/releases/latest)

ATO Clipboard Manager is a modern, open-source clipboard manager for macOS, built natively with Swift, SwiftUI, and AppKit. It keeps text and image clipboard history available, lets you quickly reuse previous items, and requires no third-party dependencies.

---

## 💻 Demo

<img src="readme_example.gif" alt="Demo" width="800"/>

---

## ✨ Features

### Clipboard history

- Capture and browse copied text and images.
- Search the selected History or Pinned section, with live result counts for both tabs.
- Switch between grid and list layouts.
- Move any selected item to the top of the history.
- Pin or unpin items from their context menu and switch between History and Pinned from the popover.
- Configure separate limits for visible items and saved history.
- Keep history in memory only, or persist it privately and restore it at startup.

### Quick access and shortcuts

- Open ATO from the macOS menu bar or with a customizable global shortcut (default: `⌘⇧V`).
- Select the first nine items with customizable shortcuts (defaults: `⌘1`–`⌘9`).
- Customize every app shortcut, including Settings, Quit, and item selection.
- Use customizable shortcuts to switch between History and Pinned (defaults: `⌘⇧H` and `⌘⇧F`).
- Optionally paste the selected item directly into the previously active app.

### Personalization

- Follow the macOS appearance by default, or choose a persistent light or dark theme.
- Choose the app language, display mode, history size, and automatic paste behavior.
- Launch ATO automatically when you log in.
- Use the app in English or Italian.
- Keep preferences between launches with `UserDefaults`.

### Updates

- Check GitHub Releases automatically at startup, when Settings opens if a check is due, and at least once a day.
- Check for updates manually from Settings.
- Download, verify, install, and restart into a newer DMG release.
- Browse a scrollable list of current and previous releases with links to their release notes.

### Native macOS experience

- Built natively with SwiftUI and AppKit, with no third-party dependencies.
- Designed around the macOS menu bar and a lightweight popover.

Clipboard history is stored in memory by default and is cleared when the app quits. JSON persistence can be enabled in Settings; ATO stores it at `~/.ato/history.json`. When persistence is disabled, ATO asks whether the existing file should be kept or deleted.

Keyboard shortcuts are stored in `~/.ato/shortcut.json`. ATO rejects duplicate assignments and lets you restore all default shortcuts from Settings.

Pinned items are stored privately in `~/.ato/favorites.json` and remain available independently of clipboard history.

---

## 🛠️ Roadmap / To-Do

- [x] Save text and image history
- [x] Customizable settings
- [x] Search clipboard history
- [x] Auto-paste mode
- [x] Run at startup
- [x] Optional JSON history persistence
- [x] Pin clipboard items
- [x] Customizable keyboard shortcuts
- [x] Auto-update support
- [x] System, light, and dark themes
- [ ] Rich media support (files, links, etc.)

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

ATO appears in the menu bar with a clipboard icon. Copy some text or an image, then use the configured global shortcut (default: `⌘⇧V`) or click the icon to open the history.

### Build the app bundle

```sh
./scripts/build-app.sh
```

The release build is created at `dist/ATO Clipboard Manager.app`. To create a DMG installer instead, run:

```sh
./scripts/build-dmg.sh
```

The installer is created at `dist/ATO-Clipboard-Manager-<version>.dmg`.

### App updates

ATO queries the public [GitHub Releases](https://github.com/simonepiteo/ato-clipboard-manager/releases) API at launch, when Settings opens if a check is due, and, while it remains open, at least once every 24 hours. When a newer version is found, a red indicator appears beside the menu bar icon and a non-blocking banner in the popover offers to install it or postpone it. A manual check is always available under **Settings → Updates**. Release metadata is cached locally so the version history remains visible between launches.

When a newer stable release includes a DMG, ATO can download it, verify that the contained app has the expected bundle identifier, version, and a valid code signature, then replace the running app and restart. The app must be running from an `.app` bundle in a folder the current user can modify. Draft and prerelease versions are not offered as automatic updates.

Automatic paste requires Accessibility permission so ATO can simulate `⌘V` in the previously active app. When permission is missing, Settings explains why it is needed and links directly to **System Settings → Privacy & Security → Accessibility**. Until permission is granted, ATO still copies the selected item and shows how to paste it manually.

### Run the tests

```sh
swift test
```

---

## License

See [LICENSE](LICENSE).
