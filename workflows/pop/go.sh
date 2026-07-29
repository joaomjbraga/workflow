#!/usr/bin/env bash
set -Eeuo pipefail

install_go() {
  if command_exists go; then
    log_info "Go já está instalado: $(go version 2>/dev/null)"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[SIMULAÇÃO] Instalaria a versão oficial do Go"
    return 0
  fi

  if ! command_exists curl; then
    log_info "Instalando curl"
    install_package curl || {
      log_warning "Falha ao instalar curl"
      return 1
    }
  fi

  if ! command_exists jq; then
    log_info "Instalando jq"
    install_package jq || {
      log_warning "Falha ao instalar jq"
      return 1
    }
  fi

  local arch
  case "$(uname -m)" in
    x86_64)
      arch="amd64"
      ;;
    aarch64)
      arch="arm64"
      ;;
    armv7l)
      arch="armv6l"
      ;;
    *)
      log_warning "Arquitetura não suportada: $(uname -m)"
      return 1
      ;;
  esac

  log_info "Obtendo a versão mais recente do Go"

  local version filename download_url

  read -r version filename download_url < <(
    curl -fsSL "https://go.dev/dl/?mode=json" |
      jq -r --arg arch "$arch" '
        .[0] as $release
        | $release.version as $version
        | $release.files[]
        | select(
            .os == "linux" and
            .arch == $arch and
            .kind == "archive"
          )
        | "\($version) \(.filename) https://go.dev/dl/\(.filename)"
      ' | head -n1
  )

  if [ -z "${download_url:-}" ]; then
    log_warning "Não foi possível localizar um download compatível do Go"
    return 1
  fi

  local tmp
  tmp="$(mktemp)"

  log_info "Baixando ${version}"

  curl -fL "$download_url" -o "$tmp" || {
    rm -f "$tmp"
    log_warning "Falha ao baixar ${filename}"
    return 1
  }

  log_info "Removendo instalação anterior (se existir)"
  run_as_root rm -rf /usr/local/go

  log_info "Instalando Go"

  run_as_root tar -C /usr/local -xzf "$tmp" || {
    rm -f "$tmp"
    log_warning "Falha ao extrair o Go"
    return 1
  }

  rm -f "$tmp"

  log_info "Configurando PATH"

  cat <<'EOF' | run_as_root tee /etc/profile.d/go.sh >/dev/null
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
EOF

  run_as_root chmod 644 /etc/profile.d/go.sh

  export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

  if ! command_exists go; then
    log_warning "Go instalado, mas não encontrado no PATH"
    log_info "Abra uma nova sessão do terminal ou execute:"
    log_info "source /etc/profile.d/go.sh"
    return 1
  fi

  log_success "Go instalado: $(go version)"
}
