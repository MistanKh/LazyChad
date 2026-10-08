#!/usr/bin/env bash
# Unit tests for bin/lazychad-uninstall arg parsing. No sudo, no deletion.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/../bin/lazychad-uninstall"   # source-only: main must NOT run

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

assert_eq "$(parse_yes --yes)" "true"  "parse_yes --yes"
assert_eq "$(parse_yes -y)"    "true"  "parse_yes -y"
assert_eq "$(parse_yes '')"    "false" "parse_yes empty"
assert_eq "$(parse_yes --foo)" "false" "parse_yes unknown"

# lazychad-nvim and lazychad-uninstall must remove the same Neovim files
paths_of() { bash -c "source '$1'; declare -f nvim_tarball_paths"; }
assert_eq "$(paths_of "$HERE/../bin/lazychad-uninstall")" "$(paths_of "$HERE/../bin/lazychad-nvim")" \
  "nvim_tarball_paths identical in lazychad-uninstall and lazychad-nvim"

# a failed package removal stops before Neovim and user data are touched
log="$(mktemp)"
(
  confirm() { return 0; }
  backup_user_config() { :; }
  remove_lazychad_package() { echo pkg >> "$log"; return 1; }
  remove_neovim() { echo nvim >> "$log"; }
  remove_user_dirs() { echo dirs >> "$log"; }
  main --yes
) >/dev/null 2>&1
status=$?
assert_eq "$status" "1" "failed package removal exits 1"
assert_eq "$(tr '\n' ' ' < "$log")" "pkg " "nothing else runs after a failed package removal"
command rm -f "$log"

# user_dirs honours a custom XDG_DATA_HOME
tmpd="$(mktemp -d)"
mkdir -p "$tmpd/xdg-data/LazyChad"
assert_eq "$(LAZYCHAD_HOMES=/nonexistent XDG_DATA_HOME="$tmpd/xdg-data" user_dirs)" "$tmpd/xdg-data/LazyChad" \
  "user_dirs includes XDG_DATA_HOME/LazyChad"
mkdir -p "$tmpd/h/.config/LazyChad.pkg-upgrade"
assert_eq "$(LAZYCHAD_HOMES="$tmpd/h" XDG_DATA_HOME='' user_dirs)" "$tmpd/h/.config/LazyChad.pkg-upgrade" \
  "user_dirs includes leftover upgrade stashes"
command rm -rf "${tmpd:?}"

exit $fail
