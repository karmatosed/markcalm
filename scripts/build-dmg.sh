#!/usr/bin/env bash
# Build an unsigned MarkCalm.dmg for local testing or GitHub Releases.
# Recipients must right-click → Open the first time (see README § Try MarkCalm now).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="MarkCalm"
SCHEME="MarkCalm"
BUILD_DIR="$ROOT/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
DMG_STAGING="$BUILD_DIR/dmg"
DMG_PATH="$BUILD_DIR/${APP_NAME}.dmg"

echo "→ Resolving packages…"
xcodebuild -resolvePackageDependencies \
  -scheme "$SCHEME" \
  -destination 'platform=macOS' \
  -quiet

echo "→ Building Release (ad-hoc signed)…"
xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  build \
  -quiet

APP_PATH="$(find "$DERIVED_DATA/Build/Products/Release" -maxdepth 1 -name "${APP_NAME}.app" -print -quit)"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "error: could not find ${APP_NAME}.app in build output" >&2
  exit 1
fi

echo "→ Creating disk image…"
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH" -quiet

echo ""
echo "Done: $DMG_PATH"
echo "Share this .dmg — recipients follow README § Try MarkCalm now to install."
