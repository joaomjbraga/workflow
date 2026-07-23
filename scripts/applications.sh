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
  if command_exists glowkey; then
    log_info "Glowkey already available"
  else
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would check and install Glowkey from https://github.com/joaomjbraga/glowkey.git"
    else
      if [ -d "$REPO_ROOT/glowkey" ] || git ls-remote --exit-code https://github.com/joaomjbraga/glowkey.git >/dev/null 2>&1; then
        log_info "Installing Glowkey from repository"
        local td
        td=$(temp_dir)
        git clone https://github.com/joaomjbraga/glowkey.git "$td/glowkey" || { log_warning "Could not clone glowkey"; return 0; }
        (cd "$td/glowkey" && ./install.sh) || log_warning "Glowkey install script failed"
        rm -rf "$td"
      else
        log_warning "Glowkey repo not reachable; skipping"
      fi
    fi
  fi
}
