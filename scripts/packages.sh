#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

resolve_pkg_name() {
  local key="$1"
  # Allow overrides via config/packages.toml in repo root
  local cfg
  cfg="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/packages.toml"
  if [ -f "$cfg" ]; then
    # extract the relevant section for this package manager
    local section
    section=$(awk -v pm="$PKG_MANAGER" '
      BEGIN{capture=0}
      /^\[/{gsub(/[][]/,"",$0); if($0==pm) {capture=1; next} else {capture=0}}
      capture==1 {print}
    ' "$cfg" || true)
    if [ -n "$section" ]; then
      # try to find key = "value" or key = value
      local val
      val=$(printf '%s' "$section" | sed -n -E 's/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' || true)
      if [ -z "$val" ]; then
        val=$(printf '%s' "$section" | sed -n -E 's/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*(.*)/\1/p' || true)
        val=$(printf '%s' "$val" | sed 's/^"//;s/"$//')
      fi
      val=$(printf '%s' "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [ -n "$val" ]; then
        echo "$val"
        return 0
      fi
    fi
  fi

  case "$PKG_MANAGER" in
    apt)
      case "$key" in
        go) echo golang ;;
        build-essential) echo build-essential ;;
        docker) echo docker.io ;;
        docker-compose) echo docker-compose-plugin ;;
        *) echo "$key" ;;
      esac ;;
    pacman)
      case "$key" in
        go) echo go ;;
        build-essential|base-devel) echo base-devel ;;
        docker) echo docker ;;
        docker-compose) echo docker-compose ;;
        *) echo "$key" ;;
      esac ;;
    dnf)
      case "$key" in
        go) echo golang ;;
        build-essential|base-devel) echo @development-tools ;;
        docker) echo docker ;;
        docker-compose) echo docker-compose-plugin ;;
        *) echo "$key" ;;
      esac ;;
    *)
      echo "$key" ;;
  esac
}

install_base_dependencies() {
  local pkgs_common=(curl wget git zsh unzip ca-certificates flatpak)
  local pkg_build

  case "$PKG_MANAGER" in
    apt)
      pkg_build=build-essential
      ;;
    pacman)
      pkg_build=base-devel
      ;;
    dnf)
      pkg_build=@development-tools
      ;;
  esac

  pkgs_common+=("$pkg_build")

  for p in "${pkgs_common[@]}"; do
    local resolved
    if type -t resolve_pkg_name >/dev/null 2>&1; then
      resolved=$(resolve_pkg_name "$p")
    else
      resolved="$p"
    fi
    log_info "Ensuring package: $resolved"
    install_package "$resolved" || log_warning "Failed to install $resolved"
  done

  # Ensure flatpak remote exists when flatpak is available
  if command_exists flatpak; then
    run_as_root flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
  fi
}

install_go() {
  # Prefer distro package if available
  case "$PKG_MANAGER" in
    pacman)
      install_package go
      ;;
    apt)
      install_package golang
      ;;
    dnf)
      install_package golang
      ;;
    *)
      return 1
      ;;
  esac
}
