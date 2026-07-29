#!/usr/bin/env bash
set -Eeuo pipefail

install_android_studio() {
  if command_exists android-studio || [ -d /opt/android-studio ]; then
    log_info "Android Studio já está instalado"
    return 0
  fi

  if command_exists flatpak; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Instalaria android-studio via flatpak"
      return 0
    fi
    log_info "Instalando Android Studio via Flatpak"
    flatpak install -y flathub com.android.Studio || {
      log_warning "Falha ao instalar Android Studio via Flatpak"
      return 1
    }
    return 0
  fi

  log_warning "Flatpak não encontrado; Android Studio não pode ser instalado"
  return 1
}