#!/usr/bin/env bash
set -Eeuo pipefail

install_nvm_and_node() {
  local nvm_version="${NVM_VERSION:-v0.40.3}"
  local node_version="${NODE_VERSION:-22}"

  if [ "$DRY_RUN" = "true" ]; then
    if [ -d "$HOME/.nvm" ]; then
      log_info "NVM já está instalado"
    else
      log_info "[SIMULAÇÃO] Instalaria NVM ${nvm_version}"
      log_info "[SIMULAÇÃO] Executaria:"
      log_info "[SIMULAÇÃO] curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh | bash"
    fi

    log_info "[SIMULAÇÃO] Instalaria Node.js ${node_version}"
    log_info "[SIMULAÇÃO] nvm install ${node_version}"
    log_info "[SIMULAÇÃO] nvm alias default ${node_version}"

    return 0
  fi

  if [ ! -d "$HOME/.nvm" ]; then
    log_info "Instalando NVM ${nvm_version}"

    curl -o- \
      "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" \
      | bash || {
        log_warning "Falha ao instalar NVM"
        return 1
      }
  else
    log_info "NVM já está instalado"
  fi

  export NVM_DIR="$HOME/.nvm"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
  else
    log_warning "Arquivo nvm.sh não encontrado"
    return 1
  fi

  if ! type nvm >/dev/null 2>&1; then
    log_warning "NVM não carregado corretamente"
    return 1
  fi

  log_info "Instalando Node.js ${node_version}"

  nvm install "$node_version" || {
    log_warning "Falha ao instalar Node.js ${node_version}"
    return 1
  }

  nvm alias default "$node_version"

  nvm use default >/dev/null

  if command_exists corepack; then
    corepack enable || log_warning "Falha ao habilitar Corepack"
  fi

  log_success "Node instalado: $(node --version)"
  log_success "npm instalado: $(npm --version)"
}
