install_docker() {
  if command_exists docker; then
    log_info "Docker já está instalado"

    TARGET_USER="${SUDO_USER:-${USER:-}}"
    [ -z "$TARGET_USER" ] && TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")

    if [ -n "$TARGET_USER" ] && ! id -nG "$TARGET_USER" | grep -qw docker; then
      run_as_root usermod -aG docker "$TARGET_USER" || true
      log_info "Usuário $TARGET_USER adicionado ao grupo docker"
    fi

    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria Docker seguindo a documentação oficial"
    log_info "[SIMULAÇÃO] Instalaria ca-certificates e curl"
    log_info "[SIMULAÇÃO] Criaria /etc/apt/keyrings"
    log_info "[SIMULAÇÃO] Baixaria docker.asc"
    log_info "[SIMULAÇÃO] Criaria /etc/apt/sources.list.d/docker.sources"
    log_info "[SIMULAÇÃO] apt update"
    log_info "[SIMULAÇÃO] apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    log_info "[SIMULAÇÃO] systemctl enable --now docker"
    log_info "[SIMULAÇÃO] usermod -aG docker \$USER"
    return 0
  fi

  log_info "Instalando dependências"

  run_as_root apt-get update -qq

  run_as_root apt-get install -y \
    ca-certificates \
    curl || {
      log_warning "Falha ao instalar dependências"
      return 1
    }

  log_info "Configurando repositório oficial do Docker"

  run_as_root install -m 0755 -d /etc/apt/keyrings

  run_as_root curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc || {
      log_warning "Falha ao baixar chave GPG"
      return 1
    }

  run_as_root chmod a+r /etc/apt/keyrings/docker.asc

  local arch codename

  arch="$(dpkg --print-architecture)"

  . /etc/os-release
  codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

  run_as_root tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Architectures: $arch
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  log_info "Atualizando índice de pacotes"

  run_as_root apt-get update -qq || {
    log_warning "Falha ao atualizar índice de pacotes"
    return 1
  }

  log_info "Instalando Docker"

  run_as_root apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin || {
      log_warning "Falha ao instalar Docker"
      return 1
    }

  run_as_root systemctl enable --now docker || {
    log_warning "Falha ao iniciar docker.service"
    return 1
  }

  TARGET_USER="${SUDO_USER:-${USER:-}}"

  [ -z "$TARGET_USER" ] && TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")

  if [ -n "$TARGET_USER" ]; then
    if ! id -nG "$TARGET_USER" | grep -qw docker; then
      run_as_root usermod -aG docker "$TARGET_USER"
      log_info "Usuário $TARGET_USER adicionado ao grupo docker (logout necessário)"
    fi
  fi

  if systemctl is-active --quiet docker; then
    log_info "Docker instalado com sucesso"
  else
    log_warning "Docker instalado, porém o serviço não está em execução"
  fi
}