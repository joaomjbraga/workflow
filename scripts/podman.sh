#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Detect and remove podman safely. Respects DRY_RUN and AUTO_YES.
remove_podman() {
  if ! command_exists podman; then
    log_info "podman not present"
    return 0
  fi

  log_info "podman detected on system"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would remove podman and cleanup containers/images/volumes"
    return 0
  fi

  if [ "${AUTO_YES:-false}" != "true" ]; then
    log_info "Skipping podman removal (use --yes to allow removals)"
    return 0
  fi

  # Stop services
  run_as_root systemctl stop podman.socket podman.service || true

  # Remove all containers/images/volumes (best-effort)
  if command_exists podman; then
    run_as_root podman ps -a -q | xargs -r -n1 podman rm -f || true
    run_as_root podman images -q | xargs -r -n1 podman rmi -f || true
    run_as_root podman volume ls -q | xargs -r -n1 podman volume rm -f || true
  fi

  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get purge -y podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    pacman)
      run_as_root pacman -Rns --noconfirm podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    dnf)
      run_as_root dnf remove -y podman || true
      run_as_root rm -rf /var/lib/containers /var/lib/podman || true
      ;;
    *)
      log_warning "Unknown package manager; please remove podman manually"
      ;;
  esac

  run_as_root systemctl disable --now podman.socket podman.service || true
  run_as_root systemctl daemon-reload || true

  log_success "podman removal complete (or simulated)"
}

export -f remove_podman
