# Limitações e problemas conhecidos

Esse script resolve *meu* problema, mas tem suas frescuras. Aqui vai o que
você precisa saber antes de sair usando:

---

### Só funciona no Arch e Pop!_OS

No momento, **Arch Linux**, **Manjaro** e **Pop!_OS** são suportados.

Se quiser adicionar outra, o esquema é:

1. Cria `workflows/<distro>/main.sh`
2. Implementa os passos
3. Adiciona a detecção em `lib/detect.sh`

A estrutura foi feita pra ser extensível, mas a implementação extra fica por sua conta.

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

### Pop!_OS específico

No Pop!_OS, `system76-driver` e `system76-power` já vêm pré-instalados
e não precisam ser gerenciados pelo script.

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
