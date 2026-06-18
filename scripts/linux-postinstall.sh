#!/bin/bash
# Post-installation script for Debian/RPM packages

echo "==> LazyChad has been successfully installed."
echo ""
echo "==> REQUIRED NEXT STEP: run 'lazychad-deps' as your normal user."
echo "    Your distro's Neovim is likely too old (LazyChad needs 0.12+)."
echo "    'lazychad-deps' installs Neovim nightly (0.12+) to /usr/local"
echo "    and sets up the Node, Python, and Rust providers:"
echo ""
echo "        lazychad-deps"
echo ""
echo "==> Then start the editor with: lchad"
