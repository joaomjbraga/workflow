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
      log_info "[SIMULAÇÃO] Removeria pacote go"
    else
      run_as_root pacman -Rns --noconfirm go || true
      log_info "Pacote go removido"
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
      log_info "[SIMULAÇÃO] Removeria pacotes do docker"
    else
      run_as_root systemctl disable --now docker || true
      run_as_root pacman -Rns --noconfirm docker docker-compose 2>/dev/null || true
      run_as_root rm -rf /var/lib/docker /var/lib/containerd || true
      log_info "Pacotes do docker removidos"
    fi
  fi

  if systemctl list-unit-files | grep -q "power-profiles-daemon.service"; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Desabilitaria e pararia power-profiles-daemon"
    else
      run_as_root systemctl disable --now power-profiles-daemon || true
      log_info "power-profiles-daemon desabilitado"
    fi
  fi

  if command_exists powerprofilesctl; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria power-profiles-daemon"
    else
      run_as_root pacman -Rns --noconfirm power-profiles-daemon 2>/dev/null || true
      log_info "power-profiles-daemon removido"
    fi
  fi

  if command_exists yay; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria pacote yay"
    else
      run_as_root pacman -Rns --noconfirm yay || true
      log_info "yay removido"
    fi
  fi

  if command_exists code; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria visual-studio-code-bin"
    else
      run_as_root pacman -Rns --noconfirm visual-studio-code-bin 2>/dev/null || true
      log_info "VS Code removido"
    fi
  fi

  if command_exists google-chrome-stable || command_exists google-chrome; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Removeria google-chrome"
    else
      run_as_root pacman -Rns --noconfirm google-chrome 2>/dev/null || true
      log_info "Google Chrome removido"
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
