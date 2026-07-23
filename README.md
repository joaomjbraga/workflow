# workflow

Personal post-install bootstrap for Linux. Run `./install.sh` to provision a fresh system.

Quick start:

```bash
chmod +x install.sh
./install.sh --dry-run   # simulate actions without making changes
./install.sh             # run for real
```

Logs are written to: `$XDG_CACHE_HOME or ~/.cache/workflow/install.log`.

Fonts: drop `.ttf` or `.otf` files in either `font/` or `fonts/` at repository root; they will be copied to `~/.local/share/`.

See `scripts/` and `config/` for modular implementation. The installer is idempotent and safe to run repeatedly.

What this implements
- Distribution detection (`/etc/os-release`) and package manager mapping for `apt`, `pacman`, and `dnf`.
- Idempotent package installation with logical package name resolution per-distro.
- Installers for: Docker (and group management), NVM + Node.js (v22), Go (distro package or tarball fallback), scrcpy, Starship, Zsh (with plugins), Glowkey, Android Studio (Flatpak).
- Fonts copy from `font/` or `fonts/` into `~/.local/share/` (supports `.ttf` and `.otf`).
- Arch-specific tasks: `fstrim.timer` enablement and `yay-bin` installation via AUR (temporary build directory).

Safety and idempotency
- Scripts check for existing commands and packages before installing.
- `install.sh --dry-run` simulates all steps and prints what would run without making changes.
- Operations that require privileges use `sudo` only when necessary.

Limitations & notes
- Package names vary between distributions; `resolve_pkg_name` provides basic mappings but may need manual adjustments for some packages.
- The Go installer prefers distro packages; when missing, it downloads a tarball and installs to `/usr/local/go`.
- Adding the current user to the `docker` group requires re-login to take effect.
- The installer assumes network access and will fail where connectivity or DNS is blocked.
- The script does not currently handle SELinux-specific steps on systems where SELinux is enforcing.

Troubleshooting
- Inspect the log at `$XDG_CACHE_HOME or ~/.cache/workflow/install.log` for details.
- Use `./install.sh --dry-run` to preview changes before applying them.

If you want, I can also create a `CHANGELOG.md` or a simple `Makefile`/`task` helper to run specific modules (e.g., only Docker or only fonts).
