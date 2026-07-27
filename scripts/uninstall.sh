#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

uninstall() {
  log_info "Executando desinstalação (dry-run=${DRY_RUN:-false})"

  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local repo_root="$(cd "$script_dir/.." && pwd)"

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
        log_info "[SIMULAÇÃO] Removeria fonte $base de ~/.local/share/fonts"
      else
        rm -f "$HOME/.local/share/fonts/$base" && log_info "Fonte $base removida"
      fi
    done
  fi

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[SIMULAÇÃO] Removeria ~/.nvm e linhas relacionadas dos arquivos shell"
  else
    rm -rf "$HOME/.nvm" && log_info "~/.nvm removido"
    for pf in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
      if [ -f "$pf" ]; then
        sed -i '/NVM_DIR/d; /nvm.sh/d; /nvm bash_completion/d' "$pf" || true
        rm -f "${pf}.bak" 2>/dev/null || true
      fi
    done
  fi

  if [ -d "/usr/local/go" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria /usr/local/go"
    else
      run_as_root rm -rf /usr/local/go && log_info "/usr/local/go removido"
    fi
  fi

  if command_exists go; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria pacote Go da distro"
    else
      case "$PKG_MANAGER" in
        apt)
          run_as_root apt-get purge -y golang golang-go || true
          ;;
        pacman)
          run_as_root pacman -Rns --noconfirm go || true
          ;;
        dnf)
          run_as_root dnf remove -y golang || true
          ;;
      esac
      log_info "Pacote Go da distro removido"
    fi
  fi

  if [ -f "$HOME/.config/starship.toml" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria ~/.config/starship.toml"
    else
      rm -f "$HOME/.config/starship.toml" && log_info "Configuração do starship removida"
    fi
  fi

  if [ -d "$HOME/.local/share/zsh/plugins" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria plugins do zsh em ~/.local/share/zsh/plugins"
    else
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-autosuggestions" || true
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting" || true
      log_info "Plugins do zsh removidos"
    fi
  fi

  if id -nG "$USER" | grep -qw docker; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria $USER do grupo docker"
    else
      run_as_root gpasswd -d "$USER" docker && log_info "$USER removido do grupo docker"
    fi
  fi

  if systemctl list-unit-files | grep -q "docker.service"; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Desabilitaria e pararia o serviço docker"
      log_info "[SIMULAÇÃO] Removeria pacotes do docker"
    else
      run_as_root systemctl disable --now docker || true
      log_info "Serviço docker desabilitado"
      case "$PKG_MANAGER" in
        apt)
          run_as_root apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
          run_as_root rm -rf /var/lib/docker /var/lib/containerd || true
          ;;
        pacman)
          run_as_root pacman -Rns --noconfirm docker || true
          run_as_root pacman -Rns --noconfirm docker-compose 2>/dev/null || true
          run_as_root pacman -Rns --noconfirm docker-cli 2>/dev/null || true
          run_as_root rm -rf /var/lib/docker /var/lib/containerd || true
          ;;
        dnf)
          run_as_root dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
          run_as_root rm -rf /var/lib/docker /var/lib/containerd || true
          ;;
      esac
      log_info "Pacotes do docker removidos"
    fi
  fi

  if [ "${PKG_MANAGER:-}" = "pacman" ]; then
    if command_exists yay; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[SIMULAÇÃO] Removeria pacote yay"
      else
        run_as_root pacman -Rns --noconfirm yay || true
        log_info "yay removido"
      fi
    fi
  fi

  if command_exists flatpak; then
    if flatpak list --app | grep -q com.google.AndroidStudio; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[SIMULAÇÃO] Desinstalaria Android Studio flatpak"
      else
        run_as_root flatpak uninstall --delete-data -y com.google.AndroidStudio || true
        log_info "Android Studio flatpak removido"
      fi
    fi
  fi

  if [ -f "$LOG_FILE" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria $LOG_FILE"
    else
      rm -f "$LOG_FILE" && log_info "Log do workflow removido"
    fi
  fi

  if type -t remove_snapd >/dev/null 2>&1; then
    remove_snapd || log_warning "Remoção do snapd durante desinstalação falhou ou foi ignorada"
  fi

  if type -t remove_podman >/dev/null 2>&1; then
    remove_podman || log_warning "Remoção do podman durante desinstalação falhou ou foi ignorada"
  fi

  log_success "Desinstalação concluída (dry-run=${DRY_RUN:-false})"
}