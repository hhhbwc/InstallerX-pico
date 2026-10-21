#!/system/bin/sh

# The stock installer returns after the next reboot; wipe the replacement's data and force
# PackageManager to rescan so the stock package is usable immediately after that reboot.
pm clear --user 0 com.android.packageinstaller >/dev/null 2>&1
rm -rf /data/system/package_cache/*
