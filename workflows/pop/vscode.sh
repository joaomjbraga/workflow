#!/usr/bin/env bash
set -Eeuo pipefail

install_vscode() {
  if command_exists code; then
    log_info "Visual Studio Code já está instalado: $(code --version 2>/dev/null | head -n1)"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria Visual Studio Code pelo repositório oficial da Microsoft"
    log_info "[SIMULAÇÃO] Instalaria dependências: wget gpg apt-transport-https"
    log_info "[SIMULAÇÃO] Criaria /etc/apt/keyrings/packages.microsoft.gpg"
    log_info "[SIMULAÇÃO] Criaria /etc/apt/sources.list.d/vscode.sources"
    log_info "[SIMULAÇÃO] Instalaria pacote code"
    return 0
  fi

  log_info "Instalando dependências do VS Code"

  run_as_root apt-get install -y \
    wget \
    gpg \
    apt-transport-https || {
      log_warning "Falha ao instalar dependências do VS Code"
      return 1
    }

  log_info "Configurando chave GPG da Microsoft"

  run_as_root install -m 0755 -d /etc/apt/keyrings

  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    run_as_root tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null || {
      log_warning "Falha ao adicionar chave GPG da Microsoft"
      return 1
    }

  run_as_root chmod 644 /etc/apt/keyrings/packages.microsoft.gpg

  local arch
  arch="$(dpkg --print-architecture)"

  log_info "Configurando repositório oficial do VS Code"

  run_as_root tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $arch
Signed-By: /etc/apt/keyrings/packages.microsoft.gpg
EOF

  log_info "Atualizando repositórios"

  run_as_root apt-get update -qq || {
    log_warning "Falha ao atualizar repositórios"
    return 1
  }

  log_info "Instalando Visual Studio Code"

  run_as_root apt-get install -y code || {
    log_warning "Falha ao instalar Visual Studio Code"
    return 1
  }

  if command_exists code; then
    log_success "Visual Studio Code instalado: $(code --version 2>/dev/null | head -n1)"
  else
    log_warning "VS Code instalado, mas comando code não encontrado"
    return 1
  fi
}