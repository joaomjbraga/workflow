#!/usr/bin/env bash
set -Eeuo pipefail

install_starship() {
  if command_exists starship; then
    log_info "Starship já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria Starship via script oficial"
    return 0
  fi

  curl -sS https://starship.rs/install.sh | sh -s -- -y || log_warning "Falha ao instalar Starship"

  local config_dir="$REPO_ROOT/config"
  mkdir -p "$HOME/.config"
  if [ ! -f "$HOME/.config/starship.toml" ] && [ -f "$config_dir/starship.toml" ]; then
    cp "$config_dir/starship.toml" "$HOME/.config/starship.toml" || true
  fi
}

configure_zsh() {
  install_package zsh || true

  local plugin_dir="$HOME/.local/share/zsh/plugins"
  mkdir -p "$plugin_dir"

  if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Clonaria zsh-autosuggestions para $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions" || true
    fi
  fi
  if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Clonaria zsh-syntax-highlighting para $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting" || true
    fi
  fi

  local config_dir="$REPO_ROOT/config"
  local target="$HOME/.zshrc"

  if [ ! -f "$target" ]; then
    if [ -f "$config_dir/zshrc" ]; then
      cp "$config_dir/zshrc" "$target"
    fi
  else
    log_info "$target já existe — garantindo que os trechos estejam presentes"
  fi

  local bash_target="$HOME/.bashrc"
  if [ ! -f "$bash_target" ]; then
    if [ -f "$config_dir/bashrc" ]; then
      cp "$config_dir/bashrc" "$bash_target"
    fi
  fi
  if [ -f "$config_dir/bashrc" ] && ! grep -q "Colorized ls" "$bash_target" 2>/dev/null; then
    cat "$config_dir/bashrc" >>"$bash_target"
  fi

  local target_zshrc="$HOME/.zshrc"
  grep -q "history-beginning-search-backward" "$target_zshrc" || echo "bindkey '^[[A' history-beginning-search-backward" >>"$target_zshrc"
  grep -q "history-beginning-search-forward" "$target_zshrc" || echo "bindkey '^[[B' history-beginning-search-forward" >>"$target_zshrc"

  grep -q "alias ls='ls --color=auto'" "$target_zshrc" || echo "alias ls='ls --color=auto'" >>"$target_zshrc"
  grep -q "alias ll='ls -alF --color=auto'" "$target_zshrc" || echo "alias ll='ls -alF --color=auto'" >>"$target_zshrc"
  grep -q "alias la='ls -A --color=auto'" "$target_zshrc" || echo "alias la='ls -A --color=auto'" >>"$target_zshrc"
  grep -q "alias l='ls -CF --color=auto'" "$target_zshrc" || echo "alias l='ls -CF --color=auto'" >>"$target_zshrc"

  grep -q "zsh-autosuggestions" "$target_zshrc" || echo "source $plugin_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" >>"$target_zshrc"
  grep -q "zsh-syntax-highlighting" "$target_zshrc" || echo "source $plugin_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"$target_zshrc"

  if [ "$(basename "$SHELL")" != "zsh" ]; then
    if command_exists chsh && command_exists zsh; then
      log_info "Alterando shell padrão para zsh do usuário $USER"
      run_as_root chsh -s "$(command -v zsh)" "$USER" || log_warning "chsh falhou; você pode precisar executá-lo manualmente"
    fi
  else
    log_info "Zsh já é o shell padrão"
  fi
}
