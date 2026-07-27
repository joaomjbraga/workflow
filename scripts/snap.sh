#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

remove_snapd() {
  if ! command_exists snap || ! dpkg -s snapd >/dev/null 2>&1 && ! command_exists snapctl; then
    log_info "snapd não está presente ou já foi removido"
    return 0
  fi

  log_info "snapd detectado no sistema"
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[SIMULAÇÃO] Removeria snapd e limparia snaps"
    return 0
  fi

  if [ "${AUTO_YES:-false}" != "true" ]; then
    log_info "Ignorando remoção do snapd (use --yes para permitir remoções)"
    return 0
  fi

  run_as_root systemctl stop snapd.service snapd.socket || true
  run_as_root snap list --all 2>/dev/null | awk 'NR>1 {print $1}' | xargs -r -n1 -I{} run_as_root snap remove "{}" || true

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
      log_warning "Gerenciador de pacotes desconhecido; remova o snapd manualmente"
      ;;
  esac

  run_as_root systemctl disable --now snapd.socket snapd.service || true
  run_as_root systemctl daemon-reload || true

  log_success "Remoção do snapd concluída (ou simulada)"
}

export -f remove_snapd