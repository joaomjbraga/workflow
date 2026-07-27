#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_android_studio() {
  if ! command_exists flatpak; then
    log_warning "flatpak não está disponível; Android Studio não será instalado"
    return 0
  fi

  run_as_root flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

  if flatpak list --app | grep -q com.google.AndroidStudio; then
    log_info "Android Studio já está instalado via Flatpak"
  else
    log_info "Instalando Android Studio via Flatpak"
    run_as_root flatpak install -y flathub com.google.AndroidStudio || log_warning "falha na instalação via flatpak"
  fi
}