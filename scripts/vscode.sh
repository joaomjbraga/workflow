#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_vscode() {
  if command_exists code; then
    log_info "Visual Studio Code already installed"
    return 0
  fi

  log_info "Installing Visual Studio Code (stable)"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would install VS Code for $PKG_MANAGER"
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      # Add Microsoft apt repo and install
      if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
        run_as_root bash -c 'curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg'
      fi
      run_as_root bash -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
      run_as_root apt-get update -y || true
      if [ "${AUTO_YES:-false}" = "true" ]; then
        run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y code || log_warning "Failed to install code via apt"
      else
        run_as_root apt-get install -y code || log_warning "Failed to install code via apt"
      fi
      ;;
    dnf)
      # Add repo and install
      run_as_root rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
      run_as_root bash -c 'cat > /etc/yum.repos.d/vscode.repo <<"EOF"
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF'
      run_as_root dnf check-update || true
      run_as_root dnf install -y code || log_warning "Failed to install code via dnf"
      ;;
    pacman)
      # Prefer AUR package visual-studio-code-bin via yay/paru
      if command_exists yay; then
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[DRY RUN] Would run: yay -S --noconfirm visual-studio-code-bin"
        else
          run_as_root yay -S --noconfirm visual-studio-code-bin || log_warning "Failed to install visual-studio-code-bin via yay"
        fi
      elif command_exists paru; then
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[DRY RUN] Would run: paru -S --noconfirm visual-studio-code-bin"
        else
          run_as_root paru -S --noconfirm visual-studio-code-bin || log_warning "Failed to install visual-studio-code-bin via paru"
        fi
      else
        log_info "No AUR helper found; attempting manual AUR build of visual-studio-code-bin"
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[DRY RUN] Would git clone https://aur.archlinux.org/visual-studio-code-bin.git and run makepkg --verify && makepkg -si --noconfirm"
        else
          tmpd=$(temp_dir)
          git clone https://aur.archlinux.org/visual-studio-code-bin.git "$tmpd/visual-studio-code-bin" || { log_warning "Failed to clone AUR repo"; rm -rf "$tmpd"; return 1; }
          pushd "$tmpd/visual-studio-code-bin" >/dev/null
          # verify sources/checksums if possible
          if command_exists makepkg; then
            log_info "Running makepkg --verify to validate sources"
            makepkg --verify || log_warning "makepkg --verify failed or not all files present"
            log_info "Building and installing package via makepkg -si --noconfirm"
            run_as_root makepkg -si --noconfirm || log_warning "makepkg build/install failed"
          else
            log_warning "makepkg not available; please install base-devel or use an AUR helper"
          fi
          popd >/dev/null
          rm -rf "$tmpd"
        fi
      fi
      ;;
    *)
      log_warning "Unsupported package manager for automatic VS Code install: $PKG_MANAGER"
      ;;
  esac
}

export -f install_vscode
