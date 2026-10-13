#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
APP_NAME="ATO Clipboard Manager"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
DMG_NAME="ATO-Clipboard-Manager-$VERSION.dmg"
APP_BUNDLE="$PROJECT_ROOT/dist/$APP_NAME.app"
DMG_PATH="$PROJECT_ROOT/dist/$DMG_NAME"
DMG_STAGE="$PROJECT_ROOT/.build/dmg-stage"

"$PROJECT_ROOT/scripts/build-app.sh"

rm -rf "$DMG_STAGE" "$DMG_PATH"
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGE" -ov -format UDZO "$DMG_PATH"

if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
  codesign --force --timestamp --sign "$CODE_SIGN_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

print "Created installer: $DMG_PATH"
