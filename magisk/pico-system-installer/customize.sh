#!/system/bin/sh

SKIPUNZIP=0

ui_print "- InstallerX PICO System Installer"
ui_print "- Device: $(getprop ro.product.device) / API $(getprop ro.build.version.sdk)"
ui_print "- Overlaying /system/priv-app/PackageInstaller"
ui_print "- Hiding stock /system/priv-app/PicoPackageInstaller"

if [ ! -f "$MODPATH/system/priv-app/PackageInstaller/PackageInstaller.apk" ]; then
    abort "! PackageInstaller.apk is missing; build the module first (see README.md)"
fi

if [ "$(getprop ro.build.version.sdk)" != "29" ]; then
    ui_print "! This module was tested on PICO 4 / Android 10 (API 29) only"
fi

set_perm_recursive "$MODPATH/system" 0 0 0755 0644

# Let service.sh clear the PackageManager cache once after this install/update.
rm -f "$MODPATH/.cache_cleared"

ui_print "- Reboot to activate the system installer"
