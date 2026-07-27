#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_chrome() {
  if command_exists google-chrome || command_exists google-chrome-stable; then
    log_info "Google Chrome já está instalado"
    return 0
  fi

  log_info "Instalando Google Chrome"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria Google Chrome para $PKG_MANAGER"
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y wget gnupg || true

      run_as_root install -m 0755 -d /etc/apt/keyrings || true
      wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
        gpg --dearmor | \
        run_as_root tee /usr/share/keyrings/google-chrome.gpg > /dev/null || {
        log_warning "Falha ao adicionar chave GPG do Google Chrome"
        return 1
      }

      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | \
        run_as_root tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

      run_as_root apt-get update -y || true
      run_as_root apt-get install -y google-chrome-stable || {
        log_warning "Falha ao instalar Google Chrome"
        return 1
      }
      ;;
    dnf)
      run_as_root dnf install -y fedora-workstation-repositories || true
      run_as_root dnf config-manager --set-enabled google-chrome || true

      run_as_root dnf install -y google-chrome-stable || {
        log_warning "Falha ao instalar Google Chrome"
        return 1
      }
      ;;
    pacman)
      if command_exists yay; then
        run_as_root yay -S --noconfirm google-chrome || {
          log_warning "Falha ao instalar google-chrome via yay"
          return 1
        }
      elif command_exists paru; then
        run_as_root paru -S --noconfirm google-chrome || {
          log_warning "Falha ao instalar google-chrome via paru"
          return 1
        }
      else
        log_warning "Nenhum helper AUR encontrado; tentando build manual do AUR"
        tmpd=$(temp_dir)
        git clone https://aur.archlinux.org/google-chrome.git "$tmpd/google-chrome" || {
          log_warning "Falha ao clonar repositório AUR"
          rm -rf "$tmpd"
          return 1
        }
        pushd "$tmpd/google-chrome" >/dev/null
        if command_exists makepkg; then
          log_info "Executando makepkg --verify para validar fontes"
          if ! makepkg --verify; then
            log_error "makepkg --verify falhou; abortando build/instalação AUR"
            popd >/dev/null
            rm -rf "$tmpd"
            return 1
          fi
          log_info "makepkg --verify passou"
          log_info "Compilando e instalando pacote via makepkg -si --noconfirm"
          if ! run_as_root makepkg -si --noconfirm; then
            log_error "makepkg build/install falhou"
            popd >/dev/null
            rm -rf "$tmpd"
            return 1
          fi
        else
          log_warning "makepkg não disponível; instale base-devel ou use um helper AUR"
        fi
        popd >/dev/null
        rm -rf "$tmpd"
      fi
      ;;
    *)
      log_warning "Gerenciador de pacotes não suportado para instalação do Google Chrome"
      return 1
      ;;
  esac
}

export -f install_chrome