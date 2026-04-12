#!/bin/bash
# Post-removal script for Debian/RPM packages

echo "==> Cleaning up LazyChad user directories..."

# Loop through all home directories
for user_home in /home/*; do
    if [ -d "$user_home/.config/LazyChad" ]; then
        echo "  -> Removing $user_home/.config/LazyChad"
        rm -rf "$user_home/.config/LazyChad"
    fi
    if [ -d "$user_home/.local/share/LazyChad" ]; then
        echo "  -> Removing $user_home/.local/share/LazyChad"
        rm -rf "$user_home/.local/share/LazyChad"
    fi
    if [ -d "$user_home/.local/state/LazyChad" ]; then
        echo "  -> Removing $user_home/.local/state/LazyChad"
        rm -rf "$user_home/.local/state/LazyChad"
    fi
    if [ -d "$user_home/.cache/LazyChad" ]; then
        echo "  -> Removing $user_home/.cache/LazyChad"
        rm -rf "$user_home/.cache/LazyChad"
    fi
done

# Also check root
if [ -d "/root/.config/LazyChad" ]; then
    rm -rf "/root/.config/LazyChad" "/root/.local/share/LazyChad" "/root/.local/state/LazyChad" "/root/.cache/LazyChad"
fi

echo "==> Done. LazyChad has been completely wiped from user directories."
