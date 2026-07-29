# workflow

Este é o meu kit de sobrevivência pós-formatação. Depois de instalar o Arch
limpinho, eu executo esse script e ele monta meu ambiente de desenvolvimento
do jeito que eu gosto — sem eu ter que lembrar passo a passo toda vez.

⚠️ **Isso é pessoal.** Esse repositório reflete *minhas* escolhas (por exemplo,
eu uso Docker, não uso Podman). Se você for usar num ambiente de trabalho,
leia o código antes — sério, é pouco e tá bem comentado.

---

## Pra começar

```bash
chmod +x install.sh
./install.sh --dry-run   # dá uma espiada no que vai rolar
./install.sh             # bora
```

---

## Como usar

```bash
./install.sh              # instala tudo (modo interativo)
./install.sh --yes        # instala tudo sem perguntar
./install.sh --dry-run    # só mostra o que faria
./install.sh uninstall    # desfaz tudo
./install.sh vscode       # só o VS Code
./install.sh git-config   # só configurar Git
```

Também dá pra usar pelo `make`:

```bash
make dry-run      # simular
make apply        # instalar (modo automático)
make uninstall    # desinstalar
make vscode       # só VS Code
make git-config   # só Git
```

---

## O que ele instala

| Categoria | Itens |
|---|---|
| **Base** | `curl`, `wget`, `git`, `zsh`, `unzip`, `base-devel` |
| **AUR helper** | `yay-bin` (compilado na hora) |
| **Containers** | Docker + Compose + Buildx |
| **Linguagens** | Go, OpenJDK 17, Node.js 22 (via NVM) |
| **Terminal** | Starship + Zsh com autosuggestions e syntax-highlighting |
| **Programas** | VS Code, Android Studio, Google Chrome |
| **Fontes** | FiraCode Nerd Font e JetBrains Mono |
| **Extras** | Configuração de Git, `fstrim.timer` pra SSD |

---

## Logs

Tudo que acontece fica registrado em:

```
~/.cache/workflow/install.log
```

Se algo der errado, é pra lá que você olha primeiro.

---

## Estrutura do repositório

```
install.sh              → Ponto de partida
lib/
├── core.sh             → Funções compartilhadas (log, sudo, pacotes)
└── detect.sh           → Descobre qual sistema você tá usando
workflows/arch/         → Workflow pro Arch (e derivados)
├── main.sh             → Ordem dos passos
├── packages.sh         → Pacotes base + yay
├── docker.sh           → Docker
├── node.sh             → NVM + Node.js
├── zsh.sh              → Starship + Zsh + plugins
├── fonts.sh            → Fontes
├── android.sh          → Android Studio
├── vscode.sh           → VS Code
├── chrome.sh           → Google Chrome
├── go.sh               → Go
├── java.sh             → OpenJDK 17
├── git.sh              → Configurar Git
├── tweaks.sh           → Ajustes de sistema
├── power.sh            → Power Profiles Daemon
└── uninstall.sh        → Reverter tudo
config/                 → Meus dotfiles
fonts/                  → Fontes .ttf
```

---

## Segurança e idempotência

- Cada passo verifica se o bagulho já tá instalado antes de agir. Pode rodar
  quantas vezes quiser que não quebra nada.
- O modo `--dry-run` mostra tudo que vai acontecer sem mexer no sistema.
- Comandos que precisam de `sudo` só pedem senha quando necessário.

---

## Funciona em outras distribuições?

Por enquanto, só **Arch Linux** (e derivados tipo Manjaro).

Se quiser adicionar outra, o esquema é:

1. Cria `workflows/<distro>/main.sh`
2. Implementa os passos
3. Adiciona o detection no `lib/detect.sh`

Fácil de estender, a arquitetura foi feita pensando nisso.

---

## Dúvidas?

Antes de abrir issue, dá uma olhada no log (`~/.cache/workflow/install.log`)
e roda o `--dry-run` pra ver se o problema aparece por lá.
