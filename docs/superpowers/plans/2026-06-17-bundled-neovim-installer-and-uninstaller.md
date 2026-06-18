# Bundled OS-Aware Neovim Installer + Uninstaller — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Update (2026-06-18):** Implemented and shipped. The standalone Kali-Scripts repo this plan folds in has since been retired and deleted — its Neovim installer now lives here as `bin/lazychad-nvim`. Kali-Scripts references below are historical context.

**Goal:** Fold the Kali-Scripts Neovim installer into LazyChad as a bundled, OS-aware script, standardize on the GitHub-release-tarball method everywhere, delegate the `lazychad-deps` Neovim step to it, and add a clean, install-method-aware uninstaller.

**Architecture:** Two new standalone Bash scripts in `bin/` — `lazychad-nvim` (install/update/uninstall Neovim, tarball-first with native package-manager fallback, x86_64+arm64) and `lazychad-uninstall` (full clean-slate removal). `lazychad-deps` is slimmed to delegate its Neovim step to `lazychad-nvim`. Both scripts run as a normal user and escalate with `sudo` per-command. Pure logic functions are written behind a `BASH_SOURCE`/`$0` guard so they can be sourced and unit-tested.

**Tech Stack:** Bash, `curl`, `tar`, `uname`, `dpkg`/`pacman`/`apt`/`dnf`. nfpm (`.deb`/`.rpm`) + Arch `PKGBUILD` for packaging. Plain-bash assertion tests under `tests/`.

## Global Constraints

- Neovim primary install method = official GitHub release tarball extracted to `/usr/local` with `tar --strip-components=1` (so `/usr/local/bin/nvim` shadows any apt/pacman nvim via PATH). Verbatim from spec.
- **Never** run `apt-get remove neovim` / `autoremove` anywhere. Leaving the apt package in place is intentional.
- CPU arch mapping: `x86_64`/`amd64` → asset `nvim-linux-x86_64`; `aarch64`/`arm64` → asset `nvim-linux-arm64`; anything else → native package-manager fallback + warning.
- Download URL MUST include the `v` tag prefix: `https://github.com/neovim/neovim/releases/download/v<version>/<asset>.tar.gz`.
- Scripts run as a normal user and use `sudo` per-command. `lazychad-deps` continues to refuse to run as root.
- Fallback chain for install: tarball → native package manager → warning + manual instructions (never abort the whole `lazychad-deps` run on a transient failure).
- Uninstaller: confirm + show what's removed + offer timestamped backup of `~/.config/LazyChad` before deletion; `--yes`/`-y` skips prompts. Does NOT remove shared deps (Node, Rust, Neovide, fonts, `-dev` packages).
- Packaging: `neovim` is a `recommends` (not hard `depends`) in `nfpm.yaml`; Arch `PKGBUILD` `depends=('neovim' …)` stays as-is.
- Colour-code helpers and tone should match the existing `bin/lazychad-deps` style (`BOLD`/`GREEN`/`BLUE`/`YELLOW`/`RED`/`NC`, emoji-prefixed status lines).

---

## File Structure

| File | Status | Responsibility |
|------|--------|----------------|
| `bin/lazychad-nvim` | create | install / update / uninstall / cleanup Neovim |
| `bin/lazychad-uninstall` | create | full, install-method-aware removal |
| `bin/lazychad-deps` | modify | delegate the Neovim step to `lazychad-nvim` |
| `nfpm.yaml` | modify | package both new scripts; `neovim` → `recommends` |
| `PKGBUILD` | modify | package both new scripts |
| `README.md` | modify | document the new commands |
| `tests/test_lazychad_nvim.sh` | create | unit tests for pure logic (arch, URL) |
| `tests/test_lazychad_uninstall.sh` | create | unit tests for confirm/arg parsing |

---

### Task 1: `bin/lazychad-nvim` — pure logic + tests

**Files:**
- Create: `bin/lazychad-nvim`
- Test: `tests/test_lazychad_nvim.sh`

**Interfaces:**
- Consumes: nothing (first task).
- Produces (sourceable functions later tasks/tests rely on):
  - `detect_arch()` → echoes `nvim-linux-x86_64` | `nvim-linux-arm64` | `unsupported`
  - `nvim_download_url(asset, version)` → echoes full tarball URL with `v` prefix
  - `get_installed_version()` → echoes `X.Y.Z` or `none`
  - `get_latest_version()` → echoes `X.Y.Z` (network)
  - `detect_os()` → echoes `/etc/os-release` `ID` or `unknown`
  - Script only runs `main "$@"` when executed directly (guarded by `BASH_SOURCE`).

- [ ] **Step 1: Write the failing test**

Create `tests/test_lazychad_nvim.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for bin/lazychad-nvim pure logic. No network, no sudo.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-nvim"   # source-only: main must NOT run

fail=0
assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi
}

# detect_arch maps uname -m values
uname() { echo "x86_64"; }; assert_eq "$(detect_arch)" "nvim-linux-x86_64" "detect_arch x86_64"
uname() { echo "amd64"; };  assert_eq "$(detect_arch)" "nvim-linux-x86_64" "detect_arch amd64"
uname() { echo "aarch64"; };assert_eq "$(detect_arch)" "nvim-linux-arm64"  "detect_arch aarch64"
uname() { echo "arm64"; };  assert_eq "$(detect_arch)" "nvim-linux-arm64"  "detect_arch arm64"
uname() { echo "riscv64"; };assert_eq "$(detect_arch)" "unsupported"       "detect_arch riscv64"
unset -f uname

# download URL includes the v prefix
assert_eq "$(nvim_download_url nvim-linux-x86_64 0.12.0)" \
  "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-x86_64.tar.gz" \
  "nvim_download_url has v prefix"

exit $fail
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_lazychad_nvim.sh`
Expected: FAIL — `source` errors because `bin/lazychad-nvim` does not exist yet.

- [ ] **Step 3: Write minimal implementation (pure logic + source guard)**

Create `bin/lazychad-nvim`:

```bash
#!/bin/bash
# LazyChad Neovim Installer
# Installs/updates/uninstalls the latest stable Neovim using the official
# GitHub release tarball into /usr/local (shadowing any apt/pacman nvim via
# PATH). Tarball-first, arch-aware, with native package-manager fallback.
# Run as a normal user; escalates with sudo per-command.

set -euo pipefail

BOLD="\033[1m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; NC="\033[0m"

# ---- pure helpers (sourceable for tests) ----

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "nvim-linux-x86_64" ;;
        aarch64|arm64) echo "nvim-linux-arm64" ;;
        *)             echo "unsupported" ;;
    esac
}

nvim_download_url() {
    # $1=asset base  $2=version (X.Y.Z, no leading v)
    echo "https://github.com/neovim/neovim/releases/download/v$2/$1.tar.gz"
}

get_installed_version() {
    command -v nvim >/dev/null 2>&1 || { echo "none"; return; }
    nvim --version 2>/dev/null | head -1 | grep -oP 'v?\K[0-9]+\.[0-9]+\.[0-9]+' || echo "none"
}

get_latest_version() {
    curl -fsSL https://github.com/neovim/neovim/releases/latest \
        | grep -oP 'releases/tag/v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release; echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# ---- main (added in later steps) ----
main() {
    echo "lazychad-nvim: not implemented yet"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_lazychad_nvim.sh`
Expected: all `ok` lines, exit 0.

- [ ] **Step 5: Syntax check**

Run: `bash -n bin/lazychad-nvim && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 6: Commit**

```bash
git add bin/lazychad-nvim tests/test_lazychad_nvim.sh
git commit -m "feat(nvim): lazychad-nvim pure logic (arch detect, url, versions)"
```

---

### Task 2: `bin/lazychad-nvim` — install/update/uninstall/cleanup behavior

**Files:**
- Modify: `bin/lazychad-nvim` (replace the placeholder `main` and add action functions)

**Interfaces:**
- Consumes: `detect_arch`, `nvim_download_url`, `get_installed_version`, `get_latest_version`, `detect_os` from Task 1.
- Produces:
  - `install_or_update()` — default action; tarball-first with fallback
  - `uninstall_nvim()` — remove `/usr/local` tarball install + manual leftovers
  - `cleanup_manual()` — remove `/usr/local/nvim` and `/usr/bin/nvim.bak` only
  - `main()` arg dispatch: `--install`/`--update`/`-i`/`-u`/`install`/`update` (default), `--uninstall`/`-r`, `--cleanup`/`-c`

- [ ] **Step 1: Write the failing test (cleanup_manual is a no-op-safe function)**

Append to `tests/test_lazychad_nvim.sh` before the final `exit $fail`:

```bash
# cleanup_manual must succeed even when nothing exists (sudo/rm stubbed)
sudo() { "$@"; }            # drop the privilege escalation in tests
rm() { :; }                 # no-op rm so the test never deletes anything
assert_eq "$(cleanup_manual >/dev/null 2>&1; echo $?)" "0" "cleanup_manual returns 0 when clean"
unset -f sudo rm
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_lazychad_nvim.sh`
Expected: FAIL — `cleanup_manual: command not found` (function not defined yet).

- [ ] **Step 3: Implement the action functions and real `main`**

In `bin/lazychad-nvim`, replace the placeholder `main()` block (the `main() { echo "lazychad-nvim: not implemented yet"; }` lines) with:

```bash
# ---- actions ----

cleanup_manual() {
    if [ -d /usr/local/nvim ]; then
        echo -e "${BLUE}Removing old manual install /usr/local/nvim...${NC}"
        sudo rm -rf /usr/local/nvim
    fi
    if [ -f /usr/bin/nvim.bak ]; then
        echo -e "${BLUE}Removing /usr/bin/nvim.bak...${NC}"
        sudo rm -f /usr/bin/nvim.bak
    fi
    return 0
}

note_apt_neovim() {
    if command -v dpkg >/dev/null 2>&1 && dpkg -l neovim 2>/dev/null | grep -q '^ii'; then
        echo -e "${YELLOW}Note: apt 'neovim' package present; it will be shadowed by the${NC}"
        echo -e "${YELLOW}      /usr/local install. Leaving it in place (no apt removal).${NC}"
    fi
}

manual_help() {
    echo -e "${RED}❌ Could not install Neovim automatically.${NC}"
    echo "Install the latest manually from:"
    echo "  https://github.com/neovim/neovim/releases/latest"
}

native_install_neovim() {
    local os; os="$(detect_os)"
    echo -e "${BLUE}Falling back to native package manager for $os...${NC}"
    case "$os" in
        arch|cachyos|manjaro) sudo pacman -S --needed --noconfirm neovim ;;
        fedora)               sudo dnf install -y neovim ;;
        debian|ubuntu|pop|kali) sudo apt-get update && sudo apt-get install -y neovim ;;
        *)                    return 1 ;;
    esac
}

install_tarball() {
    # $1=asset  $2=version
    local asset="$1" version="$2" url tmp
    url="$(nvim_download_url "$asset" "$version")"
    tmp="$(mktemp -d)"
    echo -e "${BLUE}Downloading Neovim v$version ($asset)...${NC}"
    if ! curl -fSL "$url" -o "$tmp/$asset.tar.gz"; then rm -rf "$tmp"; return 1; fi
    echo -e "${BLUE}Extracting to /usr/local...${NC}"
    if ! sudo tar -xzf "$tmp/$asset.tar.gz" -C /usr/local --strip-components=1; then rm -rf "$tmp"; return 1; fi
    rm -rf "$tmp"
    return 0
}

install_or_update() {
    local current latest asset
    echo -e "${BOLD}=== LazyChad Neovim Installer ===${NC}"
    current="$(get_installed_version)"
    asset="$(detect_arch)"

    if [ "$asset" = "unsupported" ]; then
        echo -e "${YELLOW}Unsupported CPU arch ($(uname -m)).${NC}"
        if native_install_neovim; then nvim --version | head -1; return 0; else manual_help; return 1; fi
    fi

    latest="$(get_latest_version || true)"
    if [ -z "${latest:-}" ]; then
        echo -e "${YELLOW}Could not determine the latest version (network?).${NC}"
        if native_install_neovim; then nvim --version | head -1; return 0; else manual_help; return 1; fi
    fi

    echo -e "Installed: ${current}    Latest: ${latest}"
    if [ "$current" = "$latest" ]; then
        echo -e "${GREEN}✅ Already on the latest Neovim (v$latest).${NC}"
        return 0
    fi

    cleanup_manual
    note_apt_neovim
    if install_tarball "$asset" "$latest"; then
        echo -e "${GREEN}✅ Neovim v$latest installed to /usr/local.${NC}"
        nvim --version | head -1
        return 0
    fi

    echo -e "${RED}⚠️ Tarball install failed. Trying native package manager...${NC}"
    if native_install_neovim; then nvim --version | head -1; return 0; else manual_help; return 1; fi
}

uninstall_nvim() {
    echo -e "${BLUE}Removing Neovim installed under /usr/local...${NC}"
    sudo rm -rf /usr/local/bin/nvim /usr/local/lib/nvim /usr/local/share/nvim
    cleanup_manual
    echo -e "${GREEN}✅ Neovim (tarball/manual install) removed.${NC}"
    echo -e "${YELLOW}Any apt/pacman 'neovim' package was left untouched.${NC}"
}

main() {
    case "${1:-install}" in
        -r|--uninstall)                   uninstall_nvim ;;
        -c|--cleanup)                     cleanup_manual; echo -e "${GREEN}Manual-install cleanup done.${NC}" ;;
        -i|--install|-u|--update|install|update) install_or_update ;;
        *)                                install_or_update ;;
    esac
}
```

(Leave the `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi` guard at the end of the file unchanged.)

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_lazychad_nvim.sh`
Expected: all `ok`, exit 0.

- [ ] **Step 5: Syntax check**

Run: `bash -n bin/lazychad-nvim && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 6: Commit**

```bash
git add bin/lazychad-nvim tests/test_lazychad_nvim.sh
git commit -m "feat(nvim): tarball install/update + uninstall/cleanup with native fallback"
```

---

### Task 3: Delegate the `lazychad-deps` Neovim step to `lazychad-nvim`

**Files:**
- Modify: `bin/lazychad-deps` (replace the entire `[1/6]` Neovim block)

**Interfaces:**
- Consumes: an executable `lazychad-nvim` (on PATH when packaged, or alongside in `bin/` when run from a clone).
- Produces: no new functions; `lazychad-deps` resolves and calls `lazychad-nvim --update`.

- [ ] **Step 1: Replace the Neovim block**

In `bin/lazychad-deps`, delete everything from the line:

```
# 1. Neovim Version Check & Upgrade
```

through the matching `fi` immediately **before** the line `# 2. System Packages` (this is the whole block: `get_nvim_ver`, `is_nightly`, `CURRENT_VER`/`MAJOR`/`MINOR`, the `UPGRADE_NEEDED` logic, the big per-OS `case`, the AppImage fallbacks, and the final `if [ "$UPGRADE_NEEDED" = true ] … else … fi`). Replace the whole deleted span with:

```bash
# 1. Neovim (delegated to lazychad-nvim)
echo -e "\n${BOLD}${YELLOW}[1/6] Ensuring latest Neovim...${NC}"

NVIM_INSTALLER=""
if command -v lazychad-nvim >/dev/null 2>&1; then
    NVIM_INSTALLER="lazychad-nvim"
elif [ -x "$(dirname "$0")/lazychad-nvim" ]; then
    NVIM_INSTALLER="$(dirname "$0")/lazychad-nvim"
fi

if [ -n "$NVIM_INSTALLER" ]; then
    "$NVIM_INSTALLER" --update || echo -e "${YELLOW}⚠️ Neovim step reported an issue; continuing with the rest of setup.${NC}"
else
    echo -e "${RED}⚠️ lazychad-nvim not found. Skipping Neovim install.${NC}"
    echo -e "${YELLOW}   Install it manually: https://github.com/neovim/neovim/releases/latest${NC}"
fi
```

- [ ] **Step 2: Syntax check**

Run: `bash -n bin/lazychad-deps && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 3: Verify the resolver finds the sibling script (from a clone)**

Run:
```bash
bash -c 'cd "$(git rev-parse --show-toplevel)" && [ -x bin/lazychad-nvim ] && [ -x "$(dirname bin/lazychad-deps)/lazychad-nvim" ] && echo RESOLVES_OK'
```
Expected: `RESOLVES_OK` (confirms `bin/lazychad-nvim` exists and is executable next to `lazychad-deps`).

- [ ] **Step 4: Confirm the old per-OS Neovim logic is gone**

Run: `grep -nE 'experimental|add-apt-repository|copr|AppImage|MIN_MINOR' bin/lazychad-deps || echo CLEAN`
Expected: `CLEAN` (none of the removed mechanisms remain).

- [ ] **Step 5: Commit**

```bash
git add bin/lazychad-deps
git commit -m "refactor(deps): delegate neovim install to lazychad-nvim"
```

---

### Task 4: `bin/lazychad-uninstall` — full, install-method-aware removal

**Files:**
- Create: `bin/lazychad-uninstall`
- Test: `tests/test_lazychad_uninstall.sh`

**Interfaces:**
- Consumes: `lazychad-nvim --uninstall` (resolved on PATH or sibling `bin/`).
- Produces:
  - `parse_yes(arg)` → sets/echoes whether prompts are skipped (testable)
  - `backup_user_config()`, `remove_user_dirs()`, `remove_lazychad()`, `remove_neovim()`, `main()`
  - Script runs `main "$@"` only when executed directly (BASH_SOURCE guard).

- [ ] **Step 1: Write the failing test**

Create `tests/test_lazychad_uninstall.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for bin/lazychad-uninstall arg parsing. No sudo, no deletion.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-uninstall"   # source-only: main must NOT run

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

assert_eq "$(parse_yes --yes)" "true"  "parse_yes --yes"
assert_eq "$(parse_yes -y)"    "true"  "parse_yes -y"
assert_eq "$(parse_yes '')"    "false" "parse_yes empty"
assert_eq "$(parse_yes --foo)" "false" "parse_yes unknown"

exit $fail
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_lazychad_uninstall.sh`
Expected: FAIL — `source` errors because the file does not exist.

- [ ] **Step 3: Implement `bin/lazychad-uninstall`**

Create `bin/lazychad-uninstall`:

```bash
#!/bin/bash
# LazyChad Uninstaller — full, install-method-aware removal.
# Removes the /usr/local Neovim install, LazyChad binaries/files, and user
# dirs. Leaves shared deps (Node, Rust, Neovide, fonts) untouched.
# Confirms and offers a config backup first. Run as a normal user; uses sudo.

set -uo pipefail

BOLD="\033[1m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; NC="\033[0m"

parse_yes() {
    case "${1:-}" in
        -y|--yes) echo "true" ;;
        *)        echo "false" ;;
    esac
}

confirm() {
    # $1=prompt ; honours global ASSUME_YES
    if [ "${ASSUME_YES:-false}" = "true" ]; then return 0; fi
    read -p "$1 (y/N) " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

backup_user_config() {
    local cfg="$HOME/.config/LazyChad"
    if [ -d "$cfg" ] && confirm "Back up $cfg before removing?"; then
        local dest="${cfg}_backup_$(date +%Y%m%d_%H%M%S)"
        cp -a "$cfg" "$dest"
        echo -e "${GREEN}🗄️  Backed up to $dest${NC}"
    fi
}

remove_user_dirs() {
    local home sub
    for home in /home/* /root; do
        [ -d "$home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad; do
            if [ -d "$home/$sub" ]; then
                sudo rm -rf "$home/$sub"
                echo "  -> removed $home/$sub"
            fi
        done
    done
}

remove_neovim() {
    local installer=""
    if command -v lazychad-nvim >/dev/null 2>&1; then
        installer="lazychad-nvim"
    elif [ -x "$(dirname "$0")/lazychad-nvim" ]; then
        installer="$(dirname "$0")/lazychad-nvim"
    fi
    if [ -n "$installer" ]; then
        "$installer" --uninstall
    else
        echo -e "${BLUE}Removing Neovim under /usr/local directly...${NC}"
        sudo rm -rf /usr/local/bin/nvim /usr/local/lib/nvim /usr/local/share/nvim /usr/local/nvim
    fi
}

remove_lazychad() {
    if command -v dpkg >/dev/null 2>&1 && dpkg -S /usr/bin/lchad >/dev/null 2>&1; then
        echo -e "${BLUE}Detected dpkg install. Removing the lazychad package...${NC}"
        sudo apt-get remove -y lazychad
    elif command -v pacman >/dev/null 2>&1 && pacman -Qo /usr/bin/lchad >/dev/null 2>&1; then
        echo -e "${BLUE}Detected pacman install. Removing the lazychad package...${NC}"
        sudo pacman -R --noconfirm lazychad
    else
        echo -e "${BLUE}Removing manual LazyChad install...${NC}"
        sudo rm -f /usr/bin/lchad /usr/bin/lazychad-deps /usr/bin/lazychad-nvim /usr/bin/lazychad-uninstall
        sudo rm -rf /usr/share/lazychad /usr/share/doc/lazychad /usr/share/licenses/lazychad
        remove_user_dirs
    fi
}

main() {
    ASSUME_YES="$(parse_yes "${1:-}")"

    echo -e "${BOLD}=== LazyChad Uninstaller ===${NC}"
    echo "The following will be removed:"
    echo "  - Neovim installed under /usr/local (bin/lib/share/nvim)"
    echo "  - LazyChad binaries: lchad, lazychad-deps, lazychad-nvim, lazychad-uninstall"
    echo "  - System files: /usr/share/lazychad, /usr/share/doc/lazychad, /usr/share/licenses/lazychad"
    echo "  - User dirs: ~/.config/LazyChad and ~/.local/share|state, ~/.cache/LazyChad (all users)"
    echo -e "${YELLOW}Shared deps (Node, Rust, Neovide, fonts, -dev packages) will NOT be removed.${NC}"
    echo

    if ! confirm "Proceed with uninstall?"; then
        echo "Aborted."
        exit 0
    fi

    backup_user_config   # backup BEFORE any package-manager postremove runs
    remove_neovim        # remove nvim while lazychad-nvim still exists
    remove_lazychad

    echo -e "${GREEN}✅ LazyChad has been uninstalled.${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/test_lazychad_uninstall.sh`
Expected: all `ok`, exit 0.

- [ ] **Step 5: Syntax check**

Run: `bash -n bin/lazychad-uninstall && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 6: Commit**

```bash
git add bin/lazychad-uninstall tests/test_lazychad_uninstall.sh
git commit -m "feat: add install-method-aware lazychad-uninstall"
```

---

### Task 5: Package the new scripts + make `neovim` a Recommends

**Files:**
- Modify: `nfpm.yaml`
- Modify: `PKGBUILD`

**Interfaces:**
- Consumes: `bin/lazychad-nvim`, `bin/lazychad-uninstall` from Tasks 1–4.
- Produces: packaged `/usr/bin/lazychad-nvim`, `/usr/bin/lazychad-uninstall`.

- [ ] **Step 1: Add the new binaries to `nfpm.yaml` contents**

In `nfpm.yaml`, under `contents:` `# Binaries`, after the `lazychad-deps` entry, add:

```yaml
  - src: ./bin/lazychad-nvim
    dst: /usr/bin/lazychad-nvim
  - src: ./bin/lazychad-uninstall
    dst: /usr/bin/lazychad-uninstall
```

- [ ] **Step 2: Move `neovim` from `depends` to `recommends` in `nfpm.yaml`**

Replace the `depends:` block:

```yaml
depends:
  - neovim
  - git
  - ripgrep
  - curl
  - bash
  - make
  - unzip
  - gcc
```

with:

```yaml
depends:
  - git
  - ripgrep
  - curl
  - bash
  - make
  - unzip
  - gcc

# neovim is intentionally a soft recommendation, not a hard dependency.
# lazychad-nvim installs the latest Neovim to /usr/local; a hard Depends would
# let apt cascade-remove LazyChad when an external neovim is removed and drag
# the stale repo package back on reinstall.
recommends:
  - neovim
```

- [ ] **Step 3: Add the new binaries to `PKGBUILD` package()**

In `PKGBUILD`, after the `install -Dm755 bin/lazychad-deps "$pkgdir/usr/bin/lazychad-deps"` line, add:

```bash
  install -Dm755 bin/lazychad-nvim "$pkgdir/usr/bin/lazychad-nvim"
  install -Dm755 bin/lazychad-uninstall "$pkgdir/usr/bin/lazychad-uninstall"
```

- [ ] **Step 4: Validate YAML and shell syntax**

Run:
```bash
python -c "import yaml,sys; yaml.safe_load(open('nfpm.yaml')); print('YAML_OK')"
bash -n PKGBUILD && echo PKGBUILD_OK
```
Expected: `YAML_OK` and `PKGBUILD_OK`.

- [ ] **Step 5: Confirm neovim is no longer a hard depend and both scripts are packaged**

Run:
```bash
grep -n "lazychad-nvim\|lazychad-uninstall" nfpm.yaml PKGBUILD
python -c "import yaml; d=yaml.safe_load(open('nfpm.yaml')); assert 'neovim' not in d.get('depends',[]); assert 'neovim' in d.get('recommends',[]); print('DEPS_OK')"
```
Expected: each script path appears in both files; `DEPS_OK`.

- [ ] **Step 6: Commit**

```bash
git add nfpm.yaml PKGBUILD
git commit -m "build: package lazychad-nvim & lazychad-uninstall; neovim -> recommends"
```

---

### Task 6: Document the new commands + final verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: user-facing docs; full local verification gate.

- [ ] **Step 1: Add a "Managing Neovim & Uninstalling" section to `README.md`**

Add the following near the existing usage/installation docs (place it after the install/`lazychad-deps` instructions; keep heading style consistent with the surrounding file):

```markdown
## Managing Neovim

LazyChad bundles `lazychad-nvim`, which installs the latest **stable** Neovim
from the official GitHub release tarball into `/usr/local` (so it shadows any
distro `neovim` package via `PATH`). It detects your CPU (x86_64 / arm64) and
falls back to your distro package manager if the download is unavailable.

```bash
lazychad-nvim            # install or update to the latest Neovim
lazychad-nvim --uninstall  # remove the /usr/local Neovim install
```

`lazychad-deps` runs this automatically as its Neovim step.

## Uninstalling

```bash
lazychad-uninstall       # confirm + optional config backup, then remove
lazychad-uninstall --yes # skip prompts (scripted use)
```

This removes the bundled Neovim, the LazyChad binaries and files, and the
per-user LazyChad directories. It detects whether LazyChad was installed via
`apt`/`pacman` or manually and removes it the matching way. Shared tools
(Node, Rust, Neovide, fonts) are **not** removed.
```

- [ ] **Step 2: Run the full test + syntax gate**

Run:
```bash
bash tests/test_lazychad_nvim.sh && \
bash tests/test_lazychad_uninstall.sh && \
bash -n bin/lazychad-nvim && bash -n bin/lazychad-uninstall && bash -n bin/lazychad-deps && \
echo ALL_GREEN
```
Expected: all `ok` lines and `ALL_GREEN`.

- [ ] **Step 3: Mark scripts executable**

Run:
```bash
chmod +x bin/lazychad-nvim bin/lazychad-uninstall
git update-index --chmod=+x bin/lazychad-nvim bin/lazychad-uninstall 2>/dev/null || true
```
Expected: no error.

- [ ] **Step 4: Commit**

```bash
git add README.md bin/lazychad-nvim bin/lazychad-uninstall
git commit -m "docs: document lazychad-nvim and lazychad-uninstall"
```

- [ ] **Step 5: Manual verification checklist (run on a real Linux box; not gating CI)**

These cannot be exercised in the dev shell — record results when run on Kali (x86_64) and ideally an arm64 VM:

```text
[ ] Fresh install: build/install the package; `lchad` launches Neovim 0.12+.
[ ] `lazychad-nvim` prints "Already on latest" on a second run (idempotent).
[ ] After `lazychad-nvim`, `which -a nvim` shows /usr/local/bin/nvim first.
[ ] Reinstalling the LazyChad package does NOT downgrade nvim (recommends, not depends).
[ ] arm64 VM: `lazychad-nvim` downloads nvim-linux-arm64 and installs cleanly.
[ ] Simulated network failure: tarball step falls back to the package manager (or prints manual help) without aborting lazychad-deps.
[ ] `lazychad-uninstall` shows the removal list, offers a backup, and removes everything; Node/Rust/Neovide remain installed.
[ ] `lazychad-uninstall --yes` runs non-interactively.
```

---

## Self-Review

**Spec coverage:**
- Tarball-everywhere primary install → Task 1/2 (`install_tarball`, `install_or_update`). ✓
- Standalone bundled `bin/lazychad-nvim` → Tasks 1–2; packaged in Task 5. ✓
- Arch detection x86_64+arm64, else fallback → Task 1 `detect_arch`, Task 2 `install_or_update`. ✓
- Fallback chain tarball→native→warn → Task 2 `install_or_update`/`native_install_neovim`/`manual_help`. ✓
- Never `apt-get remove neovim` → no such call anywhere; `note_apt_neovim` documents leaving it; Task 3 Step 4 greps to confirm the old logic is gone. ✓
- `lazychad-deps` delegates → Task 3. ✓
- Full install-method-aware uninstaller, backup-first, `--yes`, leaves shared deps → Task 4. ✓
- Packaging both scripts + `neovim` recommends → Task 5. ✓
- Docs → Task 6. ✓
- Verification (`bash -n`, unit tests, resolver, manual Linux checks) → Tasks 1–6. ✓

**Placeholder scan:** No TBD/TODO; every code step contains full content; no "similar to Task N" references. ✓

**Type/name consistency:** `detect_arch`, `nvim_download_url`, `get_installed_version`, `get_latest_version`, `detect_os`, `cleanup_manual`, `install_tarball`, `install_or_update`, `uninstall_nvim`, `native_install_neovim`, `note_apt_neovim`, `manual_help`, `parse_yes`, `confirm`, `backup_user_config`, `remove_user_dirs`, `remove_neovim`, `remove_lazychad` — names are used consistently across tasks and tests. The `--uninstall` flag string matches between `lazychad-uninstall`'s `remove_neovim` caller and `lazychad-nvim`'s `main` dispatch. ✓
