#!/usr/bin/env bash
set -Eeuo pipefail

install_base_dependencies() {
  apt_update

  local pkgs=(build-essential curl wget git zsh unzip ca-certificates)

  for p in "${pkgs[@]}"; do
    install_package "$p" || log_warning "Falha ao instalar $p"
  done
}

install_yay() {
  log_info "yay não é necessário no Pop!_OS — usando apt diretamente"
}