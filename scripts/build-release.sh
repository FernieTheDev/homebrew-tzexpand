#!/usr/bin/env bash
# Builds TZExpand.app, ad-hoc signs it, zips it, and prints version+sha256.
# Output: build/dist/TZExpand-${VERSION}.zip
set -euo pipefail

VERSION="${VERSION:-0.1.0}"
APP_NAME="TZExpand"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/build/dist"
APP="$DIST/${APP_NAME}.app"
ZIP="$DIST/${APP_NAME}-${VERSION}.zip"

cd "$ROOT"

echo "==> Building release binary"
# Universal binary needs full Xcode; fall back to native arch with CLT.
if [[ -n "${UNIVERSAL:-}" ]]; then
  swift build -c release --arch arm64 --arch x86_64
  BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
else
  swift build -c release
  BIN_DIR="$(swift build -c release --show-bin-path)"
fi
BIN="${BIN_DIR}/${APP_NAME}"
test -f "$BIN" || { echo "missing built binary at $BIN" >&2; exit 1; }

echo "==> Assembling .app bundle"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/${APP_NAME}"
chmod +x "$APP/Contents/MacOS/${APP_NAME}"

# Generate AppIcon.icns if missing, then copy it in.
if [[ ! -f "$ROOT/Resources/AppIcon.icns" ]]; then
  echo "==> Generating AppIcon.icns"
  python3 "$ROOT/scripts/generate_icon.py" "$ROOT/Resources/icon_1024.png"
  bash "$ROOT/scripts/build_icns.sh"
fi
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>dev.fernie.tzexpand</string>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>MIT licensed.</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc codesigning"
codesign --force --deep --sign - "$APP"

echo "==> Zipping"
( cd "$DIST" && ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$(basename "$ZIP")" )

SHA="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "==> Done"
echo "VERSION=$VERSION"
echo "ZIP=$ZIP"
echo "SHA256=$SHA"
