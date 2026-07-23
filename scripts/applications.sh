#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

install_applications() {
  # scrcpy
  if command_exists scrcpy; then
    log_info "scrcpy already installed"
  else
    log_info "Installing scrcpy"
    local pkgname
    pkgname=$(resolve_pkg_name scrcpy)
    install_package "$pkgname" || log_warning "scrcpy may not be available in distro repos"
  fi

  # Glowkey
  # Glowkey intentionally removed from installer; it's managed separately by the user.
}
