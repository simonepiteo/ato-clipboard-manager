# ATO - Clipboard Manager

[![Version](https://img.shields.io/github/v/release/simonepiteo/ato-clipboard-manager?sort=semver)](https://github.com/simonepiteo/ato-clipboard-manager/releases/latest)
[![License](https://img.shields.io/github/license/simonepiteo/ato-clipboard-manager)](https://github.com/simonepiteo/ato-clipboard-manager/blob/main/LICENSE)

ATO Clipboard Manager is a modern, open-source clipboard manager for macOS, built with React Native and Swift/ObjC. It helps you keep track of your clipboard history, quickly access previous items, and boost your productivity.

---

## 💻 Demo

<img src="readme_example.gif" alt="Demo" width="800"/>

---

## ✨ Features

- Save and browse clipboard history (text & images)
- Quick paste with keyboard shortcuts (⌘1–⌘9)
- Popover window for fast access (⌘⇧V)
- Settings window (⌘⌥S) to customize:
  - Language
  - Display mode (grid/list)
  - Max history items
  - Automatic paste
  - Shortcuts
- Clear clipboard history
- macOS native integration (menu bar, popover, etc.)
- Persistent storage with AsyncStorage
- Multi-language support (i18n)

---

## 🛠️ Roadmap / To-Do

- [x] Save text & image history
- [x] Customizable settings
- [x] Search clipboard history
- [x] Auto-paste mode
- [x] Run on startup
- [ ] Pin favorite items
- [ ] Customizable keyboard shortcuts
- [ ] Rich media support (files, links, etc.)
- [ ] Auto-update support

---

## 🚀 Getting Started

1. **Clone the repo:**

   ```sh
   git clone https://github.com/simonepiteo/ato-clipboard-manager.git
   cd ato-clipboard-manager
   ```

2. **Install dependencies:**

   ```sh
   npm install
   ```

3. **Run on macOS:**
   ```sh
   npm run macos
   ```
