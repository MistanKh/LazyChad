#!/usr/bin/env bash
# LazyChad one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/MistanKh/LazyChad/main/install.sh | bash
#
# Installs the latest LazyChad release with your system package manager (AUR
# on Arch, .deb on Debian/Ubuntu, .rpm on Fedora/RHEL), then runs
# 'lazychad-deps' so Neovim 0.12+, the tools and all plugins are ready before
# the first launch.
#
# Options go after `bash -s --` (e.g. `| bash -s -- --gui`); see --help.

set -euo pipefail

REPO="MistanKh/LazyChad"
BOLD="\033[1m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; NC="\033[0m"

info() { echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
die()  { echo -e "${RED}❌ $*${NC}" >&2; exit 1; }

detect_family() {
    # $1=ID  $2=ID_LIKE (kept in sync with lazychad-deps)
    case "$1" in
        arch|cachyos|manjaro|endeavouros|garuda|arcolinux|artix) echo "arch" ;;
        debian|ubuntu|pop|kali|linuxmint|elementary|zorin|raspbian|devuan|mx|parrot) echo "debian" ;;
        fedora|rhel|centos|rocky|almalinux|ol|nobara) echo "fedora" ;;
        *)
            case " $2 " in
                *arch*)                   echo "arch" ;;
                *debian*|*ubuntu*)        echo "debian" ;;
                *fedora*|*rhel*|*centos*) echo "fedora" ;;
                *)                        echo "unsupported" ;;
            esac
            ;;
    esac
}

package_asset() {
    # $1=family $2=version -> release asset file name (matches nfpm output)
    case "$1" in
        debian) echo "lazychad_${2}-1_all.deb" ;;
        fedora) echo "lazychad-${2}-1.noarch.rpm" ;;
        *)      return 1 ;;
    esac
}

version_from_release_url() {
    # .../releases/tag/v1.2.3 -> 1.2.3
    local tag="${1##*/}"
    tag="${tag#v}"
    [[ "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    echo "$tag"
}

latest_version() {
    local url
    url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest")" || return 1
    version_from_release_url "$url"
}

release_asset_digest() {
    # $1=release JSON file (GitHub API)  $2=asset name; prints its sha256 or nothing.
    # (Same parser as lazychad-nvim; this script must stay standalone.)
    tr ',{}' '\n\n\n' < "$1" | awk -v want="\"$2\"" '
        /"name"[[:space:]]*:/ { cur = $0; sub(/^[^:]*:[[:space:]]*/, "", cur); gsub(/[[:space:]]+$/, "", cur) }
        /"digest"[[:space:]]*:[[:space:]]*"sha256:/ && cur == want {
            sub(/.*"sha256:/, ""); sub(/".*/, ""); print; exit
        }'
}

expected_sha256() {
    # $1=dir $2=asset. GitHub's per-asset digest first, then the release's SHA256SUMS.
    local dir="$1" asset="$2" auth=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    if curl -fsSL "${auth[@]+"${auth[@]}"}" "https://api.github.com/repos/$REPO/releases/tags/v$LAZYCHAD_VERSION" \
            -o "$dir/release.json" 2>/dev/null; then
        release_asset_digest "$dir/release.json" "$asset"
        return 0
    fi
    if curl -fsSL "https://github.com/$REPO/releases/download/v$LAZYCHAD_VERSION/SHA256SUMS" -o "$dir/SHA256SUMS" 2>/dev/null; then
        awk -v name="$asset" '$2 == name { print $1; exit }' "$dir/SHA256SUMS"
    fi
}

verify_download() {
    # $1=dir $2=asset
    local dir="$1" asset="$2" expected actual
    expected="$(expected_sha256 "$dir" "$asset")"
    if [ -z "$expected" ]; then
        warn "Could not fetch a published checksum for $asset; skipping verification."
        return 0
    fi
    actual="$(sha256sum "$dir/$asset" | awk '{ print $1 }')"
    [ "$actual" = "$expected" ] || die "Checksum mismatch for $asset; aborting."
    echo -e "${GREEN}Checksum verified.${NC}"
}

install_arch() {
    if command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm lazychad
    elif command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm lazychad
    else
        info "No AUR helper found; building the AUR package with makepkg"
        sudo pacman -S --needed --noconfirm base-devel git
        git clone --depth 1 https://aur.archlinux.org/lazychad.git "$WORK_DIR/lazychad"
        (cd "$WORK_DIR/lazychad" && makepkg -si --noconfirm)
    fi
}

epel_enabled() {
    dnf repolist --enabled 2>/dev/null | grep -qi '^epel'
}

epel_help() {
    # $1=ID (rhel, rocky, almalinux, ol, centos)
    echo "LazyChad needs packages from EPEL (ripgrep, fd-find, ...) on $1. Enable it first:"
    case "$1" in
        rhel) echo '  sudo subscription-manager repos --enable "codeready-builder-for-rhel-$(rpm -E %rhel)-$(arch)-rpms"'
              echo '  sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm"' ;;
        ol)   echo '  sudo dnf install -y "oracle-epel-release-el$(rpm -E %rhel)"' ;;
        *)    echo '  sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb' ;;
    esac
}

install_release_package() {
    local family="$1" asset
    asset="$(package_asset "$family" "$LAZYCHAD_VERSION")"
    chmod 755 "$WORK_DIR"   # let apt's sandbox user read the file
    info "Downloading $asset"
    curl -fSL "https://github.com/$REPO/releases/download/v$LAZYCHAD_VERSION/$asset" -o "$WORK_DIR/$asset" \
        || die "Download failed. Is v$LAZYCHAD_VERSION a published release?"
    verify_download "$WORK_DIR" "$asset"
    info "Installing $asset"
    if [ "$family" = "debian" ]; then
        # Fresh images ship without package lists, so dependencies can't resolve.
        sudo apt-get update || warn "apt-get update failed; trying the install anyway."
        sudo apt-get install -y "$WORK_DIR/$asset"
    else
        sudo dnf install -y "$WORK_DIR/$asset"
    fi
}

is_root() { [ "$EUID" -eq 0 ]; }

os_release_field() {
    # $1=field. Read in a subshell: sourcing os-release here would clobber
    # this script's variables (it defines NAME, VERSION, ...).
    local file="${OS_RELEASE_FILE:-/etc/os-release}"
    [ -f "$file" ] || return 0
    # shellcheck source=/dev/null
    ( . "$file"; eval "printf '%s' \"\${$1:-}\"" )
}

usage() {
    cat <<'USAGE'
LazyChad one-line installer

  curl -fsSL https://raw.githubusercontent.com/MistanKh/LazyChad/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/MistanKh/LazyChad/main/install.sh | bash -s -- [options]

Options:
  --version X.Y.Z   Install a specific release instead of the latest (not on Arch)
  --no-deps         Only install the package; skip 'lazychad-deps'
  --gui, --nightly, --skip-nvim, --no-bootstrap
                    Passed to lazychad-deps
  -h, --help        Show this help
USAGE
}

parse_args() {
    LAZYCHAD_VERSION=""
    RUN_DEPS=true
    DEPS_ARGS=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --version)   LAZYCHAD_VERSION="${2:-}"; [ -n "$LAZYCHAD_VERSION" ] || die "--version needs a value"; shift ;;
            --version=*) LAZYCHAD_VERSION="${1#--version=}" ;;
            --no-deps)   RUN_DEPS=false ;;
            --gui|--stable|--nightly|--skip-nvim|--no-bootstrap) DEPS_ARGS+=("$1") ;;
            -h|--help)   usage; exit 0 ;;
            *)           die "Unknown option: $1 (see --help)" ;;
        esac
        shift
    done
    LAZYCHAD_VERSION="${LAZYCHAD_VERSION#v}"
    if [ -n "$LAZYCHAD_VERSION" ] && ! [[ "$LAZYCHAD_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        die "--version expects X.Y.Z, got '$LAZYCHAD_VERSION'"
    fi
}

main() {
    parse_args "$@"

    [ "$(uname -s)" = "Linux" ] || die "LazyChad's installer supports Linux only."
    ! is_root || die "Run this as your normal user (not root); it uses sudo when needed."
    command -v curl >/dev/null 2>&1 || die "curl is required."

    local os_id os_like family
    os_id="$(os_release_field ID)"
    os_like="$(os_release_field ID_LIKE)"
    family="$(detect_family "$os_id" "$os_like")"
    [ "$family" != "unsupported" ] || die "Unsupported distro '$os_id'. See the manual install steps: https://github.com/$REPO#option-4-manual-installation"

    if [ "$family" = "fedora" ] && [ "$os_id" != "fedora" ] && ! epel_enabled; then
        epel_help "$os_id"
        die "EPEL is not enabled; enable it and re-run the installer."
    fi

    echo -e "${BOLD}${BLUE}🚀 Installing LazyChad${NC} (${os_id:-linux}, $family family)"

    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf -- "${WORK_DIR:-}"' EXIT

    if [ "$family" = "arch" ]; then
        [ -z "$LAZYCHAD_VERSION" ] || warn "--version is ignored on Arch; the AUR package is always the latest release."
        install_arch
    else
        if [ -z "$LAZYCHAD_VERSION" ]; then
            LAZYCHAD_VERSION="$(latest_version)" || die "Could not determine the latest LazyChad release (network?)."
        fi
        install_release_package "$family"
    fi
    echo -e "${GREEN}✅ LazyChad package installed.${NC}"

    local deps_ok=true
    if [ "$RUN_DEPS" = true ]; then
        info "Running lazychad-deps (Neovim 0.12+, tools, plugins)"
        lazychad-deps "${DEPS_ARGS[@]+"${DEPS_ARGS[@]}"}" || deps_ok=false
    else
        warn "Skipped lazychad-deps. Run it before first use: lazychad-deps"
    fi

    echo
    if [ "$deps_ok" = true ]; then
        echo -e "${GREEN}${BOLD}✨ Done!${NC} Start LazyChad with: ${BOLD}lchad${NC}"
    else
        echo -e "${YELLOW}${BOLD}⚠️  Installed, but lazychad-deps reported issues${NC} (see its summary above)."
        echo -e "   Fix them and re-run ${BOLD}lazychad-deps${NC}, then start LazyChad with ${BOLD}lchad${NC}."
    fi
    echo -e "   Check your setup any time with: ${BOLD}lchad --doctor${NC}"
}

# Wrapped in main and called last, so a truncated `curl | bash` download
# never runs a partial script.
if [ -z "${LAZYCHAD_INSTALL_SOURCED:-}" ]; then
    main "$@"
fi
