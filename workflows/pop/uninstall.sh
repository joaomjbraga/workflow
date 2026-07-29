#!/usr/bin/env bash
set -Eeuo pipefail

uninstall() {
  log_info "Executando desinstalação (dry-run=${DRY_RUN:-false})"

  local font_dir=""
  if [ -d "$REPO_ROOT/font" ]; then
    font_dir="$REPO_ROOT/font"
  elif [ -d "$REPO_ROOT/fonts" ]; then
    font_dir="$REPO_ROOT/fonts"
  fi
  if [ -n "$font_dir" ]; then
    for f in "$font_dir"/*.{ttf,otf}; do
      [ -e "$f" ] || continue
      local base
      base=$(basename "$f")
      if [ "$DRY_RUN" = "true" ]; then
        log_info "[SIMULAÇÃO] Removeria fonte $base de ~/.local/share/fonts"
      else
        rm -f "$HOME/.local/share/fonts/$base" && log_info "Fonte $base removida"
      fi
    done
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Removeria ~/.nvm e linhas relacionadas dos arquivos shell"
  else
    rm -rf "$HOME/.nvm" && log_info "~/.nvm removido"
    for pf in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
      if [ -f "$pf" ]; then
        sed -i '/NVM_DIR/d; /nvm.sh/d; /nvm bash_completion/d' "$pf" || true
      fi
    done
  fi

  if command_exists go; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria pacote golang-go"
    else
      run_as_root apt-get remove --purge -y golang-go || true
      log_info "Pacote golang-go removido"
    fi
  fi

  if [ -f "$HOME/.config/starship.toml" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria ~/.config/starship.toml"
    else
      rm -f "$HOME/.config/starship.toml" && log_info "Configuração do starship removida"
    fi
  fi

  if [ -d "$HOME/.local/share/zsh/plugins" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria plugins do zsh em ~/.local/share/zsh/plugins"
    else
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-autosuggestions" || true
      rm -rf "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting" || true
      log_info "Plugins do zsh removidos"
    fi
  fi

  if id -nG "$USER" | grep -qw docker; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria $USER do grupo docker"
    else
      run_as_root gpasswd -d "$USER" docker && log_info "$USER removido do grupo docker"
    fi
  fi

  if systemctl list-unit-files | grep -q "docker.service"; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Desabilitaria e pararia o serviço docker"
      log_info "[SIMULAÇÃO] Removeria pacotes do docker e repositório oficial"
    else
      run_as_root systemctl disable --now docker || true
      run_as_root apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
      run_as_root rm -rf /var/lib/docker /var/lib/containerd || true
      run_as_root rm -f /etc/apt/sources.list.d/docker.list || true
      run_as_root rm -f /etc/apt/keyrings/docker.gpg || true
      run_as_root apt-get update -qq || true
      log_info "Pacotes do docker e repositório removidos"
    fi
  fi

  if command_exists code; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria code (VS Code)"
    else
      run_as_root apt-get remove --purge -y code || true
      log_info "VS Code removido"
    fi
  fi

  if command_exists google-chrome-stable || command_exists google-chrome; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria google-chrome"
    else
      run_as_root apt-get remove --purge -y google-chrome-stable || true
      log_info "Google Chrome removido"
    fi
  fi

  if command_exists android-studio; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria android-studio"
    else
      if flatpak list android-studio >/dev/null 2>&1; then
        flatpak uninstall -y com.android.Studio || true
      elif [ -d /opt/android-studio ]; then
        rm -rf /opt/android-studio || true
      fi
      log_info "Android Studio removido"
    fi
  fi

  if [ -f "$LOG_FILE" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria $LOG_FILE"
    else
      rm -f "$LOG_FILE" && log_info "Log do workflow removido"
    fi
  fi

  log_success "Desinstalação concluída (dry-run=${DRY_RUN:-false})"
}