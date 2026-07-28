#!/usr/bin/env bash
set -Eeuo pipefail

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$WORKFLOW_DIR/../.." && pwd)"

source "$WORKFLOW_DIR/packages.sh"
source "$WORKFLOW_DIR/docker.sh"
source "$WORKFLOW_DIR/node.sh"
source "$WORKFLOW_DIR/zsh.sh"
source "$WORKFLOW_DIR/fonts.sh"
source "$WORKFLOW_DIR/android.sh"
source "$WORKFLOW_DIR/vscode.sh"
source "$WORKFLOW_DIR/chrome.sh"
source "$WORKFLOW_DIR/go.sh"
source "$WORKFLOW_DIR/java.sh"
source "$WORKFLOW_DIR/git.sh"
source "$WORKFLOW_DIR/tweaks.sh"
source "$WORKFLOW_DIR/uninstall.sh"

main() {
  if [ "$DRY_RUN" = "true" ]; then
    log_info "Executando em modo SIMULAÇÃO: nenhuma alteração será feita"
  fi

  log_info "Instalando dependências base"
  install_base_dependencies || log_warning "Falha nas dependências base"

  log_info "Instalando yay (helper AUR)"
  install_yay || log_warning "Falha ao instalar yay"

  log_info "Instalando Docker"
  install_docker || log_warning "Falha ao instalar Docker"

  log_info "Instalando Go"
  install_go || log_warning "Falha ao instalar Go"

  log_info "Instalando OpenJDK 17"
  install_java || log_warning "Falha ao instalar Java"

  log_info "Instalando NVM e Node.js"
  install_nvm_and_node || log_warning "Falha ao instalar NVM/Node"

  log_info "Instalando Starship e configurando Zsh"
  install_starship || log_warning "Falha ao instalar Starship"
  configure_zsh || log_warning "Falha ao configurar Zsh"

  log_info "Instalando fontes"
  install_fonts || log_warning "Falha ao instalar fontes"

  log_info "Instalando Android Studio"
  install_android_studio || log_warning "Falha ao instalar Android Studio"

  log_info "Instalando Visual Studio Code"
  install_vscode || log_warning "Falha ao instalar VS Code"

  log_info "Instalando Google Chrome"
  install_chrome || log_warning "Falha ao instalar Chrome"

  log_info "Aplicando ajustes específicos do Arch"
  arch_tweaks || log_warning "Falha nos ajustes Arch"

  log_info "Configurando Git"
  configure_git || log_warning "Falha ao configurar Git"

  log_success "Bootstrap concluído. Resumo:"
  verify_installation

  log_info "Se você foi adicionado ao grupo docker, uma reinicialização de sessão pode ser necessária."
}
