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
      echo "Uso: $0 [--dry-run] [--yes] [uninstall|vscode|git-config]"
      echo ""
      echo "  --dry-run    Simula as ações sem fazer alterações"
      echo "  --yes        Modo não-interativo"
      echo "  uninstall    Reverte a instalação"
      echo "  vscode       Instala apenas o VS Code"
      echo "  git-config   Configura o Git"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

export DRY_RUN AUTO_YES

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

source "$REPO_ROOT/lib/core.sh"
source "$REPO_ROOT/lib/detect.sh"

if [ "${1:-}" = "uninstall" ] || [ "${1:-}" = "--undo" ]; then
  detect_distro
  WORKFLOW_DIR="$REPO_ROOT/workflows/$DISTRO_ID"
  source "$WORKFLOW_DIR/main.sh"
  uninstall
  exit 0
fi

detect_distro

WORKFLOW_DIR="$REPO_ROOT/workflows/$DISTRO_ID"
if [ ! -d "$WORKFLOW_DIR" ]; then
  log_error "Nenhum workflow disponível para $DISTRO_NAME ($DISTRO_ID)"
  exit 1
fi

source "$WORKFLOW_DIR/main.sh"

case "${1:-}" in
  vscode)
    install_vscode
    ;;
  git-config)
    configure_git
    ;;
  *)
    main
    ;;
esac
