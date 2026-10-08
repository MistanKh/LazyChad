#!/usr/bin/env bash
# Unit tests for scripts/linux-postremove.sh. No deletion: only checks which
# package-manager actions trigger user-dir cleanup.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
export LAZYCHAD_HOOK_SOURCED=1
# shellcheck source=/dev/null
source "$HERE/../scripts/linux-postremove.sh"   # source-only: cleanup must NOT run

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }
cleans() { should_cleanup "$1" && echo yes || echo no; }

assert_eq "$(cleans purge)"          "yes" "dpkg purge cleans"
assert_eq "$(cleans remove)"         "no"  "dpkg remove keeps user dirs"
assert_eq "$(cleans 0)"              "no"  "rpm erase keeps user dirs"
assert_eq "$(cleans upgrade)"        "no"  "dpkg upgrade keeps user dirs"
assert_eq "$(cleans failed-upgrade)" "no"  "dpkg failed-upgrade keeps user dirs"
assert_eq "$(cleans abort-install)"  "no"  "dpkg abort-install keeps user dirs"
assert_eq "$(cleans 1)"              "no"  "rpm upgrade keeps user dirs"
assert_eq "$(cleans '')"             "no"  "no argument keeps user dirs"

removal() { is_removal "$1" && echo yes || echo no; }
assert_eq "$(removal remove)"  "yes" "dpkg remove prints keep note"
assert_eq "$(removal 0)"       "yes" "rpm erase prints keep note"
assert_eq "$(removal upgrade)" "no"  "upgrade prints nothing"
assert_eq "$(removal 1)"       "no"  "rpm upgrade prints nothing"

aborts() { is_abort "$1" && echo yes || echo no; }
assert_eq "$(aborts abort-upgrade)" "yes" "abort-upgrade restores stashed data"
assert_eq "$(aborts abort-install)" "yes" "abort-install restores stashed data"
assert_eq "$(aborts remove)"        "no"  "remove is not an abort"

# removal notes must match the package format
assert_eq "$(print_keep_note 0 | grep -c apt)" "0" "rpm note never mentions apt"
assert_eq "$(print_keep_note remove | grep -c 'sudo apt purge lazychad')" "1" "deb note offers apt purge"
assert_eq "$(print_keep_note remove | grep -c 'lazychad-nvim --uninstall')" "0" "note doesn't tell users to run a removed script"
assert_eq "$(print_keep_note 0 | grep -c 'sudo rm -rf /usr/local/bin/nvim')" "1" "note gives a working Neovim removal command"

exit $fail
