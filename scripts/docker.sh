#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

remove_conflicting_packages() {
  log_info "Removendo pacotes conflitantes do Docker"

  case "$PKG_MANAGER" in
    apt)
      local conflicting_pkgs="docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc"
      for pkg in $conflicting_pkgs; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
          log_info "Removendo pacote conflitante: $pkg"
          run_as_root apt-get purge -y "$pkg" || true
        fi
      done
      ;;
    dnf)
      local conflicting_pkgs="docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine"
      for pkg in $conflicting_pkgs; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
          log_info "Removendo pacote conflitante: $pkg"
          run_as_root dnf remove -y "$pkg" || true
        fi
      done
      ;;
    pacman)
      ;;
  esac
}

setup_docker_repository() {
  log_info "Configurando repositório oficial do Docker"

  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y ca-certificates curl || true

      run_as_root install -m 0755 -d /etc/apt/keyrings || true
      run_as_root curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || {
        log_warning "Falha ao baixar chave GPG do Docker"
        return 1
      }
      run_as_root chmod a+r /etc/apt/keyrings/docker.asc || true

      local distro_id="${DISTRO_ID:-debian}"
      local version_codename
      version_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

      case "$distro_id" in
        ubuntu|linuxmint|pop)
          version_codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
          distro_id="ubuntu"
          ;;
        debian)
          distro_id="debian"
          ;;
      esac

      run_as_root tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$distro_id
Suites: $version_codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

      run_as_root apt-get update -y || true
      ;;
    dnf)
      run_as_root dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo || {
        log_warning "Falha ao adicionar repositório do Docker"
        return 1
      }
      ;;
    pacman)
      ;;
  esac
}

install_docker() {
  if command_exists docker; then
    log_info "Docker já está instalado"
  else
    remove_conflicting_packages

    setup_docker_repository || {
      log_warning "Falha ao configurar repositório do Docker, usando pacotes da distro"
      install_package docker || log_warning "Falha ao instalar pacote docker"
      return 0
    }

    log_info "Instalando pacotes do Docker pelo repositório oficial"

    case "$PKG_MANAGER" in
      apt)
        run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
          log_warning "Falha ao instalar Docker pelo repositório oficial"
          return 1
        }
        ;;
      dnf)
        run_as_root dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
          log_warning "Falha ao instalar Docker pelo repositório oficial"
          return 1
        }
        ;;
      pacman)
        install_package docker || log_warning "Falha ao instalar pacote docker"
        install_package docker-compose || log_warning "Falha ao instalar pacote docker-compose"
        ;;
    esac
  fi

  run_as_root systemctl enable --now docker || log_warning "Falha ao habilitar/iniciar docker"

  TARGET_USER="${SUDO_USER:-${USER:-}}"
  if [ -z "$TARGET_USER" ]; then
    TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")
  fi

  if [ -n "$TARGET_USER" ]; then
    if id -nG "$TARGET_USER" | grep -qw docker; then
      log_info "Usuário $TARGET_USER já está no grupo docker"
    else
      run_as_root usermod -aG docker "$TARGET_USER" || log_warning "Não foi possível adicionar $TARGET_USER ao grupo docker"
      log_info "Usuário $TARGET_USER adicionado ao grupo docker (pode ser necessário fazer logout)"
    fi
  else
    log_warning "Não foi possível determinar o usuário alvo para o grupo docker; ignorando"
  fi
}