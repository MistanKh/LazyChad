#!/usr/bin/env bash
# Unit tests for bin/lazychad-nvim pure logic. No network, no sudo.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-nvim"   # source-only: main must NOT run

fail=0
assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi
}

# detect_arch maps uname -m values
uname() { echo "x86_64"; }; assert_eq "$(detect_arch)" "nvim-linux-x86_64" "detect_arch x86_64"
uname() { echo "amd64"; };  assert_eq "$(detect_arch)" "nvim-linux-x86_64" "detect_arch amd64"
uname() { echo "aarch64"; };assert_eq "$(detect_arch)" "nvim-linux-arm64"  "detect_arch aarch64"
uname() { echo "arm64"; };  assert_eq "$(detect_arch)" "nvim-linux-arm64"  "detect_arch arm64"
uname() { echo "riscv64"; };assert_eq "$(detect_arch)" "unsupported"       "detect_arch riscv64"
unset -f uname

# download URL includes the v prefix
assert_eq "$(nvim_download_url nvim-linux-x86_64 0.12.0)" \
  "https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-x86_64.tar.gz" \
  "nvim_download_url has v prefix"

exit $fail
