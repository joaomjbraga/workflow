#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=false
AUTO_YES=false
while (("$#")); do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --yes|--assume-yes|-y)
      AUTO_YES=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--dry-run]"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

export DRY_RUN
export AUTO_YES

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If the script is executed from inside scripts/ (edge cases), normalize to repo root
if [ -d "$BASE_DIR/scripts" ] && [ -f "$BASE_DIR/install.sh" ]; then
  REPO_ROOT="$BASE_DIR"
else
  REPO_ROOT="$(cd "$BASE_DIR/.." && pwd)"
fi

SCRIPTS_DIR="$REPO_ROOT/scripts"
source "$SCRIPTS_DIR/common.sh"
source "$SCRIPTS_DIR/distro.sh"
source "$SCRIPTS_DIR/packages.sh"
source "$SCRIPTS_DIR/docker.sh"
source "$SCRIPTS_DIR/node.sh"
source "$SCRIPTS_DIR/zsh.sh"
source "$SCRIPTS_DIR/fonts.sh"
source "$SCRIPTS_DIR/android.sh"
source "$SCRIPTS_DIR/applications.sh"
source "$SCRIPTS_DIR/logging.sh" || true
source "$SCRIPTS_DIR/snap.sh" || true
source "$SCRIPTS_DIR/vscode.sh" || true
source "$SCRIPTS_DIR/git.sh" || true
# source arch and go after packages so they can override defaults when needed
source "$SCRIPTS_DIR/arch.sh" || true
source "$SCRIPTS_DIR/go.sh" || true
source "$SCRIPTS_DIR/uninstall.sh" || true

main() {
  if [ "$DRY_RUN" = true ]; then
    log_info "Running in DRY-RUN mode: no changes will be made"
  fi

  log_info "Detecting distribution"
  detect_distro

  log_info "Installing base dependencies"
  install_base_dependencies

  log_info "Installing Docker"
  install_docker

  log_info "Installing Go (if supported by distro packages or tarball fallback)"
  install_go || log_warning "Go installation failed or not supported"

  log_info "Installing scrcpy and other applications"
  install_applications

  log_info "Installing NVM and Node.js"
  install_nvm_and_node

  log_info "Installing Starship and configuring Zsh"
  install_starship
  configure_zsh

  log_info "Installing fonts"
  install_fonts

  log_info "Installing logrotate config (optional)"
  install_logrotate_config || log_warning "logrotate install failed or skipped"

  log_info "Installing Visual Studio Code (stable)"
  install_vscode || log_warning "VS Code installation failed or skipped"

  if [[ "$PKG_MANAGER" == "pacman" ]]; then
    log_info "Applying Arch-specific configuration"
    configure_arch
  fi

  log_info "Checking for snapd and removing if requested"
  remove_snapd || log_warning "snapd removal failed or skipped"

  log_success "Bootstrap completed. Summary:"
  verify_installation

  log_info "If you were added to the docker group, a session restart may be required."
}

# If user requested uninstall
if [ "${1:-}" = "uninstall" ] || [ "${1:-}" = "--undo" ]; then
  uninstall
  exit 0
fi

# If user requested only VS Code
if [ "${1:-}" = "vscode" ]; then
  install_vscode
  exit 0
fi

# If user requested only git configuration
if [ "${1:-}" = "git-config" ]; then
  configure_git
  exit 0
fi

main "$@"
