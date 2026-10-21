#!/system/bin/sh

MODDIR=${0%/*}
FLAG="$MODDIR/.cache_cleared"

# PackageManager caches the scan result of the replaced system package. Clear it once after
# install/update so the first boot picks up the new APK; the flag keeps later boots untouched.
[ -f "$FLAG" ] && exit 0

rm -rf /data/system/package_cache/*
touch "$FLAG" 2>/dev/null
