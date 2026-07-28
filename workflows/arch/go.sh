#!/usr/bin/env bash
set -Eeuo pipefail

install_go() {
  if command_exists go; then
    log_info "Go já está instalado: $(go version 2>/dev/null)"
    return 0
  fi

  log_info "Instalando Go via pacman"
  install_package go || {
    log_warning "Falha ao instalar Go via pacman"
    return 1
  }
}
