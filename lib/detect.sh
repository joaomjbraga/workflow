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
    arch|manjaro)
      PKG_MANAGER="pacman"
      ;;
    *)
      log_error "Distribuição não suportada: $DISTRO_NAME ($DISTRO_ID)"
      log_error "Por enquanto apenas Arch Linux e derivados são suportados."
      exit 1
      ;;
  esac

  export DISTRO_ID DISTRO_NAME PKG_MANAGER
  log_info "Distribuição detectada: $DISTRO_NAME ($DISTRO_ID)"
}
