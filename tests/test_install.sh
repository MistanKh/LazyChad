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

# os-release is read without clobbering the script's own variables
osr="$(mktemp)"
printf '%s\n' 'NAME="Ubuntu"' 'VERSION="24.04.5 LTS (Noble Numbat)"' 'ID=ubuntu' 'ID_LIKE=debian' > "$osr"
assert_eq "$(OS_RELEASE_FILE="$osr" os_release_field ID)" "ubuntu" "os_release_field ID"
assert_eq "$(OS_RELEASE_FILE="$osr" os_release_field ID_LIKE)" "debian" "os_release_field ID_LIKE"
assert_eq "$(OS_RELEASE_FILE=/nonexistent os_release_field ID)" "" "os_release_field missing file"

# argument parsing happens before anything is installed
assert_eq "$(parse_args --version v1.2.3; echo "$LAZYCHAD_VERSION")" "1.2.3" "--version strips a leading v"
assert_eq "$(parse_args --version=1.2.3; echo "$LAZYCHAD_VERSION")" "1.2.3" "--version=X form"
assert_eq "$(parse_args --gui --nightly; echo "${DEPS_ARGS[*]}")" "--gui --nightly" "known flags pass through"
assert_eq "$( (parse_args --gu) >/dev/null 2>&1; echo $?)" "1" "unknown flag dies"
assert_eq "$( (parse_args --version 1.2) >/dev/null 2>&1; echo $?)" "1" "malformed --version dies"

# main() end to end with stubs, on an os-release that defines VERSION
log="$(mktemp)"
(
  export OS_RELEASE_FILE="$osr"
  is_root() { return 1; }
  uname() { echo Linux; }
  sudo() { echo "sudo $*" >> "$log"; }
  lazychad-deps() { echo "deps $*" >> "$log"; }
  curl() {
    local out="" a
    for a in "$@"; do [ "${prev:-}" = "-o" ] && out="$a"; prev="$a"; done
    case "$*" in
      *-w*url_effective*) echo "https://github.com/MistanKh/LazyChad/releases/tag/v1.0.9" ;;
      *releases/download/*.deb*) echo "download $*" >> "$log"; echo pkg > "$out" ;;
      *) return 22 ;;
    esac
  }
  main --gui
) >/dev/null 2>&1
assert_eq "$(grep -c 'releases/download/v1.0.9/lazychad_1.0.9-1_all.deb' "$log")" "1" "main downloads the LazyChad release, not the distro VERSION"
assert_eq "$(grep -c '^sudo apt-get update' "$log")" "1" "main refreshes apt lists before installing"
assert_eq "$(grep -c '^sudo apt-get install -y .*lazychad_1.0.9-1_all.deb' "$log")" "1" "main installs the downloaded .deb"
assert_eq "$(grep -c '^deps --gui' "$log")" "1" "main passes flags to lazychad-deps"
command rm -f "$osr" "$log"

# install.sh and lazychad-deps must map distros the same way
install_family="$(declare -f detect_family)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-deps"
for id in arch manjaro debian ubuntu pop kali fedora rocky nobara; do
  assert_eq "$(detect_family "$id" '')" "$(eval "$install_family"; detect_family "$id" '')" "deps/install agree on $id"
done

exit $fail
