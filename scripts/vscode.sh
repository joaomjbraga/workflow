#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

install_vscode() {
  if command_exists code; then
    log_info "Visual Studio Code já está instalado"
    return 0
  fi

  log_info "Instalando Visual Studio Code (stable)"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria VS Code para $PKG_MANAGER"
    return 0
  fi

  case "$PKG_MANAGER" in
    apt)
      if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
        run_as_root bash -c 'curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg'
      fi
      run_as_root bash -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
      run_as_root apt-get update -y || true
      if [ "${AUTO_YES:-false}" = "true" ]; then
        run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y code || log_warning "Falha ao instalar code via apt"
      else
        run_as_root apt-get install -y code || log_warning "Falha ao instalar code via apt"
      fi
      ;;
    dnf)
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
      run_as_root dnf install -y code || log_warning "Falha ao instalar code via dnf"
      ;;
    pacman)
      if command_exists yay; then
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[SIMULAÇÃO] Executaria: yay -S --noconfirm visual-studio-code-bin"
        else
          run_as_root yay -S --noconfirm visual-studio-code-bin || log_warning "Falha ao instalar visual-studio-code-bin via yay"
        fi
      elif command_exists paru; then
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[SIMULAÇÃO] Executaria: paru -S --noconfirm visual-studio-code-bin"
        else
          run_as_root paru -S --noconfirm visual-studio-code-bin || log_warning "Falha ao instalar visual-studio-code-bin via paru"
        fi
      else
        log_info "Nenhum helper AUR encontrado; tentando build manual do AUR para visual-studio-code-bin"
        if [ "${DRY_RUN:-false}" = "true" ]; then
          log_info "[SIMULAÇÃO] Clonaria https://aur.archlinux.org/visual-studio-code-bin.git e executaria makepkg --verify && makepkg -si --noconfirm"
        else
          tmpd=$(temp_dir)
          git clone https://aur.archlinux.org/visual-studio-code-bin.git "$tmpd/visual-studio-code-bin" || { log_warning "Falha ao clonar repositório AUR"; rm -rf "$tmpd"; return 1; }
          pushd "$tmpd/visual-studio-code-bin" >/dev/null
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
      fi
      ;;
    *)
      log_warning "Gerenciador de pacotes não suportado para instalação automática do VS Code: $PKG_MANAGER"
      ;;
  esac
}

export -f install_vscode