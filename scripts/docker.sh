#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_docker() {
  if command_exists docker; then
    log_info "Docker already installed"
  else
    log_info "Installing Docker packages"
    # Use install_package which may resolve distro-specific names
    install_package docker || log_warning "Failed to install docker package"
    install_package docker-compose || log_warning "Failed to install docker-compose package"
  fi

  run_as_root systemctl enable --now docker || log_warning "Failed to enable/start docker"

  # Add user to docker group
  if id -nG "$USER" | grep -qw docker; then
    log_info "User $USER already in docker group"
  else
    run_as_root usermod -aG docker "$USER" || log_warning "Could not add $USER to docker group"
    log_info "Added $USER to docker group (may require relogin)"
  fi
}
