#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_chrome() {
  if command_exists google-chrome || command_exists google-chrome-stable; then
    log_info "Google Chrome already installed"
    return 0
  fi

  log_info "Installing Google Chrome"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[DRY RUN] Would install Google Chrome for $PKG_MANAGER"
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      # Install prerequisites
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y wget gnupg || true

      # Add Google Chrome GPG key
      run_as_root install -m 0755 -d /etc/apt/keyrings || true
      wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
        gpg --dearmor | \
        run_as_root tee /usr/share/keyrings/google-chrome.gpg > /dev/null || {
        log_warning "Failed to add Google Chrome GPG key"
        return 1
      }

      # Add Google Chrome repository
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | \
        run_as_root tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

      # Update package list and install
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y google-chrome-stable || {
        log_warning "Failed to install Google Chrome"
        return 1
      }
      ;;
    dnf)
      # Enable Google Chrome repository (Fedora only)
      run_as_root dnf install -y fedora-workstation-repositories || true
      run_as_root dnf config-manager --set-enabled google-chrome || true

      # Install Google Chrome
      run_as_root dnf install -y google-chrome-stable || {
        log_warning "Failed to install Google Chrome"
        return 1
      }
      ;;
    pacman)
      # Arch Linux: use AUR package or flatpak
      if command_exists yay; then
        run_as_root yay -S --noconfirm google-chrome || {
          log_warning "Failed to install google-chrome via yay"
          return 1
        }
      elif command_exists paru; then
        run_as_root paru -S --noconfirm google-chrome || {
          log_warning "Failed to install google-chrome via paru"
          return 1
        }
      else
        log_warning "No AUR helper found; attempting manual AUR build"
        tmpd=$(temp_dir)
        git clone https://aur.archlinux.org/google-chrome.git "$tmpd/google-chrome" || {
          log_warning "Failed to clone AUR repo"
          rm -rf "$tmpd"
          return 1
        }
        pushd "$tmpd/google-chrome" >/dev/null
        if command_exists makepkg; then
          log_info "Running makepkg --verify to validate sources"
          if ! makepkg --verify; then
            log_error "makepkg --verify failed; aborting AUR build/install"
            popd >/dev/null
            rm -rf "$tmpd"
            return 1
          fi
          log_info "makepkg --verify passed"
          log_info "Building and installing package via makepkg -si --noconfirm"
          if ! run_as_root makepkg -si --noconfirm; then
            log_error "makepkg build/install failed"
            popd >/dev/null
            rm -rf "$tmpd"
            return 1
          fi
        else
          log_warning "makepkg not available; please install base-devel or use an AUR helper"
        fi
        popd >/dev/null
        rm -rf "$tmpd"
      fi
      ;;
    *)
      log_warning "Unsupported package manager for Google Chrome installation"
      return 1
      ;;
  esac
}

export -f install_chrome
