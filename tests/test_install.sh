#!/usr/bin/env bash
# Unit tests for install.sh and lazychad-deps pure helpers. No network, no sudo.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
export LAZYCHAD_INSTALL_SOURCED=1
# shellcheck source=/dev/null
source "$HERE/../install.sh"   # source-only: main must NOT run
set +e

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

assert_eq "$(detect_family arch '')"            "arch"        "family arch"
assert_eq "$(detect_family endeavouros '')"     "arch"        "family endeavouros"
assert_eq "$(detect_family kali '')"            "debian"      "family kali"
assert_eq "$(detect_family linuxmint '')"       "debian"      "family linuxmint"
assert_eq "$(detect_family rocky '')"           "fedora"      "family rocky"
assert_eq "$(detect_family foo 'ubuntu debian')" "debian"     "family via ID_LIKE"
assert_eq "$(detect_family opensuse-leap 'suse opensuse')" "unsupported" "family unsupported"

assert_eq "$(package_asset debian 1.2.3)" "lazychad_1.2.3-1_all.deb"   "deb asset name"
assert_eq "$(package_asset fedora 1.2.3)" "lazychad-1.2.3-1.noarch.rpm" "rpm asset name"
assert_eq "$(package_asset arch 1.2.3 || echo none)" "none"             "no asset for arch"

assert_eq "$(version_from_release_url https://github.com/MistanKh/LazyChad/releases/tag/v1.0.9)" "1.0.9" \
  "version from release URL"
assert_eq "$(version_from_release_url https://github.com/MistanKh/LazyChad/releases || echo none)" "none" \
  "no version without a tag"

# digest parser must match lazychad-nvim's copy exactly
install_digest="$(declare -f release_asset_digest)"
nvim_digest="$(bash -c "source '$HERE/../bin/lazychad-nvim'; declare -f release_asset_digest")"
assert_eq "$install_digest" "$nvim_digest" "release_asset_digest identical in install.sh and lazychad-nvim"
deps_digest="$(bash -c "source '$HERE/../bin/lazychad-deps'; declare -f release_asset_digest")"
assert_eq "$deps_digest" "$nvim_digest" "release_asset_digest identical in lazychad-deps and lazychad-nvim"

# install.sh and lazychad-deps must map distros the same way
install_family="$(declare -f detect_family)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-deps"
for id in arch manjaro debian ubuntu pop kali fedora rocky nobara; do
  assert_eq "$(detect_family "$id" '')" "$(eval "$install_family"; detect_family "$id" '')" "deps/install agree on $id"
done

exit $fail
