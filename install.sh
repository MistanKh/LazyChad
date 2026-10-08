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
# Options (pass after `bash -s --`):
#   --version X.Y.Z   Install a specific release instead of the latest
#   --no-deps         Only install the package; skip 'lazychad-deps'
#   anything else     Passed to lazychad-deps (e.g. --gui, --stable)

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

verify_download() {
    # $1=dir $2=asset. Checks SHA256SUMS from the release when it has one.
    local dir="$1" asset="$2" expected actual
    if ! curl -fsSL "https://github.com/$REPO/releases/download/v$VERSION/SHA256SUMS" -o "$dir/SHA256SUMS"; then
        warn "This release has no SHA256SUMS; skipping checksum verification."
        return 0
    fi
    expected="$(awk -v name="$asset" '$2 == name { print $1; exit }' "$dir/SHA256SUMS")"
    [ -n "$expected" ] || die "$asset is not listed in SHA256SUMS."
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
        local tmp
        tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/lazychad.git "$tmp/lazychad"
        (cd "$tmp/lazychad" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
}

install_release_package() {
    local family="$1" asset tmp
    asset="$(package_asset "$family" "$VERSION")"
    tmp="$(mktemp -d)"
    chmod 755 "$tmp"   # let apt's sandbox user read the file
    info "Downloading $asset"
    curl -fSL "https://github.com/$REPO/releases/download/v$VERSION/$asset" -o "$tmp/$asset" \
        || die "Download failed. Is v$VERSION a published release?"
    verify_download "$tmp" "$asset"
    info "Installing $asset"
    if [ "$family" = "debian" ]; then
        sudo apt-get install -y "$tmp/$asset"
    else
        sudo dnf install -y "$tmp/$asset"
    fi
    rm -rf "$tmp"
}

main() {
    VERSION=""
    local run_deps=true deps_args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --version) VERSION="${2:-}"; [ -n "$VERSION" ] || die "--version needs a value"; shift ;;
            --no-deps) run_deps=false ;;
            *)         deps_args+=("$1") ;;
        esac
        shift
    done

    [ "$(uname -s)" = "Linux" ] || die "LazyChad's installer supports Linux only."
    [ "$EUID" -ne 0 ] || die "Run this as your normal user (not root); it uses sudo when needed."
    command -v curl >/dev/null 2>&1 || die "curl is required."

    local ID="" ID_LIKE=""
    # shellcheck source=/dev/null
    [ -f /etc/os-release ] && . /etc/os-release
    local family
    family="$(detect_family "$ID" "$ID_LIKE")"
    [ "$family" != "unsupported" ] || die "Unsupported distro '$ID'. See the manual install steps: https://github.com/$REPO#option-4-manual-installation-any-linux"

    echo -e "${BOLD}${BLUE}🚀 Installing LazyChad${NC} (${ID:-linux}, $family family)"

    if [ "$family" = "arch" ]; then
        [ -z "$VERSION" ] || warn "--version is ignored on Arch; the AUR package is always the latest release."
        install_arch
    else
        if [ -z "$VERSION" ]; then
            VERSION="$(latest_version)" || die "Could not determine the latest LazyChad release (network?)."
        fi
        install_release_package "$family"
    fi
    echo -e "${GREEN}✅ LazyChad package installed.${NC}"

    if [ "$run_deps" = true ]; then
        info "Running lazychad-deps (Neovim 0.12+, tools, plugins)"
        lazychad-deps "${deps_args[@]+"${deps_args[@]}"}" \
            || warn "lazychad-deps reported issues; see its summary above."
    else
        warn "Skipped lazychad-deps. Run it before first use: lazychad-deps"
    fi

    echo
    echo -e "${GREEN}${BOLD}✨ Done!${NC} Start LazyChad with: ${BOLD}lchad${NC}"
    echo -e "   Check your setup any time with: ${BOLD}lchad --doctor${NC}"
}

# Wrapped in main and called last, so a truncated `curl | bash` download
# never runs a partial script.
if [ -z "${LAZYCHAD_INSTALL_SOURCED:-}" ]; then
    main "$@"
fi
