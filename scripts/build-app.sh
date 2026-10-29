#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build -c release --cache-path .build/cache --disable-sandbox
BIN_DIR=$(swift build -c release --show-bin-path --cache-path .build/cache --disable-sandbox)
APP="$PWD/build/Verbatim.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/Verbatim" "$APP/Contents/MacOS/Verbatim"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Verbatim</string>
<key>CFBundleIdentifier</key><string>local.verbatim.app</string>
<key>CFBundleName</key><string>Verbatim</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>27.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
mkdir -p "$APP/Contents/Resources"
xcrun actool Resources/Verbatim.icon \
  --compile "$APP/Contents/Resources" \
  --output-partial-info-plist "$PWD/build/icon-info.plist" \
  --app-icon Verbatim --platform macosx --target-device mac \
  --minimum-deployment-target 27.0
python3 - "$APP/Contents/Info.plist" "$PWD/build/icon-info.plist" <<'PYICON'
import plistlib
import sys
from pathlib import Path
info = Path(sys.argv[1])
metadata = plistlib.loads(info.read_bytes())
metadata.update(plistlib.loads(Path(sys.argv[2]).read_bytes()))
info.write_bytes(plistlib.dumps(metadata))
PYICON
codesign --force --sign - "$APP"
echo "Built $APP"
