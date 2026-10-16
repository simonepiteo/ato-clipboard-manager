#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_NAME="ATO Clipboard Manager"
BUNDLE_IDENTIFIER="com.simonepiteo.ato-clipboard-manager"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
APP_BUNDLE="$PROJECT_ROOT/dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
ICON_SOURCE="$PROJECT_ROOT/macos/atoClipboardManager-macOS/Assets.xcassets/AppIcon.appiconset/ATO_1024.png"
CACHE_ROOT="$PROJECT_ROOT/.build/caches"

source "$PROJECT_ROOT/scripts/code-signing.sh"
ato_resolve_signing_identity

if [[ ! "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  print -u2 "Invalid version in VERSION: $VERSION"
  exit 1
fi

mkdir -p "$CACHE_ROOT/clang" "$CACHE_ROOT/swiftpm"
export CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_ROOT/swiftpm"

swift build -c release --disable-sandbox
BIN_PATH="$(swift build -c release --disable-sandbox --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN_PATH/ATOClipboardManager" "$CONTENTS/MacOS/ATOClipboardManager"
cp "$PROJECT_ROOT/Assets/PrivacyInfo.xcprivacy" "$CONTENTS/Resources/PrivacyInfo.xcprivacy"

ICON_FILE=""
if [[ -f "$ICON_SOURCE" ]]; then
  sips -s format icns "$ICON_SOURCE" --out "$CONTENTS/Resources/AppIcon.icns" >/dev/null
  ICON_FILE="AppIcon"
fi

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleExecutable</key><string>ATOClipboardManager</string>
<key>CFBundleIconFile</key><string>$ICON_FILE</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_IDENTIFIER</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSAppleEventsUsageDescription</key><string>ATO restores focus to the previous app after selecting a clipboard item.</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Simone Piteo</string>
</dict></plist>
PLIST

if [[ "$ATO_LOCAL_SIGNING" == true ]]; then
  codesign --force --options runtime "$ATO_SIGNING_TIMESTAMP" --sign "$CODE_SIGN_IDENTITY" \
    --requirements "=designated => identifier \"$BUNDLE_IDENTIFIER\" and anchor H\"$CODE_SIGN_IDENTITY\"" \
    "$APP_BUNDLE"
elif [[ "$CODE_SIGN_IDENTITY" != "-" ]]; then
  codesign --force --options runtime "$ATO_SIGNING_TIMESTAMP" --sign "$CODE_SIGN_IDENTITY" "$APP_BUNDLE"
else
  codesign --force --timestamp=none --sign - "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

print "Created: $APP_BUNDLE"
