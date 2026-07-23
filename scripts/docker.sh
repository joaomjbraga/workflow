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

  # Determine target user: prefer SUDO_USER, then USER, then current owner
  TARGET_USER="${SUDO_USER:-${USER:-}}
"
  if [ -z "$TARGET_USER" ]; then
    # try to detect an interactive user
    TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")
  fi

  if [ -n "$TARGET_USER" ]; then
    if id -nG "$TARGET_USER" | grep -qw docker; then
      log_info "User $TARGET_USER already in docker group"
    else
      run_as_root usermod -aG docker "$TARGET_USER" || log_warning "Could not add $TARGET_USER to docker group"
      log_info "Added $TARGET_USER to docker group (may require relogin)"
    fi
  else
    log_warning "Could not determine target user to add to docker group; skipping"
  fi
}
