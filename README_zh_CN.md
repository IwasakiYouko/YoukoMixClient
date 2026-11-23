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

## 下载与架构选型建议

前往 [GitHub Releases 最新版本](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest)（或登录站点用户中心走面板直连镜像）按设备架构下载安装包：

| 平台 | 多架构安装包 | 推荐选型建议与查看方法 |
| --- | --- | --- |
| **Android** | `arm64-v8a`（推荐）<br>`armeabi-v7a`<br>`x86_64` APK | • **arm64-v8a（首选）**：近五年主流 64 位安卓手机与平板（骁龙 / 天玑 / 麒麟 / Tensor）<br>• **armeabi-v7a**：老旧 32 位安卓手机、Android TV 电视盒子或车机<br>• **x86_64**：电脑端 Android 模拟器或 x86 平板 |
| **Windows 10+** | `windows-amd64-setup.exe`（推荐）<br>`windows-arm64-setup.exe`<br>`windows-amd64.zip` / `windows-arm64.zip` | • **x64 安装版 `amd64-setup.exe`（首选）**：常规 Intel / AMD 台式机与笔记本，支持应用内自动更新<br>• **ARM64 安装版 `arm64-setup.exe`**：高通骁龙轻薄本、Surface 或 Mac Parallels 虚拟机 Windows 11<br>• **便携版 `.zip`**：免安装绿色包，解压即用（可在「设置 → 系统 → 系统信息 → 系统类型」确认架构） |
| **macOS 12+** | `macos-arm64.dmg`（Apple Silicon 推荐）<br>`macos-amd64.dmg`（Intel） | • **Apple Silicon `arm64.dmg`（首选）**：2020 年底及之后的 M1 / M2 / M3 / M4 芯片 Mac<br>• **Intel `amd64.dmg`**：2020 年以前的旧款 Intel 处理器 Mac<br>• 点击屏幕左上角「 → 关于本机」可查看芯片类型；首次打开若被拦截可在「隐私与安全性」点击仍要打开 |
| **Linux** | `amd64` / `arm64` `.deb`<br>`amd64` / `arm64` `.rpm`<br>`amd64` / `arm64` `.AppImage` | • **包格式**：Ubuntu / Debian / Mint 选 `.deb`；Fedora / RHEL / Rocky / openSUSE 选 `.rpm`；跨发行版免安装选 `.AppImage`（赋予执行权限即可，托盘图标建议安装 `libayatana-appindicator3-1`）<br>• **CPU 架构**：终端运行 `uname -m`，显示 `x86_64` 选 `amd64`，显示 `aarch64`（树莓派 / ARM 主机）选 `arm64` |

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
