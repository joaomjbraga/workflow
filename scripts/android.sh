#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_android_studio() {
  if ! command_exists flatpak; then
    log_warning "flatpak not available; Android Studio will not be installed"
    return 0
  fi

  run_as_root flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

  if flatpak list --app | grep -q com.google.AndroidStudio; then
    log_info "Android Studio already installed via Flatpak"
  else
    log_info "Installing Android Studio via Flatpak"
    run_as_root flatpak install -y flathub com.google.AndroidStudio || log_warning "flatpak install failed"
  fi
}
