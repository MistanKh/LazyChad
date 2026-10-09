#!/usr/bin/env bash
# Unit tests for bin/lazychad-deps helpers. No network, no sudo.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-deps"   # source-only: main must NOT run

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

# equivalents installed another way count as present
check_installed() { return 1; }                       # package manager says "not installed"
exists() { [ "$1" = node ] || [ "$1" = npm ] || [ "$1" = curl ]; }
assert_eq "$(is_present nodejs && echo yes || echo no)" "yes" "NodeSource/LTS node counts as nodejs"
assert_eq "$(is_present npm && echo yes || echo no)"    "yes" "bundled npm counts as npm"
assert_eq "$(is_present curl && echo yes || echo no)"   "yes" "curl-minimal counts as curl"
assert_eq "$(is_present ripgrep && echo yes || echo no)" "no" "missing ripgrep is still installed"
assert_eq "$(is_present libgl1 && echo yes || echo no)"  "no" "libraries rely on the package manager"
unset -f check_installed exists

# os-release fields are read without clobbering the script's variables
osr="$(mktemp)"
printf '%s\n' 'NAME="Rocky Linux"' 'VERSION="9.4 (Blue Onyx)"' 'ID="rocky"' 'ID_LIKE="rhel centos fedora"' > "$osr"
assert_eq "$(OS_RELEASE_FILE="$osr" os_release_field ID)" "rocky" "os_release_field ID"
assert_eq "$(detect_family "$(OS_RELEASE_FILE="$osr" os_release_field ID)" "$(OS_RELEASE_FILE="$osr" os_release_field ID_LIKE)")" \
  "fedora" "Rocky maps to the fedora family"
command rm -f "$osr"

# unknown distros get a best-effort run instead of exiting
export FAMILY="opensuse-tumbleweed"
assert_eq "$(set_family_packages && echo supported || echo unsupported)" "unsupported" "no package list for openSUSE"

# Neovide build deps: multilib only on x86_64
export FAMILY=debian
apt-cache() { return 1; }
uname() { echo aarch64; }
set_family_packages
assert_eq "$(printf '%s\n' "${NEOVIDE_BUILD_DEPS[@]}" | grep -c multilib)" "0" "no multilib packages on arm64"
uname() { echo x86_64; }
set_family_packages
assert_eq "$(printf '%s\n' "${NEOVIDE_BUILD_DEPS[@]}" | grep -c multilib)" "2" "multilib packages on x86_64"
unset -f uname apt-cache

# tree-sitter CLI: npm skipped the install script and running it fails too,
# so the binary is downloaded directly
ts="$(mktemp -d)"
mkdir -p "$ts/node_modules/tree-sitter-cli" "$ts/node_modules/.bin" "$ts/payload"
printf '{\n  "name": "tree-sitter-cli",\n  "version": "0.27.1"\n}\n' > "$ts/node_modules/tree-sitter-cli/package.json"
printf '#!/bin/sh\nexec "$(dirname "$0")/../tree-sitter-cli/tree-sitter" "$@"\n' > "$ts/node_modules/.bin/tree-sitter"
chmod +x "$ts/node_modules/.bin/tree-sitter"
printf '#!/bin/sh\necho "tree-sitter 0.27.1"\n' > "$ts/payload/tree-sitter"
gzip -c "$ts/payload/tree-sitter" > "$ts/payload/tree-sitter-linux-x64.gz"
assert_eq "$(
  NODE_PREFIX="$ts"
  node() { return 1; }
  uname() { echo x86_64; }
  github_api() { return 1; }
  curl() { local out="" a prev=""; for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done
           case "$*" in *v0.27.1/tree-sitter-linux-x64.gz*) cp "$ts/payload/tree-sitter-linux-x64.gz" "$out" ;; *) return 22 ;; esac; }
  tree_sitter_runs && echo before
  fetch_tree_sitter_binary && "$NODE_PREFIX/node_modules/.bin/tree-sitter" --version
)" "tree-sitter 0.27.1" "tree-sitter binary is fetched when npm skipped it"
command rm -rf "${ts:?}"

exit $fail
