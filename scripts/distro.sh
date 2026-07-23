#!/usr/bin/env bash
set -Eeuo pipefail

detect_distro() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_NAME="${NAME:-unknown}"
  else
    DISTRO_ID="unknown"
    DISTRO_NAME="unknown"
  fi

  case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|pop)
      PKG_MANAGER="apt"
      ;;
    arch|manjaro)
      PKG_MANAGER="pacman"
      ;;
    fedora)
      PKG_MANAGER="dnf"
      ;;
    *)
      log_error "Unsupported distribution: $DISTRO_NAME ($DISTRO_ID)"
      exit 1
      ;;
  esac

  export DISTRO_ID DISTRO_NAME PKG_MANAGER
  log_info "Detected distro: $DISTRO_NAME ($DISTRO_ID), package manager: $PKG_MANAGER"
}
