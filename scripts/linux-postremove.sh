#!/bin/sh
# Post-removal script for Debian/RPM packages (deb postrm, rpm %postun).
#
# Packages shouldn't silently delete users' files: user dirs are only wiped on
# an explicit `apt purge` (or by `lazychad-uninstall`). This hook also runs on
# upgrades (dpkg "upgrade", RPM $1=1), where it must never touch them.

NVIM_RM_HINT="sudo rm -rf /usr/local/bin/nvim /usr/local/lib/nvim /usr/local/share/nvim /usr/local/share/applications/nvim.desktop /usr/local/share/man/man1/nvim.1"

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

is_abort() {
    # dpkg is unwinding a failed install/upgrade of this package.
    case "${1:-}" in
        abort-install|abort-upgrade) return 0 ;;
        *)                           return 1 ;;
    esac
}

lazychad_restore_user_data() {
    for home in ${LAZYCHAD_HOMES:-/home/* /root}; do
        [ -d "$home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad; do
            dir="$home/$sub"
            [ -d "$dir.pkg-upgrade" ] || continue
            if [ -e "$dir" ]; then
                echo "==> Kept your previous LazyChad data at $dir.pkg-upgrade ($dir already exists)"
            else
                mv "$dir.pkg-upgrade" "$dir" || echo "==> Warning: could not restore $dir from $dir.pkg-upgrade"
            fi
        done
    done
}

print_keep_note() {
    # $1 = "remove" (dpkg) or "0" (rpm)
    echo "==> LazyChad removed. Each user's config and plugins are kept in:"
    echo "      ~/.config/LazyChad  ~/.local/share/LazyChad  ~/.local/state/LazyChad  ~/.cache/LazyChad"
    if [ "${1:-}" = "remove" ]; then
        echo "==> To delete them for all users: sudo apt purge lazychad"
    else
        echo "==> To delete them: rm -rf ~/.config/LazyChad ~/.local/share/LazyChad ~/.local/state/LazyChad ~/.cache/LazyChad"
    fi
    echo "==> Neovim installed by lazychad-nvim under /usr/local was not removed. To remove it:"
    echo "      $NVIM_RM_HINT"
}

cleanup_user_dirs() {
    echo "==> Cleaning up LazyChad user directories..."
    for user_home in ${LAZYCHAD_HOMES:-/home/* /root}; do
        [ -d "$user_home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad \
                   .config/LazyChad.pkg-upgrade .local/share/LazyChad.pkg-upgrade \
                   .local/state/LazyChad.pkg-upgrade .cache/LazyChad.pkg-upgrade; do
            if [ -d "$user_home/$sub" ]; then
                echo "  -> Removing $user_home/$sub"
                rm -rf "${user_home:?}/$sub"
            fi
        done
    done
    echo "==> Neovim installed by lazychad-nvim under /usr/local was not removed. To remove it:"
    echo "      $NVIM_RM_HINT"
    echo "==> Done. LazyChad has been completely wiped from user directories."
}

if [ -z "${LAZYCHAD_HOOK_SOURCED:-}" ]; then
    if should_cleanup "${1:-}"; then
        cleanup_user_dirs
    elif is_removal "${1:-}"; then
        print_keep_note "${1:-}"
    elif is_abort "${1:-}"; then
        lazychad_restore_user_data
    fi
    exit 0
fi
