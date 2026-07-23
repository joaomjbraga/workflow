#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_java() {
  if command_exists java; then
    local java_version
    java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    if [[ "$java_version" == 17* ]]; then
      log_info "OpenJDK 17 already installed"
      return 0
    fi
  fi

  log_info "Installing OpenJDK 17"
  install_package openjdk-17-jdk || log_warning "Failed to install OpenJDK 17"

  if command_exists java; then
    log_success "OpenJDK 17 installed successfully"
  else
    log_warning "OpenJDK 17 installation could not be verified"
  fi
}
