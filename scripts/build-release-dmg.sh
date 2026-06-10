#!/usr/bin/env bash
# Build a signed + notarized MarkCalm.dmg for public distribution.
#
# Requires Apple Developer Program membership and these env vars:
#   APPLE_TEAM_ID              — 10-character Team ID (developer.apple.com → Membership)
#   APPLE_ID                   — Apple ID email
#   APPLE_APP_SPECIFIC_PASSWORD — app-specific password (appleid.apple.com)
#
# Developer ID Application certificate must be in your login keychain
# (Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application).
#
# Usage:
#   export APPLE_TEAM_ID=XXXXXXXXXX
#   export APPLE_ID=you@example.com
#   export APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
#   ./scripts/build-release-dmg.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="MarkCalm"
SCHEME="MarkCalm"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_STAGING="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/${APP_NAME}.dmg"
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID (10-character Team ID)}"
: "${APPLE_ID:?Set APPLE_ID (Apple ID email)}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?Set APPLE_APP_SPECIFIC_PASSWORD}"

echo "→ Resolving packages…"
xcodebuild -resolvePackageDependencies \
  -scheme "$SCHEME" \
  -destination 'generic/platform=macOS' \
  -quiet

echo "→ Archiving (Developer ID signing)…"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR" "$DMG_PATH"
mkdir -p "$BUILD_DIR"

xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=macOS' \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -quiet

sed "s/__TEAM_ID__/$APPLE_TEAM_ID/g" scripts/ExportOptions.plist > "$EXPORT_OPTIONS"

echo "→ Exporting signed app…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -quiet

APP_PATH="$EXPORT_DIR/${APP_NAME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: exported app not found at $APP_PATH" >&2
  exit 1
fi

echo "→ Creating disk image…"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH" -quiet

echo "→ Notarizing (this may take a few minutes)…"
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

echo "→ Stapling notarization ticket…"
xcrun stapler staple "$DMG_PATH"

echo ""
echo "Done: $DMG_PATH"
echo "This .dmg is signed and notarized — users can install without right-click → Open."
