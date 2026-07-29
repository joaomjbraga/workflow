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

run_step() {
  local description="$1"
  local function_name="$2"

  log_info "$description"

  if ! "$function_name"; then
    log_warning "Falha: $description"
  fi
}

main() {
  if [ "$DRY_RUN" = "true" ]; then
    log_info "Executando em modo SIMULAÇÃO: nenhuma alteração será feita"
  fi

  log_info "========== Dependências =========="
  run_step "Instalando dependências base" install_base_dependencies

  log_info "========== Desenvolvimento =========="
  run_step "Configurando Git" configure_git
  run_step "Instalando Docker" install_docker
  run_step "Instalando Go" install_go
  run_step "Instalando OpenJDK 17" install_java
  run_step "Instalando NVM e Node.js" install_nvm_and_node

  log_info "========== Shell =========="
  run_step "Instalando Starship" install_starship
  run_step "Configurando Zsh" configure_zsh
  run_step "Instalando fontes" install_fonts

  log_info "========== Ferramentas =========="
  run_step "Instalando Visual Studio Code" install_vscode
  run_step "Instalando Google Chrome" install_chrome
  run_step "Instalando Android Studio" install_android_studio

  log_info "========== Sistema =========="
  run_step "Aplicando ajustes específicos do sistema" arch_tweaks

  log_info "========== Verificação =========="

  log_success "Bootstrap concluído."

  verify_installation || log_warning "Falha durante a verificação da instalação"

  if [ "${DOCKER_GROUP_CHANGED:-false}" = "true" ]; then
    log_info "Você foi adicionado ao grupo docker. Faça logout/login (ou reinicie a sessão) para que a alteração tenha efeito."
  fi
}