#!/usr/bin/env bash
set -Eeuo pipefail

install_power_profiles() {
  if command_exists powerprofilesctl; then
    log_info "Power Profiles Daemon já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria power-profiles-daemon"
    log_info "[SIMULAÇÃO] sudo pacman -S --noconfirm power-profiles-daemon"
    log_info "[SIMULAÇÃO] sudo systemctl enable --now power-profiles-daemon"
    return 0
  fi

  log_info "Instalando Power Profiles Daemon"
  run_as_root pacman -S --noconfirm power-profiles-daemon || {
    log_warning "Falha ao instalar power-profiles-daemon"
    return 1
  }

  log_info "Habilitando e iniciando power-profiles-daemon"
  run_as_root systemctl enable --now power-profiles-daemon || log_warning "Falha ao habilitar/iniciar power-profiles-daemon"

  log_success "Power Profiles Daemon instalado e ativo"
}
