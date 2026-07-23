#!/usr/bin/env bash
set -Eeuo pipefail

export PKG_MANAGER=""

# If DRY_RUN is true, commands that would change the system should be printed
# instead of executed. Set via environment or by `install.sh --dry-run`.

# Logging
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/workflow"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install.log"


command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ "$EUID" -ne 0 ]; then
      echo "[DRY RUN] sudo $*"
    else
      echo "[DRY RUN] $*"
    fi
    return 0
  fi
  if [ "$EUID" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

log_info() { printf "[INFO] %s\n" "$*"; printf "%s [INFO] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_success() { printf "[OK] %s\n" "$*"; printf "%s [OK] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_warning() { printf "[WARN] %s\n" "$*"; printf "%s [WARN] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_error() { printf "[ERROR] %s\n" "$*"; printf "%s [ERROR] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }

temp_dir() {
  mktemp -d 2>/dev/null || mktemp -d -t workflow
}

install_package() {
  local pkg="$1"
  if command_exists "$pkg" || package_installed "$pkg"; then
    log_info "$pkg already installed"
    return 0
  fi

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would install package: $pkg via $PKG_MANAGER"
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y --no-install-recommends "$pkg"
      ;;
    pacman)
      run_as_root pacman -Sy --noconfirm --needed "$pkg"
      ;;
    dnf)
      run_as_root dnf install -y "$pkg"
      ;;
    *)
      log_error "Unknown package manager: $PKG_MANAGER"
      return 2
      ;;
  esac
}

package_installed() {
  local pkg="$1"
  case "$PKG_MANAGER" in
    apt)
      dpkg -s "$pkg" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Q "$pkg" >/dev/null 2>&1
      ;;
    dnf)
      rpm -q "$pkg" >/dev/null 2>&1
      ;;
    *)
      false
      ;;
  esac
}

verify_installation() {
  printf "%-20s %s\n" "Zsh:" "$(zsh --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "Node:" "$(node --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "NVM:" "$(nvm --version 2>/dev/null || echo 'not found')" 2>/dev/null || true
  printf "%-20s %s\n" "Docker:" "$(docker --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "Go:" "$(go version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "scrcpy:" "$(scrcpy --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "Starship:" "$(starship --version 2>/dev/null || echo 'not found')"
  if command_exists flatpak; then
    printf "%-20s %s\n" "Android Studio (flatpak):" "$(flatpak list | grep -i AndroidStudio || echo 'not found')"
  fi
}
