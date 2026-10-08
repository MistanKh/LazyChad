#!/bin/bash
# Post-removal script for Debian/RPM packages
#
# This hook also runs during upgrades: dpkg calls postrm with "upgrade", and
# RPM runs %postun with $1=1. Only wipe user dirs on a real removal, otherwise
# every package upgrade would delete ~/.config/LazyChad before lchad can offer
# its backup-and-sync.

should_cleanup() {
    # $1 = dpkg postrm action ("remove", "purge", ...) or RPM install count.
    case "${1:-}" in
        remove|purge|0) return 0 ;;
        *)              return 1 ;;
    esac
}

cleanup_user_dirs() {
    local user_home sub
    echo "==> Cleaning up LazyChad user directories..."
    for user_home in /home/* /root; do
        [ -d "$user_home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad; do
            if [ -d "$user_home/$sub" ]; then
                echo "  -> Removing $user_home/$sub"
                rm -rf "$user_home/$sub"
            fi
        done
    done
    echo "==> Note: Neovim installed via 'lazychad-nvim' under /usr/local is NOT removed."
    echo "==>       Run 'lazychad-nvim --uninstall' to remove it."
    echo "==> Done. LazyChad has been completely wiped from user directories."
}

if [ -z "${LAZYCHAD_POSTREMOVE_SOURCED:-}" ]; then
    if should_cleanup "${1:-}"; then
        cleanup_user_dirs
    fi
    exit 0
fi
