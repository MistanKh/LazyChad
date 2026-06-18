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

# nightly URL uses the 'nightly' tag (no version)
assert_eq "$(nvim_nightly_url nvim-linux-x86_64)" \
  "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz" \
  "nvim_nightly_url uses nightly tag"

# nightly_hash_of extracts the g<hash> from a -dev version line
assert_eq "$(nightly_hash_of 'NVIM v0.13.0-dev-752+gb8e3f3f4e0')" "b8e3f3f4e0" \
  "nightly_hash_of extracts commit hash"
assert_eq "$(nightly_hash_of 'NVIM v0.11.4')" "" \
  "nightly_hash_of empty for stable version"

# version_ge_min: LazyChad needs 0.12+
assert_eq "$(version_ge_min 0.12.0 && echo yes || echo no)" "yes" "version_ge_min 0.12.0 ok"
assert_eq "$(version_ge_min 0.13.0 && echo yes || echo no)" "yes" "version_ge_min 0.13.0 ok"
assert_eq "$(version_ge_min 1.0.0  && echo yes || echo no)" "yes" "version_ge_min 1.0.0 ok"
assert_eq "$(version_ge_min 0.11.4 && echo yes || echo no)" "no"  "version_ge_min 0.11.4 too old"
assert_eq "$(version_ge_min 0.9.5  && echo yes || echo no)" "no"  "version_ge_min 0.9.5 too old"
assert_eq "$(version_ge_min none   && echo yes || echo no)" "no"  "version_ge_min none too old"

# cleanup_manual must succeed even when nothing exists (sudo/rm stubbed)
sudo() { "$@"; }            # drop the privilege escalation in tests
rm() { :; }                 # no-op rm so the test never deletes anything
assert_eq "$(cleanup_manual >/dev/null 2>&1; echo $?)" "0" "cleanup_manual returns 0 when clean"
unset -f sudo rm

exit $fail
