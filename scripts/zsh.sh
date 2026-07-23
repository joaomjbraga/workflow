#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_starship() {
  if command_exists starship; then
    log_info "Starship already installed"
    return 0
  fi

  curl -sS https://starship.rs/install.sh | sh -s -- -y || log_warning "Starship install failed"

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
      log_info "[DRY RUN] Would clone zsh-autosuggestions to $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions" || true
    fi
  fi
  if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would clone zsh-syntax-highlighting to $plugin_dir"
    else
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir/zsh-syntax-highlighting" || true
    fi
  fi

  # Install minimal zshrc
  local target="$HOME/.zshrc"
  if [ -f "$target" ]; then
    log_info "$target exists — preserving and ensuring snippets are present"
  else
    cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/zshrc" "$target"
  fi

  # Remove legacy bindkeys that trigger zsh-syntax-highlighting warnings.
  sed -i.bak '/up-line-or-beginning-search/d; /down-line-or-beginning-search/d' "$target" 2>/dev/null || true

  # Ensure bash also gets colorized ls settings for the current shell.
  local bash_target="$HOME/.bashrc"
  if [ -f "$bash_target" ]; then
    log_info "$bash_target exists — preserving and ensuring ls color settings are present"
  else
    cp "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/bashrc" "$bash_target"
  fi
  if ! grep -q "Colorized ls" "$bash_target" 2>/dev/null; then
    cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/bashrc" >>"$bash_target"
  fi

  # Ensure safe history navigation bindings are present.
  grep -q "history-beginning-search-backward" "$target" || printf "bindkey '^[[A' history-beginning-search-backward\n" >>"$target"
  grep -q "history-beginning-search-forward" "$target" || printf "bindkey '^[[B' history-beginning-search-forward\n" >>"$target"

  # Ensure directory colors are enabled for existing zsh setups too.
  if ! grep -q "CLICOLOR" "$target" 2>/dev/null; then
    cat <<'EOF' >>"$target"

# Restore directory colors in ls and completion
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

  # Ensure plugin load lines exist (syntax highlighting last)
  grep -q "zsh-autosuggestions" "$target" || printf "source %s/zsh-autosuggestions/zsh-autosuggestions.zsh\n" "$plugin_dir" >>"$target"
  grep -q "zsh-syntax-highlighting" "$target" || printf "source %s/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n" "$plugin_dir" >>"$target"

  # Change shell if needed
  if [ "$(basename "$SHELL")" != "zsh" ]; then
    if command_exists chsh && command_exists zsh; then
      log_info "Changing default shell to zsh for user $USER"
      run_as_root chsh -s "$(command -v zsh)" "$USER" || log_warning "chsh failed; you may need to run it manually"
    fi
  else
    log_info "Zsh already default shell"
  fi
}
