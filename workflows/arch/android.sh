#!/usr/bin/env bash
set -Eeuo pipefail

install_android_studio() {
  if command_exists android-studio || [ -d /opt/android-studio ]; then
    log_info "Android Studio já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria android-studio via AUR"
    return 0
  fi

  log_info "Instalando Android Studio via AUR"
  aur_install android-studio || log_warning "Falha ao instalar Android Studio"
}
