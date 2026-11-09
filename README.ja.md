<div align="center">

<img src="docs/icon.png" width="128" alt="HeadlessGlow のアイコン">

# HeadlessGlow

ディスプレイを外した T2 搭載 MacBook Pro で、キーボードバックライトと Touch Bar の明るさを調整します。

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#対応環境)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#支援)

[ダウンロード](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [インストール](#インストール) · [使い方](#使い方) · [支援](#支援)

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md) · [Русский](README.ru.md) · [简体中文](README.zh-CN.md) · 日本語

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="設定ウインドウ">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="メニューバーのパネル">
</picture>

</div>

## 背景

T2 搭載 MacBook Pro のディスプレイを外すと、カメラ基板にある環境光センサーも一緒に外れます。すると macOS はキーボードバックライトを制御しなくなり、輝度キーは効かず、キーボードは暗いままになります。HeadlessGlow は T2 チップを通じてバックライトを直接制御します。

## 機能

- ログイン時にバックライトを点灯、スリープ解除後に復元、ディスプレイのスリープ時に消灯
- Touch Bar の輝度キー：16 段階、<kbd>⌥</kbd><kbd>⇧</kbd> で細かく調整、<kbd>⌥</kbd> で設定を開く
- 一定時間操作がないと消灯し、キー入力やマウス操作で再点灯
- オン／オフのショートカット（デフォルトは <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd>）
- Touch Bar の減光（キーボードの明るさとの連動も可能）
- メニューバーのパネル、設定ウインドウ、画面上のインジケータ
- コマンドラインツール `headlessglow`
- 英語とフランス語の UI

## 対応環境

T2 チップ搭載の Intel MacBook Pro（2018〜2020 年）、macOS 13 以降。

| macOS | 状況 |
|---|---|
| 26 | MacBookPro16,1（16 インチ、2019）でテスト済み |
| 15 | [自動起動テスト](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)に合格 |
| 13, 14 | ビルド可能、未テスト |

他の機種での結果は [issues](https://github.com/OnixBrave/HeadlessGlow/issues) でお知らせください。

## インストール

リリースから：[リリースページ](https://github.com/OnixBrave/HeadlessGlow/releases/latest)から zip をダウンロードして開き、次を実行します。

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

ソースから（Xcode 26 が必要）：

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # 任意：アップデート後も許可を維持
./install.sh
```

その後、*システム設定 → プライバシーとセキュリティ → 入力監視* で HeadlessGlow を許可します。これは Touch Bar のキーにだけ必要で、キー入力は読み取り専用で監視されます。

> [!NOTE]
> アプリは公証されていないため、`install.sh` はインストールするアプリの検疫属性を削除します。リリース版は ad hoc 署名のため、アップデートのたびに macOS が許可を求め直します。

<details>
<summary>インストールされるもの</summary>
<br>

すべてホームフォルダに入り、`sudo` は不要です。

| 項目 | 場所 |
|---|---|
| アプリ | `~/Applications/HeadlessGlow.app` |
| コマンド | `~/.local/bin/headlessglow` |
| ログインサービス | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| 設定 | `defaults read io.github.onixbrave.headlessglow` |
| ログ | `~/Library/Logs/HeadlessGlow.log` |

`setup-signing.sh` はログインキーチェーンに自己署名のコード署名証明書を作成し、ビルドが変わってもアプリが同じ ID を保てるようにします。`uninstall.sh` で削除されます。

</details>

## 使い方

Touch Bar のキーボード輝度コントロール、メニューバーのアイコン、ショートカット、またはコマンドラインを使います。

```text
headlessglow get                  状態を表示
headlessglow set <0-100>          明るさを設定（0 で消灯）
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               `defaults write` の後に設定を再読み込み
```

メニューバーのアイコンを非表示にした場合は、Spotlight から HeadlessGlow を開くと設定に戻れます。

## 仕組み

T2 はバックライトを、デバイス `05AC:8102` のベンダー独自 HID インターフェースとして公開しています。HeadlessGlow はそこへ、Linux の `hid-apple` ドライバと同じ feature report を送ります。永続的に書き込まれるものはなく、SIP の変更、カーネル拡張、管理者権限はいずれも不要です。

<details>
<summary>詳細</summary>
<br>

| インターフェース | Report | 内容 |
|---|---|---|
| `0xFF00:0x0F`（キーボード） | ID 1 | 明るさ `u32`（100…14660）、フェード `u32`（ms） |
| | ID 3 | 電源 `u8`（0/1）、フェード `u32`（ms） |
| `0xFF12:0x01`（Touch Bar） | ID 1 | 状態、減光ステップ、明るさ係数 `u32`（0…1000） |

Touch Bar の係数は減光にしか使えません。macOS も自分で Touch Bar を減光するときにこの値を書き換えるため、HeadlessGlow はスリープ解除のたびに設定を適用し直します。無操作の検出には `HIDIdleTime` を使い、輝度キーは読み取り専用のイベントタップで取得します。

</details>

## アンインストール

```sh
./uninstall.sh
```

アプリ、コマンド、ログインサービス、設定、許可、署名証明書、ログを削除します。

<details>
<summary>トラブルシューティング</summary>
<br>

- `headlessglow get` で T2 が返す状態を表示します。
- 設定の *Status* セクションで許可とコントローラの状態を確認でき、ログも開けます。
- 詳細ログ：`defaults write io.github.onixbrave.headlessglow debugLog -bool YES` の後に `headlessglow reload`。

</details>

<details>
<summary>開発</summary>
<br>

- `./build.sh` でアプリをビルドし、`./tools/package.sh` でリリース用の zip を作成します。`v*` タグを push すると、GitHub Actions がビルド、テスト、リリースの公開を行います。
- `./tools/update-strings.sh` で翻訳カタログをコードと同期します。
- `headlessglow --snapshot <フォルダ>` でアプリのウインドウを PNG に保存します。
- ハードウェアへのアクセスは `src/core/kbhw.c` にあり、アプリは Swift と SwiftUI で書かれています。

</details>

## クレジット

- キーボードの report 形式：Linux の `hid-apple` ドライバと [t2linux](https://t2linux.org) コミュニティ。
- EthanRDoesMC による [KBPulse](https://github.com/EthanRDoesMC/KBPulse)（CoreBrightness に関する先行調査）。

## 支援

HeadlessGlow は無料です。寄付を歓迎します。

| 通貨 | ネットワーク | アドレス |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

送金前にネットワークを確認してください。リポジトリへのスターも支援になります。

## 免責事項

HeadlessGlow は非公開のハードウェアインターフェースを使用しており、1 機種でしかテストされていません。自己責任でご利用ください。Apple とは関係ありません。

## ライセンス

[MIT](LICENSE) © 2026 OnixBrave
