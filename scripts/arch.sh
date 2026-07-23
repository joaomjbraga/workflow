#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

configure_arch() {
  if [ "$PKG_MANAGER" != "pacman" ]; then
    log_warning "configure_arch called on non-Arch system"
    return 0
  fi

  log_info "Enabling fstrim.timer"
  run_as_root systemctl enable fstrim.timer --now || log_warning "Could not enable fstrim.timer"
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

  # yay-bin installation
  if command_exists yay; then
    log_info "yay already installed"
  else
    log_info "Installing yay (AUR helper)"
    install_package git || true
    install_package base-devel || true
    local td
    td=$(temp_dir)
    git clone https://aur.archlinux.org/yay-bin.git "$td/yay-bin" || { log_warning "Could not clone yay-bin"; return 0; }
    (cd "$td/yay-bin" && makepkg -si --noconfirm) || log_warning "makepkg for yay failed"
    rm -rf "$td"
  fi
}
