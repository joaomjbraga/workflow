#!/usr/bin/env bash
set -Eeuo pipefail

install_chrome() {
  if command_exists google-chrome || command_exists google-chrome-stable; then
    log_info "Google Chrome já está instalado: $(google-chrome --version 2>/dev/null || google-chrome-stable --version 2>/dev/null)"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria Google Chrome pelo repositório oficial do Google"
    log_info "[SIMULAÇÃO] Instalaria dependências: wget gpg"
    log_info "[SIMULAÇÃO] Criaria chave GPG em /etc/apt/keyrings/google-chrome.gpg"
    log_info "[SIMULAÇÃO] Criaria /etc/apt/sources.list.d/google-chrome.sources"
    log_info "[SIMULAÇÃO] Instalaria pacote google-chrome-stable"
    return 0
  fi

  log_info "Instalando dependências do Google Chrome"

  run_as_root apt-get install -y \
    wget \
    gpg || {
      log_warning "Falha ao instalar dependências do Chrome"
      return 1
    }

  log_info "Configurando chave GPG do Google"

  run_as_root install -m 0755 -d /etc/apt/keyrings

  wget -qO- https://dl.google.com/linux/linux_signing_key.pub | \
    gpg --dearmor | \
    run_as_root tee /etc/apt/keyrings/google-chrome.gpg >/dev/null || {
      log_warning "Falha ao adicionar chave GPG do Google"
      return 1
    }

  run_as_root chmod 644 /etc/apt/keyrings/google-chrome.gpg

  local arch
  arch="$(dpkg --print-architecture)"

  log_info "Configurando repositório oficial do Google Chrome"

  run_as_root tee /etc/apt/sources.list.d/google-chrome.sources >/dev/null <<EOF
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: $arch
Signed-By: /etc/apt/keyrings/google-chrome.gpg
EOF

  log_info "Atualizando lista de pacotes"

  run_as_root apt-get update -qq || {
    log_warning "Falha ao atualizar repositórios"
    return 1
  }

  log_info "Instalando Google Chrome"

  run_as_root apt-get install -y google-chrome-stable || {
    log_warning "Falha ao instalar Google Chrome"
    return 1
  }

  if command_exists google-chrome || command_exists google-chrome-stable; then
    local version
    version="$(google-chrome --version 2>/dev/null || google-chrome-stable --version 2>/dev/null)"

    log_success "Google Chrome instalado: $version"
  else
    log_warning "Chrome instalado, mas comando não encontrado"
    return 1
  fi
}