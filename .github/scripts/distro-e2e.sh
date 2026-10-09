#!/bin/bash
# End-to-end LazyChad install on a fresh distro container, the way a user
# does it: install the package (built from the PKGBUILD on Arch), then run
# lazychad-deps and boot LazyChad as a normal sudo user. Fails on any error.
#
# Run as root by CI:  distro-e2e.sh <dir with the built .deb/.rpm>
set -euo pipefail

PKG_DIR="$(cd "${1:?usage: distro-e2e.sh <package dir>}" && pwd)"
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TEST_USER=tester

os_field() { ( . /etc/os-release; eval "printf '%s' \"\${$1:-}\"" ); }
OS_ID="$(os_field ID)"
OS_LIKE="$(os_field ID_LIKE)"

case " $OS_ID $OS_LIKE " in
    *" arch "*)                       FAMILY=arch ;;
    *" debian "*|*" ubuntu "*)        FAMILY=debian ;;
    *" fedora "*|*" rhel "*)          FAMILY=fedora ;;
    *) echo "No test recipe for $OS_ID"; exit 1 ;;
esac

echo "::group::Prepare $OS_ID ($FAMILY)"
case "$FAMILY" in
    arch)
        # fontconfig only for the fc-list check below
        pacman -Syu --noconfirm --needed base-devel git sudo fontconfig
        ;;
    debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y sudo ca-certificates curl
        ;;
    fedora)
        dnf install -y sudo shadow-utils
        if [ "$OS_ID" != fedora ]; then
            # Enterprise Linux: the documented prerequisite
            dnf install -y epel-release dnf-plugins-core
            dnf config-manager --set-enabled crb
        fi
        ;;
esac
useradd -m -s /bin/bash "$TEST_USER"
echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$TEST_USER"
chmod 440 "/etc/sudoers.d/$TEST_USER"
echo "::endgroup::"

echo "::group::Install the LazyChad package"
case "$FAMILY" in
    debian) apt-get install -y "$PKG_DIR"/lazychad_*_all.deb ;;
    fedora) dnf install -y "$PKG_DIR"/lazychad-*.noarch.rpm ;;
    arch)
        # Build this checkout with the real PKGBUILD: makepkg uses a source
        # tarball already present instead of downloading the tagged release.
        ver="$(tr -d '[:space:]' < "$REPO_DIR/.version")"
        build="/home/$TEST_USER/aur"
        stage="$(mktemp -d)"
        mkdir -p "$build"
        cp "$REPO_DIR/PKGBUILD" "$REPO_DIR/lazychad.install" "$build/"
        cp -a "$REPO_DIR" "$stage/LazyChad-$ver"
        rm -rf "${stage:?}/LazyChad-$ver/.git"
        tar -C "$stage" -czf "$build/lazychad-$ver.tar.gz" "LazyChad-$ver"
        rm -rf "${stage:?}"
        chown -R "$TEST_USER:" "$build"
        sudo -u "$TEST_USER" -H bash -lc 'cd ~/aur && makepkg -si --noconfirm'
        ;;
esac
command -v lchad lazychad-deps lazychad-nvim lazychad-uninstall
echo "::endgroup::"

# Everything a user runs, as that user.
sudo -u "$TEST_USER" -H --preserve-env=GITHUB_TOKEN bash -l <<'USER_STEPS'
set -euo pipefail
cd ~

echo "::group::lazychad-deps"
lazychad-deps
echo "::endgroup::"

echo "::group::Checks"
lchad --doctor
nvim --version | head -1
nvim --version | head -1 | grep -qv -- '-dev'                     # stable Neovim
grep -F "Checksum verified." ~/.local/state/LazyChad/lazychad-deps.log
fc-list | grep -i "JetBrainsMono Nerd Font"
echo "::endgroup::"

echo "::group::Boot without errors"
printf 'local x = 1\nreturn x\n' > sample.lua
lchad --headless sample.lua \
    -c 'sleep 5' \
    -c 'lua if vim.v.errmsg ~= "" then io.stderr:write("startup error: " .. vim.v.errmsg .. "\n") vim.cmd "cquit 1" end' \
    -c 'qa!'
echo "::endgroup::"
USER_STEPS

echo "✅ LazyChad installs and boots on $OS_ID"
