#!/usr/bin/env bash
set -Eeuo pipefail

export PKG_MANAGER=""

# If DRY_RUN is true, commands that would change the system should be printed
# instead of executed. Set via environment or by `install.sh --dry-run`.

# Logging
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/workflow"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))
LOG_BACKUPS=5

# rotate logs if file too large
if [ -f "$LOG_FILE" ]; then
  local_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
  if [ "$local_size" -ge "$LOG_MAX_SIZE" ]; then
    # rotate
    for i in $(seq $LOG_BACKUPS -1 2); do
      if [ -f "$LOG_FILE.$((i-1))" ]; then
        mv "$LOG_FILE.$((i-1))" "$LOG_FILE.$i" || true
      fi
    done
    mv "$LOG_FILE" "$LOG_FILE.1" || true
  fi
fi


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
      if [ "${AUTO_YES:-false}" = "true" ]; then
        run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg"
      else
        run_as_root apt-get install -y --no-install-recommends "$pkg"
      fi
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
  # NVM is a shell function; check NVM_DIR and source if available to query
  if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1 || true
    printf "%-20s %s\n" "NVM:" "$(command -v nvm >/dev/null 2>&1 && nvm --version || echo 'not found')"
  else
    printf "%-20s %s\n" "NVM:" "not found"
  fi
  printf "%-20s %s\n" "Docker:" "$(docker --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "Go:" "$(go version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "scrcpy:" "$(scrcpy --version 2>/dev/null || echo 'not found')"
  printf "%-20s %s\n" "Starship:" "$(starship --version 2>/dev/null || echo 'not found')"
  if command_exists flatpak; then
    printf "%-20s %s\n" "Android Studio (flatpak):" "$(flatpak list | grep -i AndroidStudio || echo 'not found')"
  fi
}
