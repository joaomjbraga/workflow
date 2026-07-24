#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

remove_conflicting_packages() {
  log_info "Removing conflicting Docker packages"

  case "$PKG_MANAGER" in
    apt)
      local conflicting_pkgs="docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc"
      for pkg in $conflicting_pkgs; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
          log_info "Removing conflicting package: $pkg"
          run_as_root apt-get purge -y "$pkg" || true
        fi
      done
      ;;
    dnf)
      local conflicting_pkgs="docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine"
      for pkg in $conflicting_pkgs; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
          log_info "Removing conflicting package: $pkg"
          run_as_root dnf remove -y "$pkg" || true
        fi
      done
      ;;
    pacman)
      # Arch Linux doesn't have conflicting packages by default
      ;;
  esac
}

setup_docker_repository() {
  log_info "Setting up official Docker repository"

  case "$PKG_MANAGER" in
    apt)
      # Install prerequisites
      run_as_root apt-get update -y || true
      run_as_root apt-get install -y ca-certificates curl || true

      # Add Docker's official GPG key
      run_as_root install -m 0755 -d /etc/apt/keyrings || true
      run_as_root curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc || {
        log_warning "Failed to download Docker GPG key"
        return 1
      }
      run_as_root chmod a+r /etc/apt/keyrings/docker.asc || true

      # Determine distro codename for Docker repo
      local distro_id="${DISTRO_ID:-debian}"
      local version_codename
      version_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

      # Map Ubuntu derivatives to Ubuntu codename for Docker repo
      case "$distro_id" in
        ubuntu|linuxmint|pop)
          version_codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
          distro_id="ubuntu"
          ;;
        debian)
          distro_id="debian"
          ;;
      esac

      # Add the repository to Apt sources
      run_as_root tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$distro_id
Suites: $version_codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

      run_as_root apt-get update -y || true
      ;;
    dnf)
      # Add Docker repository for Fedora
      run_as_root dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo || {
        log_warning "Failed to add Docker repository"
        return 1
      }
      ;;
    pacman)
      # Arch Linux uses community repo, no additional setup needed
      ;;
  esac
}

install_docker() {
  if command_exists docker; then
    log_info "Docker already installed"
    # Still ensure service is running and user is in docker group
  else
    # Remove conflicting packages first
    remove_conflicting_packages

    # Setup official Docker repository
    setup_docker_repository || {
      log_warning "Failed to setup Docker repository, falling back to distro packages"
      install_package docker || log_warning "Failed to install docker package"
      return 0
    }

    log_info "Installing Docker packages from official repository"

    case "$PKG_MANAGER" in
      apt)
        run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
          log_warning "Failed to install Docker from official repo"
          return 1
        }
        ;;
      dnf)
        run_as_root dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
          log_warning "Failed to install Docker from official repo"
          return 1
        }
        ;;
      pacman)
        install_package docker || log_warning "Failed to install docker package"
        install_package docker-compose || log_warning "Failed to install docker-compose package"
        ;;
    esac
  fi

  run_as_root systemctl enable --now docker || log_warning "Failed to enable/start docker"

  # Determine target user: prefer SUDO_USER, then USER, then current owner
  TARGET_USER="${SUDO_USER:-${USER:-}}"
  if [ -z "$TARGET_USER" ]; then
    # try to detect an interactive user
    TARGET_USER=$(logname 2>/dev/null || id -un 2>/dev/null || echo "")
  fi

  if [ -n "$TARGET_USER" ]; then
    if id -nG "$TARGET_USER" | grep -qw docker; then
      log_info "User $TARGET_USER already in docker group"
    else
      run_as_root usermod -aG docker "$TARGET_USER" || log_warning "Could not add $TARGET_USER to docker group"
      log_info "Added $TARGET_USER to docker group (may require relogin)"
    fi
  else
    log_warning "Could not determine target user to add to docker group; skipping"
  fi
}
