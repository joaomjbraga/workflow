#!/usr/bin/env bash
set -Eeuo pipefail

arch_tweaks() {
  log_info "Habilitando fstrim.timer (SSD TRIM)"
  run_as_root systemctl enable fstrim.timer --now || log_warning "Não foi possível habilitar fstrim.timer"
  run_as_root fstrim / || true

  local preset_dir="/etc/systemd/system-preset"
  local preset_file="$preset_dir/90-custom.preset"
  if [ ! -d "$preset_dir" ]; then
    run_as_root mkdir -p "$preset_dir"
  fi
  if [ -f "$preset_file" ]; then
    grep -q "enable fstrim.timer" "$preset_file" || run_as_root bash -c "echo 'enable fstrim.timer' >> '$preset_file'"
  else
    run_as_root bash -c "echo 'enable fstrim.timer' > '$preset_file'"
  fi
  run_as_root systemctl preset-all || true
}
