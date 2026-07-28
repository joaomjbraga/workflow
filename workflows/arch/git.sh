#!/usr/bin/env bash
set -Eeuo pipefail

configure_git() {
  log_info "Configurando Git (user.name e user.email)"

  if ! command_exists git; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Instalaria git"
    else
      install_package git || log_warning "Falha ao instalar git"
      if ! command_exists git; then
        log_warning "git não instalado; abortando configuração"
        return 1
      fi
    fi
  fi

  local cur_name cur_email
  cur_name=$(git config --global user.name 2>/dev/null || true)
  cur_email=$(git config --global user.email 2>/dev/null || true)

  local name email
  if [ "${AUTO_YES:-false}" = "true" ]; then
    name="${GIT_NAME:-$cur_name}"
    email="${GIT_EMAIL:-$cur_email}"
  else
    read -rp "Nome para Git (user.name) [${cur_name}]: " name
    name="${name:-$cur_name}"
    read -rp "Email para Git (user.email) [${cur_email}]: " email
    email="${email:-$cur_email}"
  fi

  if [ -z "$name" ] || [ -z "$email" ]; then
    log_warning "Nome ou email não fornecidos; pulando configuração de ~/.gitconfig"
    return 1
  fi

  local gitcfg="$HOME/.gitconfig"
  if [ -f "$gitcfg" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Faria backup de $gitcfg para $gitcfg.bak"
    else
      cp "$gitcfg" "$gitcfg.bak" || true
      log_info "Backup de $gitcfg salvo em $gitcfg.bak"
    fi
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Escreveria novo $gitcfg com name=$name email=$email"
  else
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    git config --global --add credential.https://github.com.helper ""
    git config --global --add credential.https://github.com.helper "!/usr/bin/gh auth git-credential"
    log_success "Configuração global do git e helper de credenciais definidos"
  fi
}
