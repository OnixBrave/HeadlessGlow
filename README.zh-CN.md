<div align="center">

<img src="docs/icon.png" width="128" alt="HeadlessGlow 图标">

# HeadlessGlow

为没有屏幕的 T2 MacBook Pro 控制键盘背光和 Touch Bar 亮度。

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#兼容性)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#支持项目)

[下载](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [安装](#安装) · [使用](#使用) · [支持](#支持项目)

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · 简体中文 · [日本語](README.ja.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="设置窗口">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="菜单栏面板">
</picture>

</div>

## 为什么需要

拆下 T2 MacBook Pro 的屏幕时，位于摄像头板上的环境光传感器也会一起被拆下。此后 macOS 不再控制键盘背光：亮度键不起作用，键盘一直不亮。HeadlessGlow 直接通过 T2 芯片控制背光。

## 功能

- 登录时打开背光，睡眠唤醒后恢复，显示器睡眠时关闭
- Touch Bar 亮度键：16 级，<kbd>⌥</kbd><kbd>⇧</kbd> 微调，<kbd>⌥</kbd> 打开设置
- 闲置一段时间后关闭，按下按键或移动鼠标时重新点亮
- 开关快捷键（默认 <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd>）
- Touch Bar 调暗，可与键盘亮度联动
- 菜单栏面板、设置窗口和屏幕指示器
- 命令行工具 `headlessglow`
- 界面提供英语和法语

## 兼容性

搭载 T2 芯片的 Intel MacBook Pro（2018–2020），macOS 13 或更高版本。

| macOS | 状态 |
|---|---|
| 26 | 已在 MacBookPro16,1（16 英寸，2019）上测试 |
| 15 | [自动启动测试](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)通过 |
| 13, 14 | 可编译，未测试 |

欢迎在 [issues](https://github.com/OnixBrave/HeadlessGlow/issues) 中反馈其他机型的结果。

## 安装

从 release 安装：在 [Releases 页面](https://github.com/OnixBrave/HeadlessGlow/releases/latest)下载 zip，打开后运行：

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

从源码安装（需要 Xcode 26）：

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # 可选：更新后保留权限
./install.sh
```

然后在 *系统设置 → 隐私与安全性 → 输入监控* 中允许 HeadlessGlow。只有 Touch Bar 按键需要此权限，且只以监听模式读取。

> [!NOTE]
> 本 app 未经公证，因此 `install.sh` 会移除所安装 app 的隔离属性。Release 版本使用 ad hoc 签名：每次更新后 macOS 都会再次请求权限。

<details>
<summary>安装了哪些内容</summary>
<br>

所有内容都放在你的个人文件夹中，无需 `sudo`。

| 内容 | 位置 |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| 命令 | `~/.local/bin/headlessglow` |
| 登录服务 | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| 设置 | `defaults read io.github.onixbrave.headlessglow` |
| 日志 | `~/Library/Logs/HeadlessGlow.log` |

`setup-signing.sh` 会在登录钥匙串中创建一个自签名的代码签名证书，使 app 在每次编译后保持相同的身份。`uninstall.sh` 会将其删除。

</details>

## 使用

使用 Touch Bar 上的键盘亮度控制、菜单栏图标、快捷键或命令行：

```text
headlessglow get                  显示状态
headlessglow set <0-100>          设置亮度（0 为关闭）
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               在 `defaults write` 之后重新读取设置
```

如果隐藏了菜单栏图标，可以通过 Spotlight 打开 HeadlessGlow 来进入设置。

## 工作原理

T2 将背光作为设备 `05AC:8102` 的厂商自定义 HID 接口暴露出来。HeadlessGlow 向这些接口发送 feature report，与 Linux 驱动 `hid-apple` 使用的相同。不会永久写入任何内容，也不需要修改 SIP、安装内核扩展或获取管理员权限。

<details>
<summary>详细信息</summary>
<br>

| 接口 | Report | 内容 |
|---|---|---|
| `0xFF00:0x0F`（键盘） | ID 1 | 亮度 `u32`（100…14660），渐变 `u32`（毫秒） |
| | ID 3 | 电源 `u8`（0/1），渐变 `u32`（毫秒） |
| `0xFF12:0x01`（Touch Bar） | ID 1 | 状态、调暗级别、亮度系数 `u32`（0…1000） |

Touch Bar 的亮度系数只能用来调暗；macOS 自己调暗 Touch Bar 时也会改写该值，因此 HeadlessGlow 会在每次唤醒后重新应用设置。闲置检测使用 `HIDIdleTime`，亮度键通过只监听的 event tap 读取。

</details>

## 卸载

```sh
./uninstall.sh
```

移除 app、命令、登录服务、设置、权限、签名证书和日志。

<details>
<summary>故障排除</summary>
<br>

- `headlessglow get` 显示 T2 报告的状态。
- 设置中的 *Status* 部分显示权限和控制器状态，并可打开日志。
- 详细日志：`defaults write io.github.onixbrave.headlessglow debugLog -bool YES`，然后运行 `headlessglow reload`。

</details>

<details>
<summary>开发</summary>
<br>

- `./build.sh` 编译 app；`./tools/package.sh` 生成 release 用的 zip。推送 `v*` 标签后，GitHub Actions 会编译、测试并发布 release。
- `./tools/update-strings.sh` 将翻译目录与代码同步。
- `headlessglow --snapshot <文件夹>` 将 app 的窗口保存为 PNG。
- 硬件访问代码位于 `src/core/kbhw.c`；app 使用 Swift 和 SwiftUI 编写。

</details>

## 致谢

- 键盘 report 格式：Linux 驱动 `hid-apple` 和 [t2linux](https://t2linux.org) 社区。
- EthanRDoesMC 的 [KBPulse](https://github.com/EthanRDoesMC/KBPulse)，感谢其在 CoreBrightness 方面的前期工作。

## 支持项目

HeadlessGlow 免费使用。欢迎捐赠：

| 币种 | 网络 | 地址 |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

转账前请确认网络。给仓库点个 Star 也是一种支持。

## 免责声明

HeadlessGlow 使用未公开的硬件接口，且只在一种机型上测试过。使用风险自负。与 Apple 无关。

## 许可证

[MIT](LICENSE) © 2026 OnixBrave
