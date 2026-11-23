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

## Download & Architecture Guide

Download the latest multi-architecture installer from [GitHub Releases](https://github.com/IwasakiYouko/YoukoMixClient/releases/latest) (or from the user dashboard mirror):

| Platform | Multi-Arch Packages | Architecture & Format Recommendation |
| --- | --- | --- |
| **Android** | `arm64-v8a` (Recommended)<br>`armeabi-v7a`<br>`x86_64` APK | • **`arm64-v8a` (Recommended)**: Almost all modern 64-bit phones & tablets (Snapdragon / Dimensity / Tensor / Kirin)<br>• **`armeabi-v7a`**: Legacy 32-bit Android phones, Android TV boxes, or head units<br>• **`x86_64`**: Desktop Android emulators or x86 tablets |
| **Windows 10+** | `windows-amd64-setup.exe` (Recommended)<br>`windows-arm64-setup.exe`<br>`windows-amd64.zip` / `windows-arm64.zip` | • **`amd64-setup.exe` (Recommended)**: Standard Intel / AMD PCs, supports automatic in-app updates<br>• **`arm64-setup.exe`**: Snapdragon laptops, Surface Pro ARM, or Windows 11 on Mac Parallels VM<br>• **Portable `.zip`**: No-install archive (`Settings → System → About → System type` shows x64 vs ARM64) |
| **macOS 12+** | `macos-arm64.dmg` (Apple Silicon)<br>`macos-amd64.dmg` (Intel) | • **`macos-arm64.dmg` (Recommended)**: Macs with Apple M1 / M2 / M3 / M4 chips (late 2020+)<br>• **`macos-amd64.dmg`**: Pre-2020 Intel Macs (check via ` → About This Mac`) |
| **Linux** | `amd64` / `arm64` `.deb`<br>`amd64` / `arm64` `.rpm`<br>`amd64` / `arm64` `.AppImage` | • **Format**: `.deb` for Ubuntu / Debian / Mint; `.rpm` for Fedora / RHEL / Rocky; `.AppImage` for universal portable run (`libayatana-appindicator3-1` recommended for tray icon)<br>• **Architecture**: Run `uname -m` — choose `amd64` for `x86_64`, or `arm64` for `aarch64` (Raspberry Pi / ARM hosts) |

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
