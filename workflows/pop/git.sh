#!/usr/bin/env bash
set -Eeuo pipefail

configure_git() {
  log_info "Configurando Git"

  if ! command_exists git; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Instalaria git"
    else
      install_package git || {
        log_warning "Falha ao instalar git"
        return 1
      }

      command_exists git || {
        log_warning "git não instalado; abortando configuração"
        return 1
      }
    fi
  fi

  local cur_name cur_email
  cur_name="$(git config --global --get user.name 2>/dev/null || true)"
  cur_email="$(git config --global --get user.email 2>/dev/null || true)"

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
    log_warning "Nome ou email não fornecidos; pulando configuração do Git"
    return 1
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Configuraria Git global"
    log_info "[SIMULAÇÃO] user.name=$name"
    log_info "[SIMULAÇÃO] user.email=$email"
    log_info "[SIMULAÇÃO] init.defaultBranch=main"
    log_info "[SIMULAÇÃO] fetch.prune=true"
    log_info "[SIMULAÇÃO] core.autocrlf=input"
    log_info "[SIMULAÇÃO] Configuraria GitHub CLI como credential helper (se instalado)"
    return 0
  fi

  git config --global user.name "$name"
  git config --global user.email "$email"

  git config --global init.defaultBranch main

  git config --global fetch.prune true

  git config --global core.autocrlf input

  if command_exists gh; then
    git config --global --unset-all credential.https://github.com.helper 2>/dev/null || true

    git config --global credential.https://github.com.helper ""

    git config --global \
      credential.https://github.com.helper \
      "!$(command -v gh) auth git-credential"

    log_info "GitHub CLI configurado como credential helper"
  else
    log_info "GitHub CLI não encontrado; pulando configuração do credential helper"
  fi

  log_success "Git configurado com sucesso"
}