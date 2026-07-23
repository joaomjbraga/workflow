#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Detect and remove snapd safely. Respects DRY_RUN and AUTO_YES.
remove_snapd() {
  if ! command_exists snap || ! dpkg -s snapd >/dev/null 2>&1 && ! command_exists snapctl; then
    log_info "snapd not present or already removed"
    return 0
  fi

  log_info "snapd detected on system"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would remove snapd and cleanup snaps"
    return 0
  fi

  if [ "${AUTO_YES:-false}" != "true" ]; then
    log_info "Skipping snapd removal (use --yes to allow removals)"
    return 0
  fi

  # Stop snap services and remove snaps
  run_as_root systemctl stop snapd.service snapd.socket || true
  run_as_root snap list --all 2>/dev/null | awk 'NR>1 {print $1}' | xargs -r -n1 -I{} run_as_root snap remove "{}" || true

  # Remove snapd package via package manager
  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get purge -y snapd || true
      run_as_root rm -rf /var/cache/snapd /snap || true
      ;;
    pacman)
      run_as_root pacman -Rns --noconfirm snapd || true
      run_as_root rm -rf /var/cache/snapd /snap || true
      ;;
    dnf)
      run_as_root dnf remove -y snapd || true
      run_as_root rm -rf /var/cache/snapd /snap || true
      ;;
    *)
      log_warning "Unknown package manager; please remove snapd manually"
      ;;
  esac

  # Mask and disable services
  run_as_root systemctl disable --now snapd.socket snapd.service || true
  run_as_root systemctl daemon-reload || true

  log_success "snapd removal complete (or simulated)"
}

export -f remove_snapd
