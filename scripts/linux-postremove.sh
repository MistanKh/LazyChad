#!/bin/bash
# Post-removal script for Debian/RPM packages
#
# Packages shouldn't silently delete users' files: user dirs are only wiped on
# an explicit `apt purge` (or by `lazychad-uninstall`). This hook also runs on
# upgrades (dpkg "upgrade", RPM $1=1), where it must never touch them.

should_cleanup() {
    # $1 = dpkg postrm action ("remove", "purge", ...) or RPM install count.
    [ "${1:-}" = "purge" ]
}

is_removal() {
    case "${1:-}" in
        remove|0) return 0 ;;
        *)        return 1 ;;
    esac
}

print_keep_note() {
    echo "==> LazyChad removed. Your config and plugins were kept:"
    echo "      ~/.config/LazyChad  ~/.local/share/LazyChad  ~/.local/state/LazyChad  ~/.cache/LazyChad"
    echo "==> Delete them with 'rm -rf' on those paths, or use 'apt purge lazychad' next time."
    echo "==> Neovim installed via 'lazychad-nvim' under /usr/local is NOT removed."
}

cleanup_user_dirs() {
    local user_home sub
    echo "==> Cleaning up LazyChad user directories..."
    for user_home in /home/* /root; do
        [ -d "$user_home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad; do
            if [ -d "$user_home/$sub" ]; then
                echo "  -> Removing $user_home/$sub"
                rm -rf "${user_home:?}/$sub"
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
    elif is_removal "${1:-}"; then
        print_keep_note
    fi
    exit 0
fi
