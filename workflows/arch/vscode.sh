#!/usr/bin/env bash
set -Eeuo pipefail

install_vscode() {
  if command_exists code; then
    log_info "Visual Studio Code já está instalado"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria visual-studio-code-bin via AUR"
    return 0
  fi

  log_info "Instalando Visual Studio Code via AUR"
  aur_install visual-studio-code-bin || log_warning "Falha ao instalar VS Code"
}
