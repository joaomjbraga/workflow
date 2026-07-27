#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

configure_arch() {
  if [ "$PKG_MANAGER" != "pacman" ]; then
    log_warning "configure_arch chamado em sistema não-Arch"
    return 0
  fi

  log_info "Habilitando fstrim.timer"
  run_as_root systemctl enable fstrim.timer --now || log_warning "Não foi possível habilitar fstrim.timer"
  run_as_root fstrim / || true

  local preset_dir="/etc/systemd/system-preset"
  local preset_file="$preset_dir/90-custom.preset"
  if [ ! -d "$preset_dir" ]; then
    run_as_root mkdir -p "$preset_dir"
  fi
  if [ -f "$preset_file" ]; then
    grep -q "enable fstrim.timer" "$preset_file" || run_as_root bash -c "echo 'enable fstrim.timer' >> '$preset_file'"
  else
    run_as_root bash -c "echo 'enable fstrim.timer' > '$preset_file'"
  fi
  run_as_root systemctl preset-all || true

  if command_exists yay; then
    log_info "yay já está instalado"
  else
    log_info "Instalando yay (helper do AUR)"
    install_package git || true
    install_package base-devel || true
    local td
    td=$(temp_dir)
    git clone https://aur.archlinux.org/yay-bin.git "$td/yay-bin" || { log_warning "Não foi possível clonar yay-bin"; return 0; }
    (cd "$td/yay-bin" && makepkg -si --noconfirm) || log_warning "makepkg para yay falhou"
    rm -rf "$td"
  fi
}