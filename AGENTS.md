# AGENTS.md

## Project

LazyChad is an NvChad-based Neovim configuration packaged for Arch/AUR,
Debian, and RPM systems. It ships a dedicated `lchad` launcher, dynamic LSP /
formatter / linter pickers, and Linux helper scripts for Neovim, dependencies,
and uninstall.

## Commands

- Check shell syntax:
  `bash -n bin/* install.sh scripts/*.sh tests/*.sh`
- Lint shell (CI runs this):
  `shellcheck -S warning bin/* install.sh scripts/*.sh tests/*.sh`
- Run shell tests:
  `for t in tests/*.sh; do bash "$t" || break; done`
- Format Lua (CI checks with `stylua --check`):
  `stylua init.lua lua`
- Check that every file carrying the version agrees:
  `bash scripts/check-version.sh [vX.Y.Z]`
- Package/release files to keep in sync:
  `.version`, `PKGBUILD`, `nfpm.yaml`, `README.md`, and the AUR `.SRCINFO`.
- Release flow: bump the version files, merge to `main`, push tag `vX.Y.Z`.
  The tag builds the `.deb`/`.rpm` + `SHA256SUMS` release and syncs the AUR
  (`updpkgsums` pins the tarball checksum). `install.sh` installs that release.

## Agent History With ctx

If `ctx` is installed, use it before substantial work to recover prior agent
decisions for the area being edited.

- One-time setup:
  `ctx setup`
- Search previous LazyChad work:
  `ctx search "LazyChad lsp picker"`
  `ctx search "lazychad-nvim installer"`
  `ctx search --file bin/lazychad-nvim`
- Inspect useful matches:
  `ctx show event <ctx-event-id> --window 3`
  `ctx show session <ctx-session-id>`

Use ctx results as background evidence, not as a substitute for reading the
current source. Cite any recovered decision that affects a code change.

## Rules

- Keep Linux shell scripts and package files with LF line endings.
- Do not run installer, dependency, or uninstaller scripts on the user's machine
  unless explicitly asked.
- Do not remove or rewrite user Neovim config/data directories during
  development.
- Package hooks must never delete user data on upgrade or plain removal; only
  `apt purge` and `lazychad-uninstall` remove it.
- Preserve `NVIM_APPNAME=LazyChad` isolation.
- Keep `lazychad-nvim` tarball-first for Neovim and never add
  `apt-get remove neovim`.
- If the package version changes, update `.version`, `PKGBUILD`, `nfpm.yaml`,
  README install examples, release tags, and AUR metadata together.
- If shared LazyChad chrome changes, check `README.md`, package hooks, and
  portfolio case-study wording for drift.

## Style

- Lua uses 2-space indentation and `.stylua.toml`.
- Bash scripts may use Bash features; keep helper functions small and testable.
- Prefer package-manager-safe behavior over clever cleanup logic.
- Keep user-facing installer output clear, concise, and consistent with the
  existing colored status style.
