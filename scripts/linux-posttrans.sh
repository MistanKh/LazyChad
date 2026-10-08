#!/bin/sh
# RPM %posttrans: runs after the whole transaction, i.e. after the old
# package's %postun. Puts back the user data linux-preinstall.sh set aside.

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

if [ -z "${LAZYCHAD_HOOK_SOURCED:-}" ]; then
    lazychad_restore_user_data
    exit 0
fi
