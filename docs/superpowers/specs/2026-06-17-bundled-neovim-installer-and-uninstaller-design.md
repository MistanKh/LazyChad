# LazyChad: Bundled OS-Aware Neovim Installer + Uninstaller

**Date:** 2026-06-17
**Status:** Approved (design) — implemented and shipped.

> **Update (2026-06-18):** The standalone **Kali-Scripts** repo referenced below
> has since been retired and deleted. Its `install_neovim.sh` lives on as the
> bundled `bin/lazychad-nvim` described here; `install_gh.sh` (GitHub CLI) was
> intentionally not carried over (`gh` is a one-line distro install). References
> to Kali-Scripts as a live separate repo are historical context for this design.

## Problem

LazyChad is a Neovim configuration wrapper. It needs a recent Neovim
(`nvim-treesitter` requires 0.12+), but distro packages are often too old —
especially Kali, whose repo Neovim lags. Today the Neovim install logic is
split awkwardly:

- `bin/lazychad-deps` installs Neovim per-distro (pacman on Arch, Debian
  Experimental / Neovim PPA / AppImage on Debian-likes, COPR on Fedora), with
  version checks and nightly-refresh prompts.
- A separate repo, **Kali-Scripts** (`install_neovim.sh`), installs the latest
  Neovim by extracting the official GitHub release tarball into `/usr/local`.

These two mechanisms fight over the `neovim` package. The known failure: running
the Kali-Scripts installer did `apt-get remove neovim` + `autoremove`, which
cascade-removed the LazyChad `.deb` (it declared a hard `Depends: neovim`), and
reinstalling LazyChad then dragged the stale Kali Neovim back.

## Goal

Fold the Kali-Scripts Neovim installer **into** LazyChad as a bundled,
OS-aware script, standardize on the tarball method everywhere, and add a clean
uninstaller. Remove the apt-package tug-of-war for good.

## Decisions (from brainstorming)

- **Install strategy:** tarball-everywhere. The official GitHub release tarball
  → `/usr/local` is the *primary* method on all Linux, regardless of distro.
  Native package managers are only a *fallback*.
- **Structure:** a standalone bundled script, `bin/lazychad-nvim`, runnable on
  its own and called by `lazychad-deps`.
- **CPU arch:** detect `x86_64` and `arm64`; fall back to native pkg manager on
  anything else.
- **Fallback:** tarball → native package manager → clear warning + manual
  instructions (never leave the user with nothing, never abort the whole deps
  run on a transient failure).
- **Uninstaller scope:** full clean-slate removal of everything LazyChad-related
  (Neovim install, binaries, system files, user dirs). Install-method aware.
- **Shared deps:** the uninstaller does **not** remove Node, Rust, Neovide,
  fonts, `-dev` packages, etc.
- **Data safety:** the uninstaller confirms, shows what will be removed, and
  offers a timestamped backup of `~/.config/LazyChad` before deleting. A
  `--yes` flag skips prompts.

## Out of scope

- Kali-Scripts' `install_gh.sh` (GitHub CLI) — not a LazyChad dependency.
- Changes to the Kali-Scripts repo itself — a possible follow-up, not part of
  this work. *(Resolved 2026-06-18: the repo was retired and deleted outright
  once its Neovim installer had been folded in here.)*
- Removing shared toolchain dependencies on uninstall.

---

## Components

### 1. `bin/lazychad-nvim` (new)

Self-contained Neovim installer/updater/uninstaller. Runs as a normal user and
escalates with `sudo` per-command (consistent with `lazychad-deps`, which
refuses to run as root). Modes:

| Invocation | Behavior |
|------------|----------|
| `lazychad-nvim` / `--install` / `--update` | install or update to latest stable |
| `lazychad-nvim --uninstall` / `-r` | remove the `/usr/local` tarball install + old manual leftovers |
| `lazychad-nvim --cleanup` / `-c` | remove old *manual* installs only (no install) |

**Install/update flow:**

1. **Detect arch** — `uname -m`:
   - `x86_64` → asset base `nvim-linux-x86_64`
   - `aarch64` | `arm64` → asset base `nvim-linux-arm64`
   - anything else → skip straight to native fallback (step 4) with a warning.
2. **Resolve versions** — installed version from `nvim --version` (first line,
   `v?\d+\.\d+\.\d+`, or `none`); latest from the GitHub
   `releases/latest` redirect tag. If equal, print "Already on latest" and exit
   0 (idempotent).
3. **Cleanup before install** — remove old *manual* installs only:
   `/usr/local/nvim`, `/usr/bin/nvim.bak`. **Never** `apt-get remove neovim`
   (that is the cascade bug). If an apt/pacman `neovim` package is present, note
   that it will be shadowed by the `/usr/local` install and leave it in place.
4. **Install (primary = tarball):**
   - Download `https://github.com/neovim/neovim/releases/download/<TAG>/<asset>.tar.gz`.
   - `sudo tar -xzf <asset>.tar.gz -C /usr/local --strip-components=1`
     (lands `nvim` in `/usr/local/bin`, which precedes `/usr/bin` on PATH).
   - Clean up the downloaded tarball.
5. **Verify** — `nvim --version`.
6. **Fallback** — if the download/extract fails, or arch was unsupported:
   - Use the native package manager to install/upgrade `neovim`
     (`pacman -S` / `dnf install` / `apt-get install`).
   - If that still does not yield a working `nvim`, print a warning with manual
     install instructions and exit non-zero.

**Uninstall flow (`--uninstall`):**

- Remove the tarball install paths: `/usr/local/bin/nvim`,
  `/usr/local/lib/nvim`, `/usr/local/share/nvim`. (Targeted paths, so unrelated
  `/usr/local` contents are untouched.)
- Remove old manual leftovers: `/usr/local/nvim`, `/usr/bin/nvim.bak`.
- Do **not** remove any apt/pacman `neovim` package (out of LazyChad's scope to
  manage; removing it risks cascades).

### 2. `bin/lazychad-deps` (modified)

Replace the entire per-OS Neovim block (Debian Experimental pinning, Neovim PPA,
COPR, AppImage, `MIN_MINOR` checks, nightly-refresh prompts) with a single
delegated call:

- Resolve the installer: prefer `command -v lazychad-nvim` (packaged on PATH);
  else fall back to `"$(dirname "$0")/lazychad-nvim"` (running from a clone).
- Run it as the current user (it escalates internally). It is idempotent, so a
  no-op when already on latest.

Everything else in `lazychad-deps` is unchanged: the no-root guard, OS
detection, system packages, Rust toolchain, Neovide, npm providers
(`neovim`, `tree-sitter-cli`), and the Python provider (`pynvim`).

### 3. `bin/lazychad-uninstall` (new)

Full, install-method-aware clean-slate removal. Runs as a normal user, escalates
with `sudo` per-command. Flags: `--yes`/`-y` to skip prompts.

1. **Show & confirm** — print the exact list of paths/packages to be removed;
   require `y/N` confirmation unless `--yes`.
2. **Back up user config (first)** — offer to copy `~/.config/LazyChad` to
   `~/.config/LazyChad_backup_<YYYYMMDD_HHMMSS>` before any deletion. Done before
   the package-manager step so it survives `postremove`.
3. **Remove LazyChad — detect install method:**
   - dpkg-owned (`dpkg -S /usr/bin/lchad` succeeds) →
     `sudo apt-get remove -y lazychad` (fires existing `postremove`, which
     clears the user dirs).
   - pacman-owned (`pacman -Qo /usr/bin/lchad` succeeds) →
     `sudo pacman -R --noconfirm lazychad`.
   - Otherwise (manual install) → `rm` directly:
     `/usr/bin/{lchad,lazychad-deps,lazychad-nvim,lazychad-uninstall}`,
     `/usr/share/lazychad`, `/usr/share/doc/lazychad`,
     `/usr/share/licenses/lazychad`, and the user dirs
     (`~/.config/LazyChad`, `~/.local/share/LazyChad`,
     `~/.local/state/LazyChad`, `~/.cache/LazyChad`) across `/home/*` and
     `/root`.
4. **Remove Neovim** — `lazychad-nvim --uninstall` (always a separate step since
   Neovim is not part of the LazyChad package).
5. **Leave shared deps** — Node, Rust, Neovide, fonts, `-dev` packages untouched.

### 4. Packaging (modified)

- **`nfpm.yaml`** (`.deb`/`.rpm`):
  - Add `bin/lazychad-nvim` → `/usr/bin/lazychad-nvim`.
  - Add `bin/lazychad-uninstall` → `/usr/bin/lazychad-uninstall`.
  - Move `neovim` from `depends:` to `recommends:` (so a `.deb` reinstall never
    drags the stale repo Neovim back; supersedes the earlier standalone PR).
- **`PKGBUILD`** (Arch):
  - `install -Dm755 bin/lazychad-nvim "$pkgdir/usr/bin/lazychad-nvim"`.
  - `install -Dm755 bin/lazychad-uninstall "$pkgdir/usr/bin/lazychad-uninstall"`.
  - Arch `depends=('neovim' …)` left as-is (pacman's Neovim is current; the
    `/usr/local` tarball simply shadows it — harmless).

---

## Final file set

| File | Status | Responsibility |
|------|--------|----------------|
| `bin/lchad` | unchanged | launch Neovim with the LazyChad config |
| `bin/lazychad-deps` | modified | install deps; delegate the Neovim step to `lazychad-nvim` |
| `bin/lazychad-nvim` | new | install / update / uninstall Neovim (tarball-first, arch-aware) |
| `bin/lazychad-uninstall` | new | full, install-method-aware clean-slate removal |
| `nfpm.yaml` | modified | package the two new scripts; `neovim` → `recommends` |
| `PKGBUILD` | modified | package the two new scripts |

## Error handling

- `lazychad-nvim` uses `set -e` but wraps the tarball download/extract so a
  failure degrades to the native-package-manager fallback rather than aborting.
- Unsupported CPU arch is a warning + fallback, not a hard error.
- `lazychad-uninstall` confirms before destructive actions and backs up user
  config first; package-manager removal and manual `rm` are guarded by the
  detected install method so the package DB stays consistent.
- Both scripts refuse to run as root where appropriate and rely on per-command
  `sudo`, matching the existing `lazychad-deps` model.

## Verification

- `bash -n` on `lazychad-nvim`, `lazychad-uninstall`, and the modified
  `lazychad-deps`.
- Dry-run the arch-detection and version-compare logic locally where the shell
  allows (Git Bash on the dev machine).
- Confirm `lazychad-nvim` resolution works both from a clone
  (`./bin/lazychad-nvim`) and from `PATH`.
- Full install/uninstall behavior must be verified on a real Linux box (Kali
  x86_64 and, ideally, an arm64 VM). The plan will enumerate the manual checks
  to run there: install → `lchad` launches with nvim 0.12+, reinstall does not
  revert Neovim, uninstall removes everything and leaves shared deps.
