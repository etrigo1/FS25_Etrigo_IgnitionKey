# Ignition Key (FS25_IgnitionKey)

Farming Simulator 25 mod: a real ignition key on the keyboard, using the normal engine start key. No new key bindings.

Português mais abaixo.

## How it works (default mode `key`)

| Engine | Key | Result |
|---|---|---|
| Off | tap | Ignition on: dashboard lights up, engine stopped |
| Off | hold | Turns the key all the way: ignition, then start |
| Ignition | tap | Ignition off |
| Ignition | hold | Starts the engine |
| Starting | release | Keeps cranking until the engine catches, like the real key |
| Running | tap | Stops the engine |

- Leaving the vehicle with the ignition on switches it off.
- Works only with **automatic engine start disabled** in the game settings.
- With the hardware ignition lock connected, or a helper working, the game works as normal.
- Multiplayer supported.

## Key modes

Choose how the key works in the settings file (see below):

| `mode` | Off | Ignition | Running |
|---|---|---|---|
| `key` (default) | tap: ignition on · hold: turn the key all the way and start | tap: ignition off · hold: start | tap: stop |
| `twoTaps` | tap: ignition on | press: start | press: stop |
| `single` | press: start (like the base game) | — | press: stop |

In every mode, releasing the key while cranking does not stop the start.

**Change the mode in game:** set a key for *Ignition key: change mode* in **Options → Controls** (no key by default). Each press switches `key` → `twoTaps` → `single`, shows a short message at the top of the screen and saves the mode in the settings file. It does not appear in the F1 help.

## Settings

The first time you enter a vehicle, the mod creates this file:

`Documents/My Games/FarmingSimulator2025/modSettings/IgnitionKey.xml`

(Up to 1.1.0.0 it was `FS25_Etrigo_IgnitionKey.xml`. If the new file does not exist yet, the mod reads the old one once and then saves to the new name.)

```xml
<ignitionKey>
    <debug enabled="false"/>
    <start mode="key" holdToCrankMs="350" modes="key | twoTaps | single"/>
</ignitionKey>
```

| Option | Values | What it does |
|---|---|---|
| `start mode` | `key` · `twoTaps` · `single` | How the key works (table above). Default `key`. An invalid value goes back to `key` |
| `start holdToCrankMs` | 100 to 2000 | Mode `key` only: how long (ms) to hold the key to start. Default 350 |
| `debug enabled` | `true` · `false` | `true` writes `[IgnitionKey][debug]` lines to `log.txt` (for testing). Default `false` |

- The file is read when the game starts: **restart the game after editing it**.
- Each player has their own file on their own PC.
- `modes` is only a reminder of the possible values; the mod does not read it.

## Advanced Damage System (ADS)

Works alongside [FS25_AdvancedDamageSystem](https://github.com/id577/FS25_AdvancedDamageSystem-dev). The key is shared with ADS:

- **Hard start:** in every mode, you hold the key and ADS keeps cranking while you hold it.
- **Battery and starter failures:** they still apply, and ADS decides whether the engine catches.
- **Help text:** the one shown is the ADS text.

## Installation

Download `FS25_IgnitionKey.zip` from the [Releases](https://github.com/etrigo1/FS25_Etrigo_IgnitionKey/releases) and put it in your `mods` folder (do not unzip it).

**Updating from 1.1.0.0 or older:** the zip used to be called `FS25_Etrigo_IgnitionKey.zip`. **Delete the old zip** from your `mods` folder, otherwise the game loads the mod twice. Your settings are kept.

## Versions

- **1.1.0.1** — New names: the zip is `FS25_IgnitionKey.zip` and the settings file is `modSettings/IgnitionKey.xml` (the old file is read once).
- **1.1.0.0** — Settings file: three key modes (`key`, `twoTaps`, `single`), hold time and debug. Optional key to change the mode in game. README inside the zip.
- **1.0.0.0** — First release: ignition key on the keyboard, dashboard at ignition, ADS compatible.

---

# Chave de Ignição (PT)

Chave de ignição no teclado, na tecla normal de arranque do motor. Sem teclas novas.

## Como funciona (modo `key`, por defeito)

| Motor | Tecla | Resultado |
|---|---|---|
| Desligado | toque | Liga a ignição: o painel acende, o motor fica parado |
| Desligado | manter premido | Roda a chave toda: ignição e arranque |
| Ignição | toque | Desliga a ignição |
| Ignição | manter premido | Arranca o motor |
| A arrancar | largar | Continua a tentar até pegar, como a chave real |
| A trabalhar | toque | Desliga o motor |

- Sair do veículo com a ignição ligada desliga-a.
- Só funciona com o **arranque automático do motor desligado** nas opções do jogo.
- Com o canhão de ignição físico ligado, ou com um trabalhador a trabalhar, o jogo funciona como de origem.
- Suporta multiplayer.

## Modos da tecla

Escolhe-se no ficheiro de definições (ver abaixo):

| `mode` | Desligado | Ignição | A trabalhar |
|---|---|---|---|
| `key` (por defeito) | toque: liga a ignição · manter premido: roda a chave toda e arranca | toque: desliga a ignição · manter premido: arranca | toque: desliga |
| `twoTaps` | toque: liga a ignição | carregar: arranca | carregar: desliga |
| `single` | carregar: arranca (como o jogo base) | — | carregar: desliga |

Em todos os modos, largar a tecla durante o arranque não o interrompe.

**Mudar o modo dentro do jogo:** define uma tecla para *Chave de ignição: mudar modo* em **Opções → Controlos** (não tem tecla por defeito).
- Cada toque muda `key` → `twoTaps` → `single`.
- Mostra uma mensagem curta no topo do ecrã e grava o modo no ficheiro de definições.
- Não aparece na ajuda do F1.

## Definições

Na primeira vez que entras num veículo, o mod cria este ficheiro:

`Documentos/My Games/FarmingSimulator2025/modSettings/IgnitionKey.xml`

(Até à 1.1.0.0 chamava-se `FS25_Etrigo_IgnitionKey.xml`. Se o ficheiro novo ainda não existir, o mod lê o antigo uma vez e passa a gravar com o nome novo.)

| Opção | Valores | O que faz |
|---|---|---|
| `start mode` | `key` · `twoTaps` · `single` | Como funciona a tecla (tabela acima). Por defeito `key`. Um valor errado volta a `key` |
| `start holdToCrankMs` | 100 a 2000 | Só no modo `key`: tempo (ms) a segurar a tecla para arrancar. Por defeito 350 |
| `debug enabled` | `true` · `false` | `true` escreve linhas `[IgnitionKey][debug]` no `log.txt` (para testes). Por defeito `false` |

- O ficheiro é lido quando o jogo arranca: **depois de o mudares, reinicia o jogo**.
- Cada jogador tem o seu ficheiro, no seu PC.
- O `modes` é só um lembrete dos valores possíveis; o mod não o lê.

## Advanced Damage System (ADS)

Funciona ao lado do Advanced Damage System. A tecla é partilhada com o ADS:

- **Arranque difícil:** em todos os modos, seguras a tecla e o ADS continua a rodar o motor de arranque enquanto seguras.
- **Avarias de bateria e de motor de arranque:** continuam a funcionar, e é o ADS que decide se o motor pega.
- **Texto de ajuda:** o que aparece é o do ADS.

## Instalação

Descarrega o `FS25_IgnitionKey.zip` das [Releases](https://github.com/etrigo1/FS25_Etrigo_IgnitionKey/releases) e põe-no na pasta `mods` (sem descompactar).

**Se vens da 1.1.0.0 ou anterior:** o zip chamava-se `FS25_Etrigo_IgnitionKey.zip`. **Apaga o zip antigo** da pasta `mods`, senão o jogo carrega o mod duas vezes. As tuas definições mantêm-se.

## Versões

- **1.1.0.1** — Nomes novos: o zip passa a `FS25_IgnitionKey.zip` e o ficheiro de definições a `modSettings/IgnitionKey.xml` (o antigo é lido uma vez).
- **1.1.0.0** — Ficheiro de definições: três modos da tecla (`key`, `twoTaps`, `single`), tempo de manter premido e debug. Tecla opcional para mudar o modo no jogo. README dentro do zip.
- **1.0.0.0** — Primeira versão: chave de ignição no teclado, painel em ignição, compatível com o ADS.

Author / Autor: Etrigo — https://github.com/etrigo1/FS25_Etrigo_IgnitionKey
