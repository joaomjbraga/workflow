Limitações e problemas conhecidos

- Atualmente apenas Arch Linux e derivados (Manjaro) são suportados. Para adicionar suporte a outras distribuições, crie um workflow em `workflows/<distro>/` e atualize `lib/detect.sh`.
- O instalador requer acesso à rede para downloads e clones via `git`. Em ambientes restritos, faça o pré-download dos artefatos ou forneça mirrors locais.
- A compilação via AUR para `yay-bin` requer `makepkg` e as ferramentas de `base-devel` e executará `makepkg -si`, o que realiza instalações no sistema.
- O script utiliza `sudo` para operações privilegiadas; executar de forma não interativa em sistemas sem `sudo` configurado resultará em falha.
- Adicionar o usuário atual ao grupo `docker` requer logout/login para surtir efeito.

Se encontrar um problema, abra uma issue no repositório incluindo a saída de `--dry-run` e linhas relevantes do log em `~/.cache/workflow/install.log`.
