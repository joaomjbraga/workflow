#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=false
while (("$#")); do
  case "$1" in
    --dry-run)
      DRY_RUN=true
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/distro.sh"
source "$SCRIPT_DIR/scripts/packages.sh"
source "$SCRIPT_DIR/scripts/docker.sh"
source "$SCRIPT_DIR/scripts/node.sh"
source "$SCRIPT_DIR/scripts/zsh.sh"
source "$SCRIPT_DIR/scripts/fonts.sh"
source "$SCRIPT_DIR/scripts/android.sh"
source "$SCRIPT_DIR/scripts/applications.sh"
# source arch and go after packages so they can override defaults when needed
source "$SCRIPT_DIR/scripts/arch.sh" || true
source "$SCRIPT_DIR/scripts/go.sh" || true

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

  if [[ "$PKG_MANAGER" == "pacman" ]]; then
    log_info "Applying Arch-specific configuration"
    configure_arch
  fi

  log_success "Bootstrap completed. Summary:"
  verify_installation

  log_info "If you were added to the docker group, a session restart may be required."
}

main "$@"
