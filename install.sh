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
      echo "Uso: $0 [--dry-run]"
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
source "$SCRIPTS_DIR/chrome.sh" || true
source "$SCRIPTS_DIR/git.sh" || true
source "$SCRIPTS_DIR/podman.sh" || true
source "$SCRIPTS_DIR/arch.sh" || true
source "$SCRIPTS_DIR/go.sh" || true
source "$SCRIPTS_DIR/java.sh" || true
source "$SCRIPTS_DIR/uninstall.sh" || true

main() {
  if [ "$DRY_RUN" = true ]; then
    log_info "Executando em modo SIMULAÇÃO: nenhuma alteração será feita"
  fi

  log_info "Detectando distribuição"
  detect_distro

  log_info "Instalando dependências base"
  install_base_dependencies

  log_info "Instalando Docker"
  install_docker || log_warning "Falha na instalação do Docker ou ignorada"

  log_info "Verificando podman e removendo se solicitado"
  remove_podman || log_warning "Remoção do podman falhou ou foi ignorada"

  log_info "Instalando Go (se suportado pelo gerenciador de pacotes ou fallback por tarball)"
  install_go || log_warning "Falha na instalação do Go ou não suportado"

  log_info "Instalando OpenJDK 17"
  install_java || log_warning "Falha na instalação do OpenJDK 17 ou não suportado"

  log_info "Instalando aplicativos"
  install_applications

  log_info "Instalando NVM e Node.js"
  install_nvm_and_node

  log_info "Instalando Starship e configurando Zsh"
  install_starship
  configure_zsh

  log_info "Instalando fontes"
  install_fonts

  log_info "Instalando configuração do logrotate (opcional)"
  install_logrotate_config || log_warning "Falha na instalação do logrotate ou ignorada"

  log_info "Instalando Visual Studio Code (stable)"
  install_vscode || log_warning "Falha na instalação do VS Code ou ignorada"

  log_info "Instalando Google Chrome (stable)"
  install_chrome || log_warning "Falha na instalação do Google Chrome ou ignorada"

  if [[ "$PKG_MANAGER" == "pacman" ]]; then
    log_info "Aplicando configuração específica do Arch"
    configure_arch
  fi

  log_info "Verificando snapd e removendo se solicitado"
  remove_snapd || log_warning "Remoção do snapd falhou ou foi ignorada"

  log_success "Bootstrap concluído. Resumo:"
  verify_installation

  log_info "Se você foi adicionado ao grupo docker, uma reinicialização de sessão pode ser necessária."
}

if [ "${1:-}" = "uninstall" ] || [ "${1:-}" = "--undo" ]; then
  uninstall
  exit 0
fi

if [ "${1:-}" = "vscode" ]; then
  install_vscode
  exit 0
fi

if [ "${1:-}" = "git-config" ]; then
  configure_git
  exit 0
fi

main "$@"