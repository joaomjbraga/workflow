#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_nvm_and_node() {
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -d "$HOME/.nvm" ] || command_exists nvm; then
      log_info "NVM already installed"
    else
      log_info "[DRY RUN] Would install NVM via official installer"
      log_info "[DRY RUN] Would run: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash"
    fi
    log_info "[DRY RUN] Would source NVM and install Node.js 22 (nvm install 22; nvm alias default 22)"
    return 0
  fi

  if [ -d "$HOME/.nvm" ] || command_exists nvm; then
    log_info "NVM already installed"
  else
    log_info "Installing NVM"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash || return 1
  fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  log_info "Installing Node.js 22 via NVM"
  nvm install 22 || log_warning "nvm install 22 failed"
  nvm alias default 22 || true
  nvm use default || true

  log_info "Node: $(node --version 2>/dev/null || echo 'not found')"
}
