#!/system/bin/sh

# Magisk module action button: open the InstallerX PICO launcher / settings entry point.
am start -n com.android.packageinstaller/com.rosan.installer.ui.activity.LauncherAlias >/dev/null 2>&1
