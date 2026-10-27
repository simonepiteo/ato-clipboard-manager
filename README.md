# ATO - Clipboard Manager

[![Version](https://img.shields.io/github/v/release/simonepiteo/ato-clipboard-manager?sort=semver)](https://github.com/simonepiteo/ato-clipboard-manager/releases/latest)
[![Tests](https://github.com/simonepiteo/ato-clipboard-manager/actions/workflows/tests.yml/badge.svg)](https://github.com/simonepiteo/ato-clipboard-manager/actions/workflows/tests.yml)

ATO Clipboard Manager is a modern, open-source clipboard manager for macOS, built natively with Swift, SwiftUI, and AppKit. It keeps text, image, and file clipboard history available, lets you quickly reuse previous items, and requires no third-party dependencies.

---

## ✨ Features

ATO provides a native, menu bar–first workflow for capturing, finding, and reusing clipboard content on macOS.

### Clipboard history

#### Supported content

ATO captures and displays:

- Text and images.
- Folders and files of any type.
- Finder selections containing multiple files. Each selection is preserved as a single history item and displays native file icons, filenames, and the total item count.

#### Browsing and search

- Browse items in either a grid or list layout.
- Search within the active **History** or **Pinned** section.
- View the number of matching results in both sections while searching.
- Configure separate limits for the number of items shown and the number retained in saved history.

#### Item management

- Move an item to the top of the history.
- Pin or unpin an item from its context menu, or press `⌘P` after selecting it with the arrow keys.
- Switch between **History** and **Pinned** directly from the popover.
- Delete individual history items from their context menu. Pinned items must be unpinned before they can be deleted.
- Choose **Select** from an item’s context menu to enter multiple selection. Click cards or use the arrow keys and Return to select or deselect them without copying.
- In selection mode, use the toolbar below search to select or deselect all visible items, pin or unpin the selection, or delete it. Unpin all selected items before deleting; use the **×** button or Escape to leave selection mode and clear the card focus while keeping the popover open.
- The configured pin shortcut (default `⌘P`) also toggles the selected group: it pins all selected items when any are unpinned, and unpins them when all are pinned.

### Quick access and keyboard shortcuts

ATO can be opened from the macOS menu bar or controlled entirely with customizable keyboard shortcuts.

| Action | Default shortcut |
| --- | --- |
| Open ATO | `⌘⇧V` |
| Select one of the first nine items | `⌘1`–`⌘9` |
| Pin or unpin the keyboard-selected item | `⌘P` |
| Enter selection mode | `⌘⇧M` |
| Switch to History | `⌘⇧H` |
| Switch to Pinned | `⌘⇧F` |

Shortcuts for item selection, pinning, Settings, Quit, and section navigation can all be reassigned. ATO prevents duplicate assignments and provides an option to restore the default configuration.

When automatic paste is enabled, selecting an item also pastes it into the previously active application. Otherwise, the item is only copied to the system clipboard.

### Personalization and preferences

The following options are available from Settings:

- **Appearance:** follow the macOS system appearance or use a persistent light or dark theme.
- **Language:** use ATO in English or Italian.
- **Layout:** choose between grid and list display modes.
- **Card previews:** enable or disable enlarged hover previews and set the delay from 1 to 30 seconds (default: 3 seconds).
- **History:** configure visible and saved history limits, and optionally enable persistent history.
- **Paste behavior:** independently enable automatic paste for clicks, item shortcuts, and Return after keyboard navigation.
- **Startup:** launch ATO automatically when logging in to macOS.

General preferences are retained between launches with `UserDefaults`.

### History and pinned-item persistence

Clipboard history is kept in memory by default and cleared when ATO quits. Persistent history can be enabled in Settings; when enabled, ATO restores saved items at startup.

Pinned items are stored separately and remain available independently of clipboard history.

| Data | Location | Behavior |
| --- | --- | --- |
| Clipboard history | `~/.ato/history.json` | Created only when persistent history is enabled. When persistence is disabled, ATO asks whether to keep or delete the existing file. |
| Pinned items | `~/.ato/favorites.json` | Stored privately and retained between launches. |
| Keyboard shortcuts | `~/.ato/shortcut.json` | Stores custom shortcut assignments. |

### Updates

ATO integrates with GitHub Releases to keep the application up to date:

- Automatically checks at startup, when Settings opens if a check is due, and at least once every 24 hours while running.
- Supports manual update checks from Settings.
- Displays current and previous versions in a scrollable release list, with links to release notes.
- Downloads, verifies, and installs newer DMG releases, then restarts into the updated application.

### Native macOS experience

- Built with SwiftUI and AppKit, with no third-party dependencies.
- Designed as a lightweight menu bar application with a native popover interface.

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
- [x] Single-file and multi-file clipboard support

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

ATO appears in the menu bar with a clipboard icon. Copy some text, an image, or one or more files, then use the configured global shortcut (default: `⌘⇧V`) or click the icon to open the history.

### Build the app bundle

```sh
./scripts/setup-local-signing.sh
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
