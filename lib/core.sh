#!/usr/bin/env bash
set -Eeuo pipefail

export DRY_RUN="${DRY_RUN:-false}"
export AUTO_YES="${AUTO_YES:-false}"
export PKG_MANAGER="${PKG_MANAGER:-}"

_REPO_ROOT="${REPO_ROOT:-}"

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/workflow"
LOG_FILE="$LOG_DIR/install.log"
LOG_MAX_SIZE=$((5 * 1024 * 1024))
LOG_BACKUPS=5

mkdir -p "$LOG_DIR"

if [ -f "$LOG_FILE" ]; then
  log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
  if [ "$log_size" -ge "$LOG_MAX_SIZE" ]; then
    for i in $(seq $LOG_BACKUPS -1 2); do
      if [ -f "$LOG_FILE.$((i-1))" ]; then
        mv "$LOG_FILE.$((i-1))" "$LOG_FILE.$i" 2>/dev/null || true
      fi
    done
    mv "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null || true
  fi
fi

command_exists() { command -v "$1" >/dev/null 2>&1; }

run_as_root() {
  if [ "$DRY_RUN" = "true" ]; then
    if [ "$EUID" -ne 0 ]; then echo "[SIMULAÇÃO] sudo $*"
    else echo "[SIMULAÇÃO] $*"; fi
    return 0
  fi
  if [ "$EUID" -ne 0 ]; then sudo "$@"
  else "$@"; fi
}

log_info()    { printf "[INFO] %s\n" "$*"; printf "%s [INFO] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_success() { printf "[OK] %s\n" "$*"; printf "%s [OK] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_warning() { printf "[AVISO] %s\n" "$*"; printf "%s [AVISO] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }
log_error()   { printf "[ERRO] %s\n" "$*"; printf "%s [ERRO] %s\n" "$(date -Iseconds)" "$*" >>"$LOG_FILE"; }

temp_dir() { mktemp -d 2>/dev/null || mktemp -d -t workflow; }

install_package() {
  local pkg="$1"
  if package_installed "$pkg"; then
    log_info "$pkg já está instalado"
    return 0
  fi
  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria pacote: $pkg"
    return 0
  fi
  case "$PKG_MANAGER" in
    pacman) run_as_root pacman -Sy --noconfirm --needed "$pkg" ;;
    apt)
      run_as_root apt-get update -qq || true
      run_as_root apt-get install -y "$pkg"
      ;;
    *)
      log_error "Gerenciador de pacotes não implementado: $PKG_MANAGER"
      return 2
      ;;
  esac
}

apt_update() {
  if [ "$PKG_MANAGER" != "apt" ]; then
    return 0
  fi
  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Executaria apt-get update"
    return 0
  fi
  run_as_root apt-get update -qq || log_warning "apt-get update falhou"
}

install_deb() {
  local url="$1"
  local tmp_dir
  tmp_dir=$(temp_dir)
  local deb_file="$tmp_dir/$(basename "$url")"

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Baixaria e instalaria $url"
    rm -rf "$tmp_dir"
    return 0
  fi

  curl -fsSL "$url" -o "$deb_file" || {
    log_warning "Falha ao baixar $url"
    rm -rf "$tmp_dir"
    return 1
  }
  run_as_root apt-get install -y "$deb_file" || {
    log_warning "Falha ao instalar $deb_file"
    rm -rf "$tmp_dir"
    return 1
  }
  rm -rf "$tmp_dir"
  log_success "Pacote .deb instalado: $url"
}

package_installed() {
  local pkg="$1"
  case "$PKG_MANAGER" in
    pacman) pacman -Q "$pkg" >/dev/null 2>&1 ;;
    apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
    *) false ;;
  esac
}

verify_installation() {
  printf "%-20s %s\n" "Zsh:" "$(zsh --version 2>/dev/null || echo 'não encontrado')"
  printf "%-20s %s\n" "Node:" "$(node --version 2>/dev/null || echo 'não encontrado')"
  if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1 || true
    printf "%-20s %s\n" "NVM:" "$(command -v nvm >/dev/null 2>&1 && nvm --version || echo 'não encontrado')"
  else
    printf "%-20s %s\n" "NVM:" "não encontrado"
  fi
  printf "%-20s %s\n" "Docker:" "$(docker --version 2>/dev/null || echo 'não encontrado')"
  printf "%-20s %s\n" "Go:" "$(command -v go >/dev/null 2>&1 && go version 2>/dev/null || { [ -x /usr/local/go/bin/go ] && /usr/local/go/bin/go version 2>/dev/null || echo 'não encontrado'; })"
  printf "%-20s %s\n" "Java:" "$(java -version 2>&1 | head -n1 || echo 'não encontrado')"
  printf "%-20s %s\n" "Starship:" "$(starship --version 2>/dev/null || echo 'não encontrado')"
  if command_exists android-studio; then
    printf "%-20s %s\n" "Android Studio:" "$(android-studio --version 2>/dev/null || echo 'instalado')"
  elif [ -d /opt/android-studio ]; then
    printf "%-20s %s\n" "Android Studio:" "instalado em /opt/android-studio"
  else
    printf "%-20s %s\n" "Android Studio:" "não encontrado"
  fi
  printf "%-20s %s\n" "VS Code:" "$(code --version 2>/dev/null | head -n1 || echo 'não encontrado')"
  printf "%-20s %s\n" "Chrome:" "$(google-chrome-stable --version 2>/dev/null || google-chrome --version 2>/dev/null || echo 'não encontrado')"
  printf "%-20s %s\n" "Yay:" "$(yay --version 2>/dev/null | head -n1 || echo 'não encontrado')"
}
