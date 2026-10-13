# ATO - Clipboard Manager

[![Version](https://img.shields.io/github/v/release/simonepiteo/ato-clipboard-manager?sort=semver)](https://github.com/simonepiteo/ato-clipboard-manager/releases/latest)

ATO Clipboard Manager is a modern, open-source clipboard manager for macOS, built natively with Swift, SwiftUI, and AppKit. It keeps text and image clipboard history available, lets you quickly reuse previous items, and requires no third-party dependencies.

---

## 💻 Demo

<img src="readme_example.gif" alt="Demo" width="800"/>

---

## ✨ Features

- Save and browse text and image clipboard history
- Search text entries instantly
- Switch between grid and list layouts
- Select the first nine items with keyboard shortcuts (`⌘1`–`⌘9`)
- Open the popover globally with `⌘⇧V`
- Optionally paste a selected item into the previously active app
- Move the selected item to the top of the history
- Customize language, display mode, history size, and automatic paste behavior
- Open Settings with `⌘⌥S`
- Clear clipboard history
- Optionally launch ATO automatically when you log in
- Optionally persist history to a configurable JSON file and restore it on startup
- Configure separate limits for visible and saved history, and delete the saved file from Settings
- Check GitHub Releases for updates at startup, when Settings opens, and at least once a day
- Download, verify, install, and restart into a newer DMG release directly from Settings
- Browse a scrollable list of current and previous releases with links to their release notes
- Native macOS menu bar and popover integration
- Persistent preferences with `UserDefaults`
- English and Italian localization

Clipboard history is stored in memory by default and is cleared when the app quits. JSON persistence can be enabled in Settings; its default path is `~/.ato/history.json`.

---

## 🛠️ Roadmap / To-Do

- [x] Save text and image history
- [x] Customizable settings
- [x] Search clipboard history
- [x] Auto-paste mode
- [x] Run at startup
- [x] Optional JSON history persistence
- [ ] Pin favorite items
- [ ] Customizable keyboard shortcuts
- [ ] Rich media support (files, links, etc.)
- [x] Auto-update support

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

### Create a release

Release versions follow [Conventional Commits](https://www.conventionalcommits.org/): `fix:` creates a patch release, `feat:` a minor release, and `BREAKING CHANGE:` or `type!:` a major release.

```sh
./scripts/release.sh --dry-run
./scripts/release.sh
git push --follow-tags origin HEAD
```

The release script updates `VERSION` and `CHANGELOG.md`, then creates the release commit and annotated Git tag. You can override the detected bump with `./scripts/release.sh patch`, `minor`, or `major`.

### App updates

ATO queries the public [GitHub Releases](https://github.com/simonepiteo/ato-clipboard-manager/releases) API at launch and, while it remains open, at least once every 24 hours. When a newer version is found, a red indicator appears beside the menu bar icon and a non-blocking banner in the popover offers to install it or postpone it. A manual check is always available under **Settings → Updates**. Release metadata is cached locally so the version history remains visible between launches.

When a newer stable release includes a DMG, ATO can download it, verify that the contained app has the expected bundle identifier, version, and a valid code signature, then replace the running app and restart. The app must be running from an `.app` bundle in a folder the current user can modify. Draft and prerelease versions are not offered as automatic updates.

Automatic paste requires Accessibility permission so ATO can simulate `⌘V` in the previously active app. macOS prompts for it when the feature is first used; it can also be enabled under **System Settings → Privacy & Security → Accessibility**.

### Run the tests

```sh
swift test
```

---

## License

See [LICENSE](LICENSE).
