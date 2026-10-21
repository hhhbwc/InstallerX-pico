#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
case "$SCRIPT_PATH" in
    */*) MODULE_DIR="$(cd -- "${SCRIPT_PATH%/*}" && pwd)" ;;
    *) MODULE_DIR="$(pwd)" ;;
esac
ROOT_DIR="$(cd -- "$MODULE_DIR/../.." && pwd)"

read_prop() {
    sed -n "s/^$1=//p" "$MODULE_DIR/module.prop" | tr -d '\r' | head -n 1
}

VERSION_NAME="$(read_prop version)"
MODULE_VERSION_CODE="$(read_prop versionCode)"
VERSION_CODE="${VERSION_CODE:-$MODULE_VERSION_CODE}"
APP_ID="${APP_ID:-com.android.packageinstaller}"
VARIANT="${VARIANT:-Unstable}"

if [ -z "$VERSION_CODE" ]; then
    echo "module.prop is missing versionCode" >&2
    exit 1
fi

cd "$ROOT_DIR"
./gradlew ":app:assemble${VARIANT}Debug" \
    -PAPP_ID="$APP_ID" \
    -PVERSION_CODE="$VERSION_CODE" \
    --no-configuration-cache

APK_DIR="app/build/outputs/apk/$VARIANT/debug"
APK_PATH="$(find "$APK_DIR" -maxdepth 1 -type f -name '*.apk' | head -n 1)"
if [ -z "$APK_PATH" ]; then
    echo "APK not found in $APK_DIR; run the Gradle build first" >&2
    exit 1
fi

mkdir -p "$MODULE_DIR/system/priv-app/PackageInstaller"
cp "$APK_PATH" "$MODULE_DIR/system/priv-app/PackageInstaller/PackageInstaller.apk"

mkdir -p "$MODULE_DIR/dist"
ZIP_NAME="InstallerX-PICO-system-${VERSION_NAME}-${VERSION_CODE}.zip"
cd "$MODULE_DIR"
rm -f "dist/$ZIP_NAME"

if command -v zip >/dev/null 2>&1; then
    zip -r "dist/$ZIP_NAME" module.prop customize.sh service.sh action.sh uninstall.sh META-INF system >/dev/null
elif command -v 7z >/dev/null 2>&1; then
    7z a -tzip "dist/$ZIP_NAME" module.prop customize.sh service.sh action.sh uninstall.sh META-INF system >/dev/null
elif [ -x "/c/Program Files/7-Zip/7z.exe" ]; then
    "/c/Program Files/7-Zip/7z.exe" a -tzip "dist/$ZIP_NAME" module.prop customize.sh service.sh action.sh uninstall.sh META-INF system >/dev/null
else
    echo "Need 'zip' or '7z' to package the module" >&2
    exit 1
fi

echo "APK:    $APK_PATH"
echo "Module: $MODULE_DIR/dist/$ZIP_NAME"
