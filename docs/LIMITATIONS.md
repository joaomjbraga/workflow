# Limitações e problemas conhecidos

Esse script resolve *meu* problema, mas tem suas frescuras. Aqui vai o que
você precisa saber antes de sair usando:

---

### Só funciona no Arch (e derivados)

No momento, só **Arch Linux** e **Manjaro** são suportados. Se você usa
outra distribuição, vai precisar criar um workflow pra ela em
`workflows/<distro>/` e adicionar a detecção em `lib/detect.sh`.
A estrutura foi feita pra ser extensível, mas a implementação extra
fica por sua conta.

---

### Precisa de internet

O script baixa pacotes, clona repositórios do AUR e faz `curl` de
scripts de instalação. Se você estiver num ambiente restrito (sem
acesso à internet ou com proxy), vai precisar baixar os artefatos
antecipadamente ou configurar mirrors locais.

---

### Compilação do AUR

O `yay-bin` é compilado na hora com `makepkg -si`. Isso significa que
você precisa do `base-devel` instalado (o script instala) e que a
compilação pode levar alguns segundos. Em máquinas mais fracas, pode
demorar um pouco.

---

### Sudo é obrigatório

O script usa `sudo` pra instalar pacotes e ativar serviços. Se você
executar de forma não interativa num sistema sem `sudo` configurado
(ou sem permissão pra usar), vai falhar.

---

### Grupo Docker

Se você for adicionado ao grupo `docker`, precisa fazer **logout e
login** pra生效. Não adianta só fechar o terminal — tem que sair da
sessão mesmo. O script avisa no final, mas é bom já saber.

---

### Encontrou um problema?

Antes de abrir uma issue, roda o `--dry-run` e cola a saída junto com
as linhas relevantes do log em `~/.cache/workflow/install.log`. Isso
ajuda a identificar onde a coisa quebrou.
