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
      log_error "Distribuição não suportada: $DISTRO_NAME ($DISTRO_ID)"
      exit 1
      ;;
  esac

  export DISTRO_ID DISTRO_NAME PKG_MANAGER
  log_info "Distribuição detectada: $DISTRO_NAME ($DISTRO_ID), gerenciador de pacotes: $PKG_MANAGER"
}