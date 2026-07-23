# workflow

Ferramenta pessoal de pós-instalação para Linux.

ATENÇÃO: este repositório contém o meu "workflow" pessoal — ele instala e remove ferramentas conforme as minhas preferências pessoais (por exemplo, eu uso Docker e removo `podman`; não uso `snap`/`flatpak` para certos pacotes). Se você pretende usar este script em outro ambiente (como trabalho), revise o conteúdo de `install.sh` e os scripts em `scripts/` antes de executar.

Execute `./install.sh` para provisionar um sistema a partir de uma instalação limpa.

Início rápido:

```bash
chmod +x install.sh
./install.sh --dry-run   # simula as ações sem fazer alterações
./install.sh             # executa de fato
```

Logs são gravados em: `$XDG_CACHE_HOME` ou `~/.cache/workflow/install.log`.

Fontes: coloque arquivos `.ttf` ou `.otf` nas pastas `font/` ou `fonts/` na raiz do repositório; eles serão copiados para `~/.local/share/`.

Veja os diretórios `scripts/` e `config/` para a implementação modular. O instalador é idempotente e pode ser executado repetidas vezes com segurança.

Personalização importante: o instalador pode remover componentes do sistema (ex.: `podman`, `snapd`) quando você executar com `--yes`. Use `--dry-run` para revisar ações antes de aplicar.

O que foi implementado
- Detecção de distribuição (`/etc/os-release`) e mapeamento de gerenciador de pacotes para `apt`, `pacman` e `dnf`.
- Instalação idempotente de pacotes com resolução de nomes por distribuição.
- Instaladores para: Docker (e gestão de grupo), NVM + Node.js (v22), Go (pacote da distro ou fallback por tarball), scrcpy, Starship, Zsh (com plugins) e Android Studio (via Flatpak).
- Cópia de fontes de `font/` ou `fonts/` para `~/.local/share/` (suporta `.ttf` e `.otf`).
- Algumas ferramentas (por exemplo, projetos pessoais como "Glowkey") são gerenciadas fora deste instalador e não serão instaladas automaticamente; instale-as manualmente quando desejar.
- Tarefas específicas do Arch: habilitação de `fstrim.timer` e instalação de `yay-bin` via AUR (diretório temporário para build).

Segurança e idempotência
- Os scripts verificam se comandos e pacotes já existem antes de instalar.
- `install.sh --dry-run` simula todas as etapas e mostra o que seria executado sem alterar o sistema.
- Operações que exigem privilégios usam `sudo` apenas quando necessário.

Limitações e observações
- Nomes de pacotes variam entre distribuições; `resolve_pkg_name` fornece mapeamentos básicos, mas pode ser necessário ajustar manualmente para alguns pacotes.
- O instalador do Go prefere o pacote da distro; quando ausente, baixa um tarball e instala em `/usr/local/go`.
- Adicionar o usuário atual ao grupo `docker` requer logout/login para surtir efeito.
- O instalador pressupõe acesso à rede e falhará em ambientes sem conectividade ou com DNS bloqueado.
- O script não trata especificamente sistemas com SELinux em modo enforcing.

Solução de problemas
- Verifique o log em `$XDG_CACHE_HOME` ou `~/.cache/workflow/install.log` para detalhes.
- Use `./install.sh --dry-run` para visualizar as alterações antes de aplicá-las.

