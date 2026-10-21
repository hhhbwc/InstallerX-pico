# InstallerX PICO

面向 **PICO 4（A8110，Android 10）** 的 [InstallerX Revived](https://github.com/wxxsfxyzm/InstallerX-Revived)
适配分支。目标是在不依赖 Shizuku 的前提下，让 InstallerX 接管 PICO 的系统安装流程。

## 本分支增加了什么

- **系统安装器 Magisk 模块**：以 `com.android.packageinstaller` 身份覆盖安装器 APK，并隐藏 stock
  `PicoPackageInstaller`。刷入后从文件管理器点 APK 安装会直接进入 InstallerX。
- **默认 Root**：普通安装使用 Magisk Root；作为系统安装器运行时使用系统自身权限（`None`）。
- **PICO 文件管理器兼容**：优先读取 Intent extra `FilePath`，避开目录型 MediaStore URI 导致的
  `EISDIR` / 权限错误。
- **PICO 桌面入口**：提供“选择 APK 安装”的 Launcher 页面和设置入口。
- **近场 dock 安装卡片**：`InstallerActivity` 声明 PICO near 元数据，安装界面以
  `1127×752 @200` 的近场卡片显示（不需要 resfix）；卡片外透明，不占满整块面板。
- **Android 10 存储兼容**：`targetSdk 29` + `requestLegacyExternalStorage`。

## 快速开始

1. 从 Release 下载 `InstallerX-PICO-system-*.zip`，或按下方说明自行构建。
2. Magisk → 模块 → 从本地安装 → 选择 zip → 重启。
3. 在 PICO 文件管理器里点一个 APK，确认出现 InstallerX PICO 卡片。

详细安装、验证、回滚和构建说明：
[magisk/pico-system-installer/README.md](magisk/pico-system-installer/README.md)

替换系统安装器的原理、包名/路径/versionCode、`.replace` 与验证日志：
[docs/pico-system-installer.md](docs/pico-system-installer.md)

> **风险提示**：这是系统安装器替换操作，仅验证于 PICO 4 A8110 / Android 10。刷入前请确认
> Magisk 安全模式或禁用模块的方式可用。卸载模块后需要重启才会恢复 stock 安装器。

## 构建

需要 JDK 25、Android SDK 和可用的 Gradle Wrapper。

```bash
# 普通 APK
./gradlew assembleUnstableDebug

# 系统安装器 APK（包名必须是 com.android.packageinstaller）
./gradlew assembleUnstableDebug \
  -PAPP_ID=com.android.packageinstaller \
  -PVERSION_CODE=100103004

# 一键构建并打包 Magisk 模块
bash magisk/pico-system-installer/build.sh
```

模块输出目录：`magisk/pico-system-installer/dist/`。

## 文档

- [PICO 系统安装器技术说明](docs/pico-system-installer.md)
- [上游功能文档（中文）](docs/README_CN.md)
- [Upstream documentation (English)](docs/README.md)

## 许可证

本项目与上游一致，基于 [GNU General Public License v3](LICENSE) 开源。
InstallerX Revived 的版权归 [iamr0s](https://github.com/iamr0s) 与
[InstallerX Revived Contributors](https://github.com/wxxsfxyzm/InstallerX-Revived/graphs/contributors)
所有；PICO 适配与 Magisk 模块由本 fork 的贡献者维护。

## English summary

This is a PICO 4 (A8110, Android 10) fork of InstallerX Revived. It adds a Magisk system-installer
module that overlays InstallerX as `com.android.packageinstaller` and hides the stock
`PicoPackageInstaller`, Root-by-default authorization without Shizuku, PICO FileManager `FilePath`
handling, and a near-field dock installer card (`1127×752 @200`). See
[docs/pico-system-installer.md](docs/pico-system-installer.md) for the full method and
[magisk/pico-system-installer](magisk/pico-system-installer/README.md) for installation. Tested only
on PICO 4 / Android 10; GPL-3.0.
