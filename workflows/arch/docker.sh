#!/usr/bin/env bash
set -Eeuo pipefail

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
    log_info "[SIMULAÇÃO] sudo pacman -Syu --noconfirm"
    log_info "[SIMULAÇÃO] sudo pacman -S --noconfirm docker docker-compose docker-buildx"
    log_info "[SIMULAÇÃO] sudo systemctl enable --now docker"
    log_info "[SIMULAÇÃO] sudo usermod -aG docker $USER"
    return 0
  fi

  log_info "Sincronizando pacman antes da instalação do Docker (conforme documentação oficial)"
  run_as_root pacman -Sy --noconfirm || true

  log_info "Instalando Docker Engine, Compose e Buildx"
  run_as_root pacman -S --noconfirm docker docker-compose docker-buildx || {
    log_warning "Falha ao instalar pacotes Docker"
    return 1
  }

  log_info "Habilitando e iniciando docker.service"
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
