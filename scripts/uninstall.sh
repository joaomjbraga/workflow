#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

uninstall() {
  log_info "Running uninstall (dry-run=${DRY_RUN:-false})"

  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local repo_root="$(cd "$script_dir/.." && pwd)"

  # Remove fonts copied from repo
  local font_dir=""
  if [ -d "$repo_root/font" ]; then
    font_dir="$repo_root/font"
  elif [ -d "$repo_root/fonts" ]; then
    font_dir="$repo_root/fonts"
  fi
  if [ -n "$font_dir" ]; then
    for f in "$font_dir"/*.{ttf,otf}; do
      [ -e "$f" ] || continue
      local base="$(basename "$f")"
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[DRY RUN] Would remove font $base from ~/.local/share/fonts"
      else
        rm -f "$HOME/.local/share/fonts/$base" && log_info "Removed font $base"
      fi
    done
  fi

  # Remove NVM
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would remove ~/.nvm and related shell lines"
  else
    rm -rf "$HOME/.nvm" && log_info "Removed ~/.nvm"
    for pf in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
      if [ -f "$pf" ]; then
        sed -i.bak '/NVM_DIR/d; /nvm.sh/d; /nvm bash_completion/d' "$pf" || true
      fi
    done
  fi

  # Remove Go (tarball)
  if [ -d "/usr/local/go" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would remove /usr/local/go"
    else
      run_as_root rm -rf /usr/local/go && log_info "Removed /usr/local/go"
    fi
  fi

  # Remove Starship config
  if [ -f "$HOME/.config/starship.toml" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would remove ~/.config/starship.toml"
    else
      rm -f "$HOME/.config/starship.toml" && log_info "Removed starship config"
    fi
  fi

  # Remove Zsh plugins
  if [ -d "$HOME/.local/share/zsh/plugins" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would remove zsh plugins in ~/.local/share/zsh/plugins"
    else
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-autosuggestions" || true
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting" || true
      log_info "Removed zsh plugins"
    fi
  fi

  # Note: personal projects (e.g. Glowkey) are managed outside this installer

  # Remove user from docker group
  if id -nG "$USER" | grep -qw docker; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would remove $USER from docker group"
    else
      run_as_root gpasswd -d "$USER" docker && log_info "Removed $USER from docker group"
    fi
  fi

  # Disable docker service
  if systemctl list-unit-files | grep -q "docker.service"; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would disable and stop docker service"
    else
      run_as_root systemctl disable --now docker || true
      log_info "Disabled docker service"
    fi
  fi

  # Remove yay on Arch
  if [ "${PKG_MANAGER:-}" = "pacman" ]; then
    if command_exists yay; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[DRY RUN] Would remove yay package"
      else
        run_as_root pacman -Rns --noconfirm yay || true
        log_info "Removed yay"
      fi
    fi
  fi

  # Remove Android Studio flatpak
  if command_exists flatpak; then
    if flatpak list --app | grep -q com.google.AndroidStudio; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[DRY RUN] Would uninstall Android Studio flatpak"
      else
        run_as_root flatpak uninstall --delete-data -y com.google.AndroidStudio || true
        log_info "Removed Android Studio flatpak"
      fi
    fi
  fi

  # Remove log
  if [ -f "$LOG_FILE" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would remove $LOG_FILE"
    else
      rm -f "$LOG_FILE" && log_info "Removed workflow log"
    fi
  fi
  
  # Attempt to remove snapd during uninstall
  if type -t remove_snapd >/dev/null 2>&1; then
    remove_snapd || log_warning "snapd removal during uninstall failed or skipped"
  fi

  # Attempt to remove podman during uninstall
  if type -t remove_podman >/dev/null 2>&1; then
    remove_podman || log_warning "podman removal during uninstall failed or skipped"
  fi

  log_success "Uninstall finished (dry-run=${DRY_RUN:-false})"
}
