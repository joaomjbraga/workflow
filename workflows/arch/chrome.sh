#!/usr/bin/env bash
set -Eeuo pipefail

install_chrome() {
  if command_exists google-chrome || command_exists google-chrome-stable; then
    log_info "Google Chrome já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria google-chrome via AUR"
    return 0
  fi

  log_info "Instalando Google Chrome via AUR"
  aur_install google-chrome || log_warning "Falha ao instalar Google Chrome"
}
