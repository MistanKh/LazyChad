#!/usr/bin/env bash
# Unit tests for scripts/linux-postremove.sh. No deletion: only checks which
# package-manager actions trigger user-dir cleanup.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
export LAZYCHAD_POSTREMOVE_SOURCED=1
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

exit $fail
