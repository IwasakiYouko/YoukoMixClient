<div align="center">

<img src="assets/images/icon.png" alt="人间之里" width="88">

# 人间之里 · YoukoMix Client

A cross-platform dedicated proxy client for **人间之里 (YoukoMix)**, built on Clash.Meta (`mihomo`).

**English** · [简体中文](README_zh_CN.md)

[![Release](https://img.shields.io/github/v/release/IwasakiYouko/YoukoMixClient?style=flat-square&color=e85d88&label=release)](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/IwasakiYouko/YoukoMixClient/total?style=flat-square&color=e85d88&logo=github)](https://github.com/IwasakiYouko/YoukoMixClient/releases)
[![License](https://img.shields.io/github/license/IwasakiYouko/YoukoMixClient?style=flat-square)](LICENSE)

[Download](#download) · [Changelog](CHANGELOG.md) · [Build from source](#build-from-source)

</div>

## Features

- **Unified multi-platform experience**: Android (`arm64-v8a`, `armeabi-v7a`, `x86_64`), Windows (`x64`, `ARM64`), macOS (`Apple Silicon`, `Intel`), and Linux (`x64`, `ARM64`).
- **Native account & subscription sync**: Built-in email/password sign-in, TOTP MFA verification, browser handoff (`youkomix://auth`), traffic & plan dashboard, announcements, and one-click node sync (`youkomix://sync`).
- **Exclusive managed subscription**: Automatically activates and syncs your bound account subscription while isolating runtime binaries (`YoukoMixCore`, `YoukoMixHelperService`) and TUN adapter (`YoukoMix`).
- **Powered by Clash.Meta (`mihomo`)**: Rule-based routing, latency testing, system proxy, TUN mode, per-app proxy on Android, and live connection/request/DNS diagnostics.
- **Open source under GPL-3.0**: Customized from upstream [FlClash](https://github.com/chen08209/FlClash).

## Download

Download the latest installer for your device from [GitHub Releases](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest):

| Platform | Packages | Notes |
| --- | --- | --- |
| Android | APK for `arm64-v8a`, `armeabi-v7a`, and `x86_64` | Most modern Android devices use `arm64-v8a`. |
| Windows 10+ | Setup installer (`.exe`) and portable `.zip` (`amd64`, `arm64`) | Installer supports automatic in-app updates. |
| macOS 12+ | DMG for Apple Silicon (`arm64`) and Intel (`amd64`) | Drag `YoukoMix.app` into `/Applications`. |
| Linux | `.deb`, `.rpm`, and `.AppImage` (`amd64`, `arm64`) | Install `libayatana-appindicator3-1` for tray icon support on AppImage/RPM. |

## Build from source

Requires **Flutter 3.47.6**, **Go 1.27.1**, and **Rust stable**.

```bash
git clone --recurse-submodules https://github.com/IwasakiYouko/YoukoMixClient.git
cd YoukoMixClient
flutter pub get

# Package for current desktop host or Android:
dart setup.dart windows --env stable
dart setup.dart macos --env stable
dart setup.dart linux --env stable
dart setup.dart android --env stable
```

## License

Licensed under the [GNU General Public License v3.0](LICENSE). Based on [chen08209/FlClash](https://github.com/chen08209/FlClash) and [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo).
