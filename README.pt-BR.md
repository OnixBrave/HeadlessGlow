<div align="center">

<img src="docs/icon.png" width="128" alt="Ícone do HeadlessGlow">

# HeadlessGlow

Iluminação do teclado e brilho da Touch Bar para MacBook Pro com chip T2 sem tela.

[![Build](https://img.shields.io/github/actions/workflow/status/OnixBrave/HeadlessGlow/build.yml?branch=main&style=flat-square&logo=githubactions&logoColor=white&label=build)](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/OnixBrave/HeadlessGlow?style=flat-square&color=2ea44f&label=release)](https://github.com/OnixBrave/HeadlessGlow/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?style=flat-square&logo=apple&logoColor=white)](#compatibilidade)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/OnixBrave/HeadlessGlow?style=flat-square&logo=github&label=stars&color=e3b341)](https://github.com/OnixBrave/HeadlessGlow/stargazers)
[![Donate](https://img.shields.io/badge/donate-crypto-f7931a?style=flat-square&logo=bitcoin&logoColor=white)](#apoie-o-projeto)

[Baixar](https://github.com/OnixBrave/HeadlessGlow/releases/latest) · [Instalação](#instalação) · [Uso](#uso) · [Apoiar](#apoie-o-projeto)

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Italiano](README.it.md) · Português · [Русский](README.ru.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md)

<br>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/settings-dark.png">
  <img src="docs/settings-light.png" width="420" alt="Janela de ajustes">
</picture>
&nbsp;&nbsp;
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/menu-dark.png">
  <img src="docs/menu-light.png" width="300" alt="Painel da barra de menus">
</picture>

</div>

## Por quê

Remover a tela de um MacBook Pro com chip T2 também remove o sensor de luz ambiente, que fica na placa da câmera. O macOS então deixa de controlar a iluminação do teclado: as teclas de brilho não fazem nada e o teclado fica apagado. O HeadlessGlow controla a iluminação diretamente pelo chip T2.

## Recursos

- Iluminação acesa ao iniciar a sessão, restaurada após o repouso e apagada quando a tela entra em repouso
- Teclas de brilho da Touch Bar: 16 níveis, <kbd>⌥</kbd><kbd>⇧</kbd> para ajustes mais finos, <kbd>⌥</kbd> para abrir os ajustes
- Apaga após um período de inatividade e acende de novo ao pressionar uma tecla ou mover o mouse
- Atalho para ligar e desligar (<kbd>⌃</kbd><kbd>⌥</kbd><kbd>K</kbd> por padrão)
- Escurecimento da Touch Bar, opcionalmente vinculado ao nível do teclado
- Painel na barra de menus, janela de ajustes e indicador na tela
- Ferramenta de linha de comando `headlessglow`
- Multilíngue

## Compatibilidade

MacBook Pro Intel com chip T2 (2018–2020), macOS 13 ou posterior.

| macOS | Status |
|---|---|
| 26 | Testado em um MacBookPro16,1 (16 polegadas, 2019) |
| 15 | [Testes automáticos de inicialização](https://github.com/OnixBrave/HeadlessGlow/actions/workflows/build.yml) aprovados |
| 13, 14 | Compila, não testado |

Resultados em outros modelos são bem-vindos nas [issues](https://github.com/OnixBrave/HeadlessGlow/issues).

## Instalação

A partir de uma release: baixe o zip na [página de releases](https://github.com/OnixBrave/HeadlessGlow/releases/latest), abra-o e execute:

```sh
cd ~/Downloads/HeadlessGlow-<version> && ./install.sh
```

A partir do código-fonte (requer Xcode 26):

```sh
git clone https://github.com/OnixBrave/HeadlessGlow.git && cd HeadlessGlow
./tools/setup-signing.sh   # opcional: mantém a permissão entre atualizações
./install.sh
```

Depois, permita o HeadlessGlow em *Ajustes do Sistema → Privacidade e Segurança → Monitoração de Entrada*. Isso só é necessário para as teclas da Touch Bar, que são lidas em modo somente escuta.

> [!NOTE]
> O app não é notarizado, então o `install.sh` remove o atributo de quarentena do app que instala. As releases são assinadas ad hoc: o macOS pede a permissão de novo após cada atualização.

<details>
<summary>O que é instalado</summary>
<br>

Tudo fica na sua pasta pessoal, sem `sudo`.

| O quê | Onde |
|---|---|
| App | `~/Applications/HeadlessGlow.app` |
| Comando | `~/.local/bin/headlessglow` |
| Serviço de início de sessão | `~/Library/LaunchAgents/io.github.onixbrave.headlessglow.plist` |
| Ajustes | `defaults read io.github.onixbrave.headlessglow` |
| Log | `~/Library/Logs/HeadlessGlow.log` |

O `setup-signing.sh` cria um certificado de assinatura de código autoassinado no seu chaveiro de início de sessão, para que o app mantenha a mesma identidade entre compilações. O `uninstall.sh` o remove.

</details>

## Uso

Use os controles de brilho do teclado na Touch Bar, o ícone da barra de menus, o atalho ou a linha de comando:

```text
headlessglow get                  mostra o status
headlessglow set <0-100>          define o nível (0 apaga)
headlessglow on | off | toggle
headlessglow touchbar <10-100 | link | unlink>
headlessglow reload               relê os ajustes após um `defaults write`
```

Se você ocultar o ícone da barra de menus, abra o HeadlessGlow pelo Spotlight para voltar aos ajustes.

## Como funciona

O T2 expõe a iluminação como interfaces HID proprietárias do dispositivo `05AC:8102`. O HeadlessGlow envia a elas feature reports, os mesmos usados pelo driver Linux `hid-apple`. Nada é gravado de forma permanente, e não é preciso alterar o SIP, instalar extensões de kernel nem ter acesso de administrador.

<details>
<summary>Detalhes</summary>
<br>

| Interface | Report | Conteúdo |
|---|---|---|
| `0xFF00:0x0F` (teclado) | ID 1 | brilho `u32` (100…14660), transição `u32` (ms) |
| | ID 3 | energia `u8` (0/1), transição `u32` (ms) |
| `0xFF12:0x01` (Touch Bar) | ID 1 | estado, nível de escurecimento, fator de brilho `u32` (0…1000) |

O fator da Touch Bar só permite escurecê-la; o macOS também o reescreve quando escurece a Touch Bar por conta própria, então o HeadlessGlow reaplica o ajuste após cada despertar. A detecção de inatividade usa `HIDIdleTime`, e as teclas de brilho são lidas com um event tap somente de escuta.

</details>

## Desinstalação

```sh
./uninstall.sh
```

Remove o app, o comando, o serviço de início de sessão, os ajustes, a permissão, o certificado de assinatura e os logs.

<details>
<summary>Solução de problemas</summary>
<br>

- `headlessglow get` mostra o que o T2 informa.
- A seção *Status* dos ajustes mostra a permissão e o estado dos controladores, e abre o log.
- Log detalhado: `defaults write io.github.onixbrave.headlessglow debugLog -bool YES`, depois `headlessglow reload`.

</details>

<details>
<summary>Desenvolvimento</summary>
<br>

- `./build.sh` compila o app; `./tools/package.sh` gera o zip da release. Enviar uma tag `v*` compila, testa e publica uma release pelo GitHub Actions.
- `./tools/update-strings.sh` sincroniza o catálogo de traduções com o código.
- `headlessglow --snapshot <pasta>` salva as janelas do app em PNG.
- O acesso ao hardware fica em `src/core/kbhw.c`; o app é escrito em Swift e SwiftUI.

</details>

## Créditos

- Formato dos reports do teclado: o driver Linux `hid-apple` e a comunidade [t2linux](https://t2linux.org).
- [KBPulse](https://github.com/EthanRDoesMC/KBPulse), de EthanRDoesMC, pelo trabalho inicial com o CoreBrightness.

## Apoie o projeto

O HeadlessGlow é gratuito. Doações são bem-vindas:

| Moeda | Rede | Endereço |
|---|---|---|
| Bitcoin | Bitcoin | `bc1qsmpzq2hzruf2lgpexz4wtg0p0c0t8uxujnckfw` |
| ETH, USDC, USDT | Ethereum, Base, Arbitrum, Optimism | `0x2860E6465E03E714e4eCa092DcaeCCE2CE601D1C` |
| Litecoin | Litecoin | `LeDfGzBNgJGJURon1LCizT9n8LshTThBjD` |

Confira a rede antes de enviar. Dar uma estrela ao repositório também ajuda.

## Aviso

O HeadlessGlow usa interfaces de hardware não documentadas e foi testado em um único modelo. Use por sua conta e risco. Sem vínculo com a Apple.

## Licença

[MIT](LICENSE) © 2026 OnixBrave
