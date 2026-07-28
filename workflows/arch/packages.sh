#!/usr/bin/env bash
set -Eeuo pipefail

install_base_dependencies() {
  local pkgs=(base-devel curl wget git zsh unzip ca-certificates flatpak)

  for p in "${pkgs[@]}"; do
    install_package "$p" || log_warning "Falha ao instalar $p"
  done

  if command_exists flatpak; then
    run_as_root flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    if [ -d "/run/systemd/system" ] && command -v systemctl >/dev/null 2>&1; then
      for unit in flatpak.service flatpak-system-helper.service; do
        if systemctl list-unit-files | grep -q "^${unit}"; then
          run_as_root systemctl enable --now "$unit" || true
        fi
      done
    fi
  fi
}

install_yay() {
  if command_exists yay; then
    log_info "yay já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Clonaria yay-bin do AUR e executaria makepkg -si"
    return 0
  fi

  local td
  td=$(temp_dir)
  git clone https://aur.archlinux.org/yay-bin.git "$td/yay-bin" || {
    log_warning "Não foi possível clonar yay-bin"
    rm -rf "$td"
    return 1
  }
  (cd "$td/yay-bin" && makepkg -si --noconfirm) || {
    log_warning "makepkg para yay falhou"
    rm -rf "$td"
    return 1
  }
  rm -rf "$td"
  log_success "yay instalado com sucesso"
}

aur_install() {
  local pkg="$1"
  if command_exists yay; then
    yay -S --noconfirm "$pkg" || return 1
  elif command_exists paru; then
    paru -S --noconfirm "$pkg" || return 1
  else
    log_info "Nenhum helper AUR encontrado; tentando build manual"
    local td
    td=$(temp_dir)
    git clone "https://aur.archlinux.org/${pkg}.git" "$td/$pkg" || {
      rm -rf "$td"
      return 1
    }
    (cd "$td/$pkg" && makepkg -si --noconfirm) || {
      rm -rf "$td"
      return 1
    }
    rm -rf "$td"
  fi
}
