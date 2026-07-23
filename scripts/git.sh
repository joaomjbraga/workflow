#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

configure_git() {
  log_info "Configuring Git (user.name and user.email)"

  # Ensure git is installed
  if ! command_exists git; then
    log_info "git not found"
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would install git"
    else
      if [ "${AUTO_YES:-false}" = "true" ]; then
        install_package git || log_warning "Failed to install git"
      else
        read -rp "git não encontrado. Deseja instalar git agora? [Y/n]: " ans
        ans="${ans:-Y}"
        if [[ "$ans" =~ ^[Yy] ]]; then
          install_package git || log_warning "Failed to install git"
        else
          log_warning "git não instalado; abortando configuração de usuário"
          return 1
        fi
      fi
    fi
  fi

  # Gather existing values
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
    log_warning "Nome ou email não fornecido; pulando configuração de ~/.gitconfig"
    return 1
  fi

  local gitcfg="$HOME/.gitconfig"
  if [ -f "$gitcfg" ]; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would backup existing $gitcfg to $gitcfg.bak"
    else
      cp "$gitcfg" "$gitcfg.bak" || true
      log_info "Backed up existing $gitcfg to $gitcfg.bak"
    fi
  fi

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would write new $gitcfg with name=$name email=$email"
  else
    cat > "$gitcfg" <<EOF
[user]
	name = $name
	email = $email

[init]
	defaultBranch = main

[credential "https://github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
EOF
    log_success "Wrote $gitcfg"
  fi

  # Also configure via git config --global for immediate effect
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would run: git config --global user.name \"$name\""
    log_info "[DRY RUN] Would run: git config --global user.email \"$email\""
  else
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global init.defaultBranch main
    # add credential helper entries
    git config --global --add credential.https://github.com.helper ""
    git config --global --add credential.https://github.com.helper "!/usr/bin/gh auth git-credential"
    log_success "Configured git global user and credential helper"
  fi
}

export -f configure_git
