# InstallerX PICO System Installer

一个面向 **PICO 4（A8110，Android 10 / API 29）** 的 Magisk 模块，用 **InstallerX PICO** 接管系统安装器
`com.android.packageinstaller`，不需要 Shizuku。

- 已验证设备：PICO 4 `PA8110MGGB070328G`（A8110，Android 10）
- 已验证固件中的 stock 安装器：`com.android.packageinstaller`，versionCode `100103003`
- 本模块安装的 InstallerX PICO：versionCode `100103004`
- 安装流程实测：通过 PICO 文件管理器选择 APK → InstallerX 解析 → Root / 系统安装器权限安装 → `InstallSuccess`

## 它做了什么

1. 将 InstallerX PICO 的 APK 以 **systemless overlay** 放到：
   `system/priv-app/PackageInstaller/PackageInstaller.apk`
2. 用空的 `.replace` 隐藏 stock 的 `system/priv-app/PicoPackageInstaller`。
   在 PICO 上仅提高 versionCode 并不够：PackageManager 仍可能先扫到 stock 并跳过重复包，
   隐藏 stock 后 InstallerX 才会稳定成为实际生效的 `com.android.packageinstaller`。
3. 隐藏 `PackageInstaller/lib` 与 `PackageInstaller/oat` 的 stock 内容，避免加载到与旧 APK 匹配的
   native lib / oat。
4. 首次开机清一次 `/data/system/package_cache`，让 PackageManager 重新扫描替换后的系统包。
5. 提供 `action.sh`：在 Magisk 模块页面点动作按钮可直接打开 InstallerX PICO。

详细的原理、APK 侧改动和验证命令见
[docs/pico-system-installer.md](../../docs/pico-system-installer.md)。

## 安装

前置条件：

- PICO 4（A8110）Android 10
- 已解锁并安装 Magisk（Root）
- 建议先确认 Magisk 安全模式 / 禁用模块的方式可用

步骤：

1. 下载 `InstallerX-PICO-system-*.zip`（或按下面的“构建”自行生成）。
2. Magisk → 模块 → 从本地安装 → 选择 zip。
3. 重启头显。
4. 打开 PICO 文件管理器，点一个 APK 安装，确认弹出的安装界面是 InstallerX PICO。

也可以命令行安装：

```bash
adb push InstallerX-PICO-system-*.zip /sdcard/Download/
adb shell su -c "magisk --install-module /sdcard/Download/InstallerX-PICO-system-*.zip"
adb reboot
```

## 验证

```bash
# 1. 版本号应为 100103004（stock 为 100103003）
adb shell dumpsys package com.android.packageinstaller | grep versionCode

# 2. 实际 APK 路径应来自 overlay 的 PackageInstaller 目录
adb shell pm path com.android.packageinstaller

# 3. 打开安装界面后，SystemExt 日志应显示 near/dock 与 1127x752@200
adb logcat -d | grep -E "add VD cache.*packageinstaller"

# 4. 安装成功日志
adb logcat -d | grep -E "InstallSuccess|InstallFailed"
```

预期看到的关键日志：

```text
SYSTEM_EXT: add VD cache : AppRecord ...[size (1127, 752), type: 2002, ... density: 200]...
```

`type: 2002` 是 PICO 的近场 dock 窗口。InstallerX PICO 的 `InstallerActivity` 声明了
`pico.vr.position=near` / `pvr.2dtovr.mode=6`，**不需要 resfix 也会得到这个近场窗口**。
resfix 仅用于按应用微调分辨率/DPI，不是本模块的前置条件。

## 回滚

优先方式：

1. Magisk → 模块 → 移除 `InstallerX PICO System Installer`
2. 重启

`uninstall.sh` 会清理 InstallerX 的数据和 PackageManager 缓存；重启后 overlay 消失，stock
`PicoPackageInstaller` 恢复。

已实测回滚（A8110）：移除模块并重启后，`com.android.packageinstaller` 恢复为
`versionCode=100103003`，`pm path` 指向 `/system/priv-app/PicoPackageInstaller/PicoPackageInstaller.apk`；
重新刷入模块后恢复为 `100103004` / `/system/priv-app/PackageInstaller/PackageInstaller.apk`。

> 请使用 Magisk 的“移除”操作，而不要只“禁用”模块：`uninstall.sh` 负责清 package cache，
> 禁用不会执行它。若只禁用，重启后如遇安装器异常，可手动清 `/data/system/package_cache/*` 或重新
> 刷入/移除模块。

如果改坏了安装流程、无法正常进入系统：使用 Magisk 安全模式（开机时按住音量键等，具体方式取决于
Magisk 版本），或通过 adb 在可连接时执行 `magisk --remove-modules` 后重启。不要在无法恢复的环境里
测试这个模块。

## 构建

环境要求：JDK 25、Android SDK、Gradle Wrapper 可用。Miuix snapshot 走 GitHub Packages，
本地构建需要在 `~/.gradle/gradle.properties` 配置带 `read:packages` 权限的 `gpr.user` /
`gpr.key`；仓库的 `PICO System Installer Module` workflow 使用 `GITHUB_TOKEN` 自动完成。
构建会产出 debug 签名的 APK（系统安装器不依赖签名与 stock 一致；stock 已被 `.replace` 隐藏）。

```bash
# 在仓库根目录执行
bash magisk/pico-system-installer/build.sh
```

脚本会：

1. 读取 `module.prop` 的 `version` / `versionCode`；
2. 执行 `:app:assembleUnstableDebug -PAPP_ID=com.android.packageinstaller -PVERSION_CODE=<module.prop>`；
3. 把 APK 复制到 `system/priv-app/PackageInstaller/PackageInstaller.apk`；
4. 打包为 `magisk/pico-system-installer/dist/InstallerX-PICO-system-<version>-<versionCode>.zip`。

可用环境变量覆盖：

```bash
VERSION_CODE=100103005 bash magisk/pico-system-installer/build.sh
APP_ID=com.android.packageinstaller VARIANT=Unstable bash magisk/pico-system-installer/build.sh
```

> `VERSION_CODE` 必须大于当前固件 stock 安装器的 versionCode；否则 PackageManager 可能继续使用
> stock。升级固件后如果 stock versionCode 变大，需要同步提高本模块的 `module.prop` versionCode。

## 目录结构

```text
magisk/pico-system-installer/
├── module.prop
├── customize.sh
├── service.sh
├── action.sh
├── uninstall.sh
├── build.sh
├── META-INF/com/google/android/update-binary
├── META-INF/com/google/android/updater-script
└── system/priv-app/
    ├── PackageInstaller/
    │   ├── lib/.replace
    │   └── oat/.replace
    └── PicoPackageInstaller/.replace
```

`PackageInstaller.apk` 由 `build.sh` 生成，已加入 `.gitignore`，不随源码提交。
`META-INF/com/google/android/update-binary` 来自 Magisk 模块模板（GPL-3.0）。

## 已知限制

- 只在 PICO 4 A8110 / Android 10 上验证过；其他 PICO 型号/固件的 stock 安装器路径和 versionCode 可能不同。
- 依赖 `com.android.packageinstaller` 这个系统包名与 `/system/priv-app/PackageInstaller` 路径；
  如果 ROM 使用别的路径，需要调整 overlay 或 `.replace`。
- 需要 Magisk；不适用于无 Root 设备。
- 默认使用 debug 签名构建；如果自己重建模块，签名变化可能需要在切换构建时清理
  `com.android.packageinstaller` 数据。发布时建议由维护者用固定签名构建。
- 卸载模块后必须重启，stock 安装器才会恢复。

## English summary

This Magisk module makes **InstallerX PICO** the active system package installer on **PICO 4
(A8110, Android 10)** without Shizuku. It overlays an APK at
`/system/priv-app/PackageInstaller/PackageInstaller.apk` with applicationId
`com.android.packageinstaller` and a versionCode higher than the stock one, hides the stock
`PicoPackageInstaller` via `.replace`, and clears the PackageManager cache once after installation.
The installer activity declares PICO near-field metadata, so it opens as a near/dock card
(1127×752 @200) without resfix. Flash the zip in Magisk, reboot, and verify with the adb commands
above. Uninstall the module and reboot to restore the stock installer. GPL-3.0; built on
[InstallerX Revived](https://github.com/wxxsfxyzm/InstallerX-Revived).
