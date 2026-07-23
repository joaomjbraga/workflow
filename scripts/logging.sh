#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_logrotate_config() {
  local src_cfg="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/logrotate/workflow"
  if [ ! -f "$src_cfg" ]; then
    log_warning "No logrotate template found at $src_cfg"
    return 0
  fi

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would install logrotate config to /etc/logrotate.d/workflow"
    return 0
  fi

  if [ "${AUTO_YES:-false}" != "true" ]; then
    log_info "Skipping installing system logrotate config (use --yes to enable)"
    return 0
  fi

  run_as_root cp "$src_cfg" /etc/logrotate.d/workflow && run_as_root chmod 644 /etc/logrotate.d/workflow
  log_success "Installed /etc/logrotate.d/workflow"
}

export -f install_logrotate_config
