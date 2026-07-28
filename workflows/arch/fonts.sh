#!/usr/bin/env bash
set -Eeuo pipefail

install_fonts() {
  local src_dir=""
  if [ -d "$REPO_ROOT/font" ]; then
    src_dir="$REPO_ROOT/font"
  elif [ -d "$REPO_ROOT/fonts" ]; then
    src_dir="$REPO_ROOT/fonts"
  fi

  local dest_dir="$HOME/.local/share/fonts"
  mkdir -p "$dest_dir"

  if [ -z "$src_dir" ] || [ ! -d "$src_dir" ]; then
    log_info "Diretório font/ ou fonts/ não encontrado; ignorando fontes"
    return 0
  fi

  shopt -s nullglob
  local copied=0
  for f in "$src_dir"/*.{ttf,otf}; do
    [ -e "$f" ] || continue
    local base
    base=$(basename "$f")
    if [ -e "$dest_dir/$base" ]; then
      log_info "Fonte $base já existe; ignorando"
    else
      if [ "$DRY_RUN" = "true" ]; then
        log_info "[SIMULAÇÃO] Copiaria fonte $base para $dest_dir"
        copied=$((copied + 1))
      else
        cp "$f" "$dest_dir/"
        copied=$((copied + 1))
        log_info "Fonte $base copiada"
      fi
    fi
  done
  shopt -u nullglob

  if command_exists fc-cache && [ "$copied" -gt 0 ]; then
    if [ "$DRY_RUN" = "true" ]; then
      log_info "[SIMULAÇÃO] Executaria fc-cache -f"
    else
      fc-cache -f || log_warning "fc-cache falhou"
    fi
  fi
}
