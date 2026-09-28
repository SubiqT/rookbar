#!/usr/bin/env bash
# Builds a release binary and wraps it in build/rookbar.app.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/build/rookbar.app"
version="${ROOKBAR_VERSION:-0.1.0}"

swift build --package-path "$root" -c release --arch arm64 --arch x86_64
bin_dir="$(swift build --package-path "$root" -c release --arch arm64 --arch x86_64 --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/rookbar" "$app/Contents/MacOS/rookbar"
if [[ -d "$root/Resources" ]]; then
    cp -R "$root/Resources/." "$app/Contents/Resources/"
fi

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>rookbar</string>
    <key>CFBundleIdentifier</key>
    <string>com.rookbar</string>
    <key>CFBundleName</key>
    <string>rookbar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app" >/dev/null
echo "$app"
