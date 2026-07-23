Limitações e problemas conhecidos

- Os mapeamentos de nomes de pacotes são básicos. Algumas distribuições ou versões podem usar nomes diferentes para pacotes ou meta-pacotes. Se um pacote falhar ao instalar, verifique o nome do pacote na sua distro e atualize `scripts/packages.sh::resolve_pkg_name`.
- O fallback que instala o Go por tarball utiliza `/usr/local/go` e adiciona o caminho em `~/.profile`. Usuários com shells personalizados ou mecanismos diferentes de carregamento de perfil podem precisar configurar o PATH manualmente.
- O instalador requer acesso à rede para downloads e clones via `git`. Em ambientes restritos, faça o pré-download dos artefatos ou forneça mirrors locais.
- A compilação via AUR para `yay-bin` requer `makepkg` e as ferramentas de `base-devel` e executará `makepkg -si`, o que realiza instalações no sistema.
- O script utiliza `sudo` para operações privilegiadas; executar de forma não interativa em sistemas sem `sudo` configurado resultará em falha.
- Não há tratamento avançado de prompts interativos além do `chsh` como fallback; considere executar de forma interativa ao trocar o shell padrão.

Se encontrar um problema, abra uma issue no repositório incluindo a saída de `--dry-run` e linhas relevantes do log em `~/.cache/workflow/install.log`.
