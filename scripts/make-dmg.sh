#!/usr/bin/env bash
# Build DeskCat.app (Release) and wrap it in a drag-to-Applications DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="DeskCat"
SCHEME="FocusDesk"
VERSION="${VERSION:-1.0.0}"
DERIVED="${DERIVED:-/tmp/DeskCatRelease}"
STAGE="${ROOT}/build/dmg-stage"
OUT_DIR="${ROOT}/build"
DMG_NAME="${PRODUCT_NAME}-${VERSION}.dmg"
DMG_PATH="${OUT_DIR}/${DMG_NAME}"
VOL_NAME="${PRODUCT_NAME}"

cd "$ROOT"
rm -rf "$DERIVED" "$STAGE"
mkdir -p "$STAGE" "$OUT_DIR"

echo "→ Building ${PRODUCT_NAME} (Release)…"
xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -destination 'platform=macOS' \
  build \
  | grep -E '^(error:|warning:|\\*\\*|Export|Touch|CodeSign|Validate|note:.*succeeded|BUILD)' || true

APP="${DERIVED}/Build/Products/Release/${PRODUCT_NAME}.app"
if [[ ! -d "$APP" ]]; then
  echo "error: expected app at $APP" >&2
  exit 1
fi

echo "→ Staging DMG contents…"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# Optional background — keep layout simple for hdiutil
rm -f "$DMG_PATH" "${DMG_PATH}.tmp.dmg" 2>/dev/null || true

echo "→ Creating ${DMG_NAME}…"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "→ Done: $DMG_PATH"
ls -lh "$DMG_PATH"
