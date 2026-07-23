#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Install Go: prefer distro package, fallback to tarball installation.
install_go() {
  case "$PKG_MANAGER" in
    pacman)
      install_package go && return 0 || true
      ;;
    apt)
      install_package golang && return 0 || true
      ;;
    dnf)
      install_package golang && return 0 || true
      ;;
  esac

  # Fallback: install from tarball to /usr/local
  local GO_VERSION="${GO_VERSION:-1.22.6}"
  local arch="$(uname -m)"
  case "$arch" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) arch=amd64 ;;
  esac

  local tarball="go${GO_VERSION}.linux-${arch}.tar.gz"
  local url="https://go.dev/dl/${tarball}"
  local td
  td=$(temp_dir)
  pushd "$td" >/dev/null
  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would download $url and extract to /usr/local"
    popd >/dev/null
    rm -rf "$td"
    return 0
  fi

  if ! curl -fsSL -O "$url"; then
    log_warning "Could not download Go tarball from $url"
    popd >/dev/null
    rm -rf "$td"
    return 1
  fi

  run_as_root rm -rf /usr/local/go || true
  run_as_root tar -C /usr/local -xzf "$tarball" || { log_warning "Failed to extract Go tarball"; popd >/dev/null; rm -rf "$td"; return 1; }
  popd >/dev/null
  rm -rf "$td"

  # Ensure PATH line in ~/.profile
  local profile="$HOME/.profile"
  local line='export PATH="/usr/local/go/bin:$PATH"'
  if ! grep -Fq '/usr/local/go/bin' "$profile" 2>/dev/null; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      log_info "[DRY RUN] Would add $line to $profile"
    else
      printf "%s\n" "$line" >> "$profile"
      log_info "Added /usr/local/go/bin to $profile"
    fi
  fi

  log_info "Go installed to /usr/local/go"
}
