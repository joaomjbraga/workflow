#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_fonts() {
  local base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
  local src_dir=""
  if [ -d "$base_dir/font" ]; then
    src_dir="$base_dir/font"
  elif [ -d "$base_dir/fonts" ]; then
    src_dir="$base_dir/fonts"
  else
    src_dir=""
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
    local base="$(basename "$f")"
    if [ -e "$dest_dir/$base" ]; then
      log_info "Fonte $base já existe; ignorando"
    else
      if [ "${DRY_RUN:-false}" = "true" ]; then
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
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[SIMULAÇÃO] Executaria fc-cache -f"
    else
      fc-cache -f || log_warning "fc-cache falhou"
    fi
  fi
}