<div align="center">

<img src="assets/images/icon.png" alt="人间之里" width="88">

# 人间之里 · YoukoMix Client

基于 Clash.Meta（`mihomo`）内核深度定制的 **人间之里** 全平台专属代理客户端。

[English](README.md) · **简体中文**

[![Release](https://img.shields.io/github/v/release/IwasakiYouko/YoukoMixClient?style=flat-square&color=e85d88&label=release)](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/IwasakiYouko/YoukoMixClient/total?style=flat-square&color=e85d88&logo=github)](https://github.com/IwasakiYouko/YoukoMixClient/releases)
[![License](https://img.shields.io/github/license/IwasakiYouko/YoukoMixClient?style=flat-square)](LICENSE)

[下载客户端](#下载) · [更新日志](CHANGELOG.md) · [从源码构建](#从源码构建)

</div>

## 特性一览

- **全平台原生同步**：完整覆盖 Android（含 Android TV）、Windows（`x64` / `ARM64`）、macOS（`Apple Silicon` / `Intel`）与 Linux（`x64` / `ARM64`）。
- **原生账号登录与订阅下发**：内置账号密码直连登录、TOTP 二步验证、浏览器验证码协同回跳（`youkomix://auth`）、套餐流量/到期/余额看板、站点公告与一键节点同步（`youkomix://sync`）。
- **专属受管订阅与系统级隔离**：仅绑定自家受管订阅，独立运行内核 `YoukoMixCore`、桌面提权服务 `YoukoMixHelperService` 与虚拟网卡 `YoukoMix`，与其它客户端互不干扰。
- **Clash.Meta 内核驱动**：支持分流规则、策略组自动测速、系统代理、TUN 透明接管、Android 分应用代理以及连接/请求/DNS 实时观测。
- **GPL-3.0 开源协议**：基于上游 [FlClash](https://github.com/chen08209/FlClash) 定制开发，无广告、代码公开透明。

## 下载

前往 [GitHub Releases](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest) 下载对应系统安装包：

| 平台 | 安装包格式 | 说明 |
| --- | --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64` APK | 绝大多数手机选择 `arm64-v8a`。 |
| Windows 10+ | 安装版 `.exe` 与便携版 `.zip`（`amd64` / `arm64`） | 安装版支持客户端内自动更新。 |
| macOS 12+ | Apple Silicon（`arm64`）与 Intel（`amd64`）DMG | 打开后将 `YoukoMix.app` 拖入应用程序目录即可。 |
| Linux | `.deb`、`.rpm`、`.AppImage`（`amd64` / `arm64`） | 使用 AppImage 或 RPM 时建议安装 `libayatana-appindicator3-1` 以显示托盘图标。 |

## 从源码构建

构建环境需准备 **Flutter 3.47.6**、**Go 1.27.1** 与 **Rust stable**。

```bash
git clone --recurse-submodules https://github.com/IwasakiYouko/YoukoMixClient.git
cd YoukoMixClient
flutter pub get

# 按目标平台打包：
dart setup.dart windows --env stable
dart setup.dart macos --env stable
dart setup.dart linux --env stable
dart setup.dart android --env stable
```

## 开源许可

本项目遵循 [GNU General Public License v3.0](LICENSE) 协议开源，致谢上游项目 [chen08209/FlClash](https://github.com/chen08209/FlClash) 与 [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)。
