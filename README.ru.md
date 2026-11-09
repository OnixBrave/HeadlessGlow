<div align="center">

<img src="docs/icon.png" width="128" alt="Значок HeadlessGlow">

# HeadlessGlow

Подсветка клавиатуры и яркость Touch Bar для MacBook Pro с чипом T2 без дисплея.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#совместимость)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#поддержать-проект)

[Скачать](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [Установка](#установка) · [Использование](#использование) · [Поддержать](#поддержать-проект)

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md) · Русский · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="Окно настроек">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="Панель в строке меню">
</picture>

</div>

## Зачем

Если снять дисплей с MacBook Pro с чипом T2, вместе с ним пропадает и датчик освещённости, который находится на плате камеры. После этого macOS перестаёт управлять подсветкой клавиатуры: клавиши яркости ничего не делают, клавиатура остаётся тёмной. HeadlessGlow управляет подсветкой напрямую через чип T2.

## Возможности

- Подсветка включается при входе в систему, восстанавливается после сна и выключается, когда засыпает дисплей
- Клавиши яркости на Touch Bar: 16 шагов, <kbd>⌥</kbd><kbd>⇧</kbd> для более мелких шагов, <kbd>⌥</kbd> открывает настройки
- Выключается после периода бездействия и снова включается при первом нажатии клавиши или движении мыши
- Сочетание клавиш для включения и выключения (по умолчанию <kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd>)
- Затемнение Touch Bar, при желании связанное с уровнем подсветки клавиатуры
- Панель в строке меню, окно настроек и индикатор на экране
- Утилита командной строки `headlessglow`
- Многоязычность

## Совместимость

MacBook Pro на Intel с чипом T2 (2018–2020), macOS 13 или новее.

| macOS | Статус |
|---|---|
| 26 | Проверено на MacBookPro16,1 (16 дюймов, 2019) |
| 15 | [Автоматические тесты запуска](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) проходят |
| 13, 14 | Собирается, не проверено |

Результаты на других моделях присылайте в [issues](https://github.com/OnixBrave/HeadlessGlow/issues).

## Установка

Из релиза: скачайте zip со [страницы релизов](https://github.com/OnixBrave/HeadlessGlow/releases/latest), откройте его и выполните:

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

Из исходного кода (нужен Xcode 26):

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # необязательно: сохраняет разрешение между обновлениями
./install.sh
```

Затем разрешите HeadlessGlow в *Системные настройки → Конфиденциальность и безопасность → Мониторинг ввода*. Это нужно только для клавиш Touch Bar, которые читаются в режиме только прослушивания.

> [!NOTE]
> Приложение не нотаризовано, поэтому `install.sh` снимает атрибут карантина с приложения, которое устанавливает. Релизы подписаны ad hoc: macOS заново запрашивает разрешение после каждого обновления.

<details>
<summary>Что устанавливается</summary>
<br>

Всё ставится в вашу домашнюю папку, без `sudo`.

| Что | Где |
|---|---|
| Приложение | `~/Applications/HeadlessGlow.app` |
| Команда | `~/.local/bin/headlessglow` |
| Служба входа | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Настройки | `defaults read io.github.onixbrave.headlessglow` |
| Журнал | `~/Library/Logs/HeadlessGlow.log` |

`setup-signing.sh` создаёт самоподписанный сертификат подписи кода в связке ключей «Вход», чтобы приложение сохраняло одну и ту же идентичность между сборками. `uninstall.sh` его удаляет.

</details>

## Использование

Используйте кнопки яркости клавиатуры на Touch Bar, значок в строке меню, сочетание клавиш или командную строку:

```text
headlessglow get                  показать состояние
headlessglow set <0-100>          задать уровень (0 выключает)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               перечитать настройки после `defaults write`
```

Если вы скрыли значок в строке меню, откройте HeadlessGlow через Spotlight, чтобы вернуться к настройкам.

## Как это работает

T2 представляет подсветку как проприетарные HID-интерфейсы устройства `05AC:8102`. HeadlessGlow отправляет им feature-репорты, те же, что использует Linux-драйвер `hid-apple`. Ничего не записывается навсегда; не нужно ни менять SIP, ни ставить расширения ядра, ни получать права администратора.

<details>
<summary>Подробности</summary>
<br>

| Интерфейс | Репорт | Содержимое |
|---|---|---|
| `0xFF00:0x0F` (клавиатура) | ID 1 | яркость `u32` (100…14660), плавный переход `u32` (мс) |
| | ID 3 | питание `u8` (0/1), плавный переход `u32` (мс) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | состояние, шаг затемнения, коэффициент яркости `u32` (0…1000) |

Коэффициент Touch Bar позволяет только затемнять её; macOS тоже перезаписывает его, когда сама затемняет Touch Bar, поэтому HeadlessGlow применяет настройку заново после каждого пробуждения. Бездействие определяется по `HIDIdleTime`, а клавиши яркости читаются через event tap в режиме только прослушивания.

</details>

## Удаление

```sh
./uninstall.sh
```

Удаляет приложение, команду, службу входа, настройки, разрешение, сертификат подписи и журналы.

<details>
<summary>Решение проблем</summary>
<br>

- `headlessglow get` показывает, что сообщает T2.
- Раздел *Status* в настройках показывает разрешение и состояние контроллеров и открывает журнал.
- Подробный журнал: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, затем `headlessglow reload`.

</details>

<details>
<summary>Разработка</summary>
<br>

- `./build.sh` собирает приложение; `./tools/package.sh` создаёт zip для релиза. Пуш тега `v*` собирает, тестирует и публикует релиз через GitHub Actions.
- `./tools/update-strings.sh` синхронизирует каталог переводов с кодом.
- `headlessglow --snapshot <папка>` сохраняет окна приложения в PNG.
- Доступ к оборудованию находится в `src/core/kbhw.c`; приложение написано на Swift и SwiftUI.

</details>

## Благодарности

- Формат репортов клавиатуры: Linux-драйвер `hid-apple` и сообщество [t2linux](https://t2linux.org).
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse) от EthanRDoesMC, за предварительную работу с CoreBrightness.

## Поддержать проект

HeadlessGlow бесплатен. Пожертвования приветствуются:

| Валюта | Сеть | Адрес |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Проверьте сеть перед отправкой. Звезда репозиторию тоже помогает.

## Отказ от ответственности

HeadlessGlow использует недокументированные аппаратные интерфейсы и проверен только на одной модели. Используйте на свой риск. Не связан с Apple.

## Лицензия

[MIT](LICENSE) © 2026 OnixBrave
