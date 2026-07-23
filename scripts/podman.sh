#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# source docker helpers to allow reconfiguration
if [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker.sh" ]; then
  # shellcheck disable=SC1090
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker.sh"
fi

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

  # Confirm interactively even if --yes; skip prompt if non-interactive (no TTY)
  if [ -t 0 ]; then
    read -rp "Confirm removal of podman and all its containers/images (this is irreversible)? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "User declined podman removal"
      return 0
    fi
  else
    if [ "${AUTO_YES:-false}" != "true" ]; then
      log_info "Non-interactive shell and --yes not provided; skipping podman removal"
      return 0
    fi
    # In non-interactive + AUTO_YES, proceed without prompt
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

  # Ensure Docker is installed and running (user prefers Docker)
  if ! command_exists docker; then
    log_info "Docker not found; installing Docker to replace Podman"
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would install docker via $PKG_MANAGER"
    else
      install_package docker || log_warning "Failed to install docker"
    fi
  fi

  if command_exists docker; then
    log_info "Enabling and starting Docker service"
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] sudo systemctl enable --now docker"
    else
      run_as_root systemctl enable --now docker || log_warning "Failed to enable/start docker"
    fi

    # Add user to docker group if possible
    TARGET_USER="${SUDO_USER:-${USER:-}}"
    if [ -z "$TARGET_USER" ]; then
      TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")
    fi
    if [ -n "$TARGET_USER" ]; then
      if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "[DRY RUN] Would add $TARGET_USER to docker group"
      else
        run_as_root usermod -aG docker "$TARGET_USER" || log_warning "Could not add $TARGET_USER to docker group"
        log_info "Added $TARGET_USER to docker group (may require relogin)"
      fi
    fi
  fi
}

export -f remove_podman
