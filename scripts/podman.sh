#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker.sh"

remove_podman() {
  if ! command_exists podman; then
    log_info "podman não está presente"
    return 0
  fi

  log_info "podman detectado no sistema"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[SIMULAÇÃO] Removeria podman e limparia containers/imagens/volumes"
    return 0
  fi

  if [ -t 0 ]; then
    read -rp "Confirmar remoção do podman e de todos os seus containers/imagens (isso é irreversível)? [s/N]: " confirm
    if [[ ! "$confirm" =~ ^[SsYy]$ ]]; then
      log_info "Usuário recusou a remoção do podman"
      return 0
    fi
  else
    if [ "${AUTO_YES:-false}" != "true" ]; then
      log_info "Shell não-interativo e --yes não fornecido; ignorando remoção do podman"
      return 0
    fi
  fi

  run_as_root systemctl stop podman.socket podman.service || true

  if command_exists podman; then
    run_as_root podman ps -a -q | xargs -r -n1 podman rm -f || true
    run_as_root podman images -q | xargs -r -n1 podman rmi -f || true
    run_as_root podman volume ls -q | xargs -r -n1 podman volume rm -f || true
  fi

  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get purge -y podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    pacman)
      run_as_root pacman -Rns --noconfirm podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    dnf)
      run_as_root dnf remove -y podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    *)
      log_warning "Gerenciador de pacotes desconhecido; remova o podman manualmente"
      ;;
  esac

  run_as_root systemctl disable --now podman.socket podman.service || true
  run_as_root systemctl daemon-reload || true
  log_success "Remoção do podman concluída (ou simulada)"

  if ! command_exists docker; then
    log_info "Docker não encontrado; instalando Docker para substituir o Podman"
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Instalaria docker via $PKG_MANAGER"
    else
      install_package docker || log_warning "Falha ao instalar docker"
    fi
  fi

  if command_exists docker; then
    log_info "Habilitando e iniciando serviço Docker"
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] sudo systemctl enable --now docker"
    else
      run_as_root systemctl enable --now docker || log_warning "Falha ao habilitar/iniciar docker"
    fi

    TARGET_USER="${SUDO_USER:-${USER:-}}"
    if [ -z "$TARGET_USER" ]; then
      TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")
    fi
    if [ -n "$TARGET_USER" ]; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[SIMULAÇÃO] Adicionaria $TARGET_USER ao grupo docker"
      else
        run_as_root usermod -aG docker "$TARGET_USER" || log_warning "Não foi possível adicionar $TARGET_USER ao grupo docker"
        log_info "Usuário $TARGET_USER adicionado ao grupo docker (pode ser necessário fazer logout)"
      fi
    fi
  fi
}

export -f remove_podman