#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_nvm_and_node() {
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -d "$HOME/.nvm" ] || command_exists nvm; then
      log_info "NVM já está instalado"
    else
      log_info "[SIMULAÇÃO] Instalaria NVM via instalador oficial"
      log_info "[SIMULAÇÃO] Executaria: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash"
    fi
    log_info "[SIMULAÇÃO] Fontearia NVM e instalaria Node.js 22 (nvm install 22; nvm alias default 22)"
    return 0
  fi

  if [ -d "$HOME/.nvm" ] || command_exists nvm; then
    log_info "NVM já está instalado"
  else
    log_info "Instalando NVM"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash || return 1
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  log_info "Instalando Node.js 22 via NVM"
  nvm install 22 || log_warning "nvm install 22 falhou"
  nvm alias default 22 || true
  nvm use default || true

  log_info "Node: $(node --version 2>/dev/null || echo 'não encontrado')"
}

export -f install_nvm_and_node