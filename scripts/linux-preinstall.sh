#!/bin/sh
# Pre-installation script for Debian/RPM packages (deb preinst, rpm %pre).
#
# LazyChad 1.0.9 and earlier shipped a postrm/%postun that deleted every
# user's LazyChad config and data, and the OLD package's script still runs
# during an upgrade. So on upgrade, move those dirs aside first; the deb
# postinst / rpm %posttrans move them back once the old script has run.

lazychad_stash_user_data() {
    for home in ${LAZYCHAD_HOMES:-/home/* /root}; do
        [ -d "$home" ] || continue
        for sub in .config/LazyChad .local/share/LazyChad .local/state/LazyChad .cache/LazyChad; do
            dir="$home/$sub"
            if [ -d "$dir" ] && [ ! -e "$dir.pkg-upgrade" ]; then
                mv "$dir" "$dir.pkg-upgrade" || echo "==> Warning: could not protect $dir during the upgrade"
            fi
        done
    done
}

if [ -z "${LAZYCHAD_HOOK_SOURCED:-}" ]; then
    case "${1:-}" in
        upgrade|2) lazychad_stash_user_data ;;   # dpkg "upgrade", rpm $1 >= 2
    esac
    exit 0
fi
