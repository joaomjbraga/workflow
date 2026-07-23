Limitations and known issues

- Package name mappings are basic. Some distributions or versions may use different package names or meta-packages. If a package fails to install, check the distro's package name and update `scripts/packages.sh::resolve_pkg_name`.
- The Go tarball fallback installs to `/usr/local/go` and appends the path to `~/.profile`. Users with custom shells or profile handling may need to source the path manually.
- The installer requires network access for downloads and git clones. In restricted environments, pre-download artifacts or provide local mirrors.
- The AUR build for `yay-bin` requires `makepkg` and `base-devel` tools and will run `makepkg -si` which performs system-level package installation.
- The script uses `sudo` for privileged operations; running unattended on systems with no sudo configured will fail.
- No interactive prompt handling beyond `chsh` fallback; consider running interactively when changing shells.

If you encounter an issue, open an issue in the repository with the `--dry-run` output and relevant lines from `~/.cache/workflow/install.log`.
