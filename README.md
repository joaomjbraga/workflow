# workflow

Ferramenta pessoal de pós-instalação para Linux.

ATENÇÃO: este repositório contém o meu "workflow" pessoal. Ele instala e remove ferramentas conforme as minhas preferências pessoais (por exemplo, eu uso Docker e removo `podman`; não uso `snap`/`flatpak` para certos pacotes). Se você pretende usar este script em outro ambiente (como trabalho), revise o conteúdo antes de executar.

Execute `./install.sh` para provisionar um sistema a partir de uma instalação limpa.

## Início rápido

```bash
chmod +x install.sh
./install.sh --dry-run   # simula as ações sem fazer alterações
./install.sh             # executa de fato
```

## Uso

```bash
./install.sh              # instalação completa (interativa)
./install.sh --dry-run    # simula sem fazer alterações
./install.sh --yes        # modo não-interativo
./install.sh uninstall    # reverte a instalação
./install.sh vscode       # instala apenas o VS Code
./install.sh git-config   # configura o Git interativamente
```

Também disponível via Makefile:

```bash
make dry-run      # simulação
make apply        # instalação completa com --yes
make uninstall    # desinstalação
make vscode       # instala apenas o VS Code
make git-config   # configura o Git
```

## Logs

Os logs são gravados em: `$XDG_CACHE_HOME/workflow/install.log` (padrão `~/.cache/workflow/install.log`).

## Fontes

Coloque arquivos `.ttf` ou `.otf` nas pastas `font/` ou `fonts/` na raiz do repositório; eles serão copiados para `~/.local/share/`.

## Estrutura

```
install.sh        → Entry point: detecta a distribuição e carrega o workflow
lib/              → Framework compartilhado entre distribuições
├── core.sh       → Utilitários (logging, sudo, pacotes)
└── detect.sh     → Detecção da distribuição
workflows/        → Workflows específicos por distribuição
└── arch/         → Workflow Arch Linux
    ├── main.sh   → Orquestrador (ordem dos passos)
    ├── packages.sh   → Pacotes base + yay (helper AUR)
    ├── docker.sh     → Docker
    ├── node.sh       → NVM + Node.js
    ├── zsh.sh        → Starship + Zsh + plugins
    ├── fonts.sh      → Fontes
    ├── android.sh    → Android Studio (AUR)
    ├── vscode.sh     → VS Code (AUR)
    ├── chrome.sh     → Google Chrome (AUR)
    ├── go.sh         → Go
    ├── java.sh       → OpenJDK 17
    ├── git.sh        → Configuração do Git
    ├── tweaks.sh     → Ajustes específicos (fstrim)
    └── uninstall.sh  → Reversão completa
config/           → Configurações compartilhadas
├── starship.toml
├── zshrc
├── bashrc
└── logrotate/workflow
fonts/            → Fontes .ttf/.otf
```

## O que é instalado

- **Base:** curl, wget, git, zsh, unzip, flatpak, base-devel
- **yay** (helper AUR)
- **Docker + Docker Compose + Docker Buildx**
- **Go** (pacote oficial)
- **OpenJDK 17**
- **NVM + Node.js 22**
- **Starship** + Zsh com plugins (autosuggestions, syntax-highlighting)
- **Fontes** (Nerd Fonts)
- **Android Studio** (AUR)
- **Visual Studio Code** (AUR)
- **Google Chrome** (AUR)
- **Configuração Git** (interativa)
- **fstrim.timer** (Arch)

## Segurança e idempotência

- Os scripts verificam se comandos e pacotes já existem antes de instalar.
- `install.sh --dry-run` simula todas as etapas sem alterar o sistema.
- Operações que exigem privilégios usam `sudo` apenas quando necessário.

## Suporte a distribuições

Atualmente apenas **Arch Linux** (e derivados como Manjaro) são suportados.

Para adicionar uma nova distribuição:
1. Crie `workflows/<distro>/main.sh`
2. Implemente os passos específicos (pacotes, docker, vscode, etc.)
3. Adicione a detecção em `lib/detect.sh`

## Limitações e observações

- O instalador requer acesso à rede para downloads e clones via `git`.
- A compilação via AUR para `yay-bin` requer `makepkg` e as ferramentas de `base-devel`.
- O script utiliza `sudo` para operações privilegiadas.
- Adicionar o usuário atual ao grupo `docker` requer logout/login para surtir efeito.

## Solução de problemas

- Verifique o log em `$XDG_CACHE_HOME/workflow/install.log` para detalhes.
- Use `./install.sh --dry-run` para visualizar as alterações antes de aplicá-las.
