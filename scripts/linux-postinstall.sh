#!/bin/sh
# Post-installation script for Debian/RPM packages (deb postinst, rpm %post).

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

print_next_steps() {
    echo "==> LazyChad has been successfully installed."
    echo ""
    echo "==> REQUIRED NEXT STEP: run 'lazychad-deps' as your normal user."
    echo "    Your distro's Neovim is likely too old (LazyChad needs 0.12+)."
    echo "    'lazychad-deps' installs the latest stable Neovim (0.12+) to /usr/local,"
    echo "    the Node and Python providers, and all plugins:"
    echo ""
    echo "        lazychad-deps"
    echo ""
    echo "==> Then start the editor with: lchad   (check your setup: lchad --doctor)"
}

if [ -z "${LAZYCHAD_HOOK_SOURCED:-}" ]; then
    # dpkg: the old postrm has already run by "configure", so restore now.
    # rpm %post runs BEFORE the old %postun; restoring happens in %posttrans.
    [ "${1:-}" = "configure" ] && lazychad_restore_user_data
    print_next_steps
    exit 0
fi
