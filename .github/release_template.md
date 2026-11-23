### 多架构安装包下载与选型建议 / Multi-Architecture Downloads & Selection Guide

<table>
    <thead align="left">
        <tr>
            <th>平台 (OS)</th>
            <th>多架构直链下载 (Packages)</th>
            <th>芯片架构与格式选型建议 (Recommended Choice)</th>
        </tr>
    </thead>
    <tbody align="left">
        <tr>
            <td><strong>Android</strong></td>
            <td>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-android-arm64-v8a.apk"><img src="https://img.shields.io/badge/APK-arm64--v8a%20(推荐)-e85d88.svg?logo=android" alt="APK arm64-v8a"></a><br>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-android-armeabi-v7a.apk"><img src="https://img.shields.io/badge/APK-armeabi--v7a-f07ca0.svg?logo=android" alt="APK armeabi-v7a"></a><br>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x86__64-f59db8.svg?logo=android" alt="APK x86_64"></a>
            </td>
            <td>
                • <strong>arm64-v8a（首选）</strong>：近五年主流 64 位安卓手机与平板（骁龙 / 天玑 / 麒麟 / Tensor）<br>
                • <strong>armeabi-v7a</strong>：老旧 32 位安卓手机、Android TV 电视盒子或车机<br>
                • <strong>x86_64</strong>：电脑端 Android 模拟器或 x86 平板
            </td>
        </tr>
        <tr>
            <td><strong>Windows 10+</strong></td>
            <td>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-windows-amd64-setup.exe"><img src="https://img.shields.io/badge/Setup-x64%20(推荐)-2d7d9a.svg?logo=windows" alt="Setup x64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-windows-amd64.zip"><img src="https://img.shields.io/badge/Portable-x64%20.zip-67b7d1.svg?logo=windows" alt="Portable x64"></a><br>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-windows-arm64-setup.exe"><img src="https://img.shields.io/badge/Setup-ARM64-2d7d9a.svg?logo=windows" alt="Setup ARM64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-windows-arm64.zip"><img src="https://img.shields.io/badge/Portable-ARM64%20.zip-67b7d1.svg?logo=windows" alt="Portable ARM64"></a>
            </td>
            <td>
                • <strong>Setup x64（首选）</strong>：常规 Intel / AMD 台式机与笔记本，支持应用内自动更新<br>
                • <strong>Setup ARM64</strong>：骁龙处理器轻薄本、Surface 或 Mac Parallels 虚拟机 Windows 11<br>
                • <strong>Portable .zip</strong>：免安装绿色便携版，解压即用（可在「设置 → 系统 → 系统信息」查看系统类型）
            </td>
        </tr>
        <tr>
            <td><strong>macOS 12+</strong></td>
            <td>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-macos-arm64.dmg"><img src="https://img.shields.io/badge/DMG-Apple%20Silicon%20(arm64)-000000.svg?logo=apple" alt="DMG Apple Silicon"></a><br>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-macos-amd64.dmg"><img src="https://img.shields.io/badge/DMG-Intel%20(x64)-00A9E0.svg?logo=apple" alt="DMG Intel x64"></a>
            </td>
            <td>
                • <strong>Apple Silicon (arm64)（首选）</strong>：2020 年底及之后的 M1 / M2 / M3 / M4 芯片 Mac<br>
                • <strong>Intel (x64)</strong>：2020 年以前的旧款 Intel 处理器 Mac<br>
                • 点击左上角「 → 关于本机」可确认芯片型号；首次打开若提示无法验证，可在「隐私与安全性」点击仍要打开
            </td>
        </tr>
        <tr>
            <td><strong>Linux</strong></td>
            <td>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-amd64.deb"><img src="https://img.shields.io/badge/Deb-x64%20(推荐)-FF9966.svg?logo=debian" alt="Deb x64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-amd64.rpm"><img src="https://img.shields.io/badge/RPM-x64-F1B42F.svg?logo=redhat" alt="RPM x64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-amd64.AppImage"><img src="https://img.shields.io/badge/AppImage-x64-f84e29.svg?logo=linux" alt="AppImage x64"></a><br>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-arm64.deb"><img src="https://img.shields.io/badge/Deb-ARM64-FF9966.svg?logo=debian" alt="Deb ARM64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-arm64.rpm"><img src="https://img.shields.io/badge/RPM-ARM64-F1B42F.svg?logo=redhat" alt="RPM ARM64"></a>
                <a href="https://github.com/REPO/releases/download/vVERSION/YoukoMix-VERSION-linux-arm64.AppImage"><img src="https://img.shields.io/badge/AppImage-ARM64-f84e29.svg?logo=linux" alt="AppImage ARM64"></a>
            </td>
            <td>
                • <strong>格式选择</strong>：Ubuntu / Debian / Mint 选 <code>.deb</code>；Fedora / RHEL / Rocky 选 <code>.rpm</code>；通用免安装选 <code>.AppImage</code><br>
                • <strong>架构选择</strong>：终端执行 <code>uname -m</code>，输出 <code>x86_64</code> 选 <strong>x64</strong>，输出 <code>aarch64</code>（树莓派 / ARM 主机）选 <strong>ARM64</strong>
            </td>
        </tr>
    </tbody>
</table>
