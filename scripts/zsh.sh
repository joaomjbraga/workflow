#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_starship() {
  if command_exists starship; then
    log_info "Starship já está instalado"
    return 0
  fi

  curl -sS https://starship.rs/install.sh | sh -s -- -y || log_warning "Falha ao instalar Starship"

  mkdir -p "$HOME/.config"
  if [ ! -f "$HOME/.config/starship.toml" ]; then
    cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/starship.toml" "$HOME/.config/starship.toml" || true
  fi
}

configure_zsh() {
  install_package zsh || true

  local plugin_dir="$HOME/.local/share/zsh/plugins"
  mkdir -p "$plugin_dir"

  if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Clonaria zsh-autosuggestions para $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions" || true
    fi
  fi
  if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Clonaria zsh-syntax-highlighting para $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting" || true
    fi
  fi

  local target="$HOME/.zshrc"
  if [ -f "$target" ]; then
    log_info "$target já existe — preservando e garantindo que os trechos estejam presentes"
  else
    cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/zshrc" "$target"
  fi

  sed -i '/up-line-or-beginning-search/d; /down-line-or-beginning-search/d' "$target" 2>/dev/null || true
  rm -f "${target}.bak" 2>/dev/null || true

  local bash_target="$HOME/.bashrc"
  if [ -f "$bash_target" ]; then
    log_info "$bash_target já existe — preservando e garantindo que as configurações de cor para ls estejam presentes"
  else
    cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/bashrc" "$bash_target"
  fi
  if ! grep -q "Colorized ls" "$bash_target" 2>/dev/null; then
    cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/bashrc" >>"$bash_target"
  fi

  grep -q "history-beginning-search-backward" "$target" || printf "bindkey '^[[A' history-beginning-search-backward\n" >>"$target"
  grep -q "history-beginning-search-forward" "$target" || printf "bindkey '^[[B' history-beginning-search-forward\n" >>"$target"

  if ! grep -q "CLICOLOR" "$target" 2>/dev/null; then
    cat <<'EOF' >>"$target"

# Restaurar cores de diretório no ls e no completion
export CLICOLOR=1
export LS_COLORS='di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;32:bd=1;34:cd=1;34:su=1;31:sg=1;31:tw=1;33:ow=1;33'
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
EOF
  fi

  grep -q "alias ls='ls --color=auto'" "$target" || printf "alias ls='ls --color=auto'\n" >>"$target"
  grep -q "alias ll='ls -alF --color=auto'" "$target" || printf "alias ll='ls -alF --color=auto'\n" >>"$target"
  grep -q "alias la='ls -A --color=auto'" "$target" || printf "alias la='ls -A --color=auto'\n" >>"$target"
  grep -q "alias l='ls -CF --color=auto'" "$target" || printf "alias l='ls -CF --color=auto'\n" >>"$target"

  grep -q "zsh-autosuggestions" "$target" || printf "source %s/zsh-autosuggestions/zsh-autosuggestions.zsh\n" "$plugin_dir" >>"$target"
  grep -q "zsh-syntax-highlighting" "$target" || printf "source %s/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n" "$plugin_dir" >>"$target"

  if [ "$(basename "$SHELL")" != "zsh" ]; then
    if command_exists chsh && command_exists zsh; then
      log_info "Alterando shell padrão para zsh do usuário $USER"
      run_as_root chsh -s "$(command -v zsh)" "$USER" || log_warning "chsh falhou; você pode precisar executá-lo manualmente"
    fi
  else
    log_info "Zsh já é o shell padrão"
  fi
}