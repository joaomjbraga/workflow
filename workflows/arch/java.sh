#!/usr/bin/env bash
set -Eeuo pipefail

install_java() {
  if command_exists java; then
    local java_version
    java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    if [[ "$java_version" == 17* ]]; then
      log_info "OpenJDK 17 já está instalado"
      return 0
    fi
  fi

  log_info "Instalando OpenJDK 17"
  install_package jdk17-openjdk || log_warning "Falha ao instalar OpenJDK 17"

  if command_exists java; then
    log_success "OpenJDK 17 instalado com sucesso"
    return 0
  else
    log_warning "A instalação do OpenJDK 17 não pôde ser verificada"
    return 1
  fi
}
