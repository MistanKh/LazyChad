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

exit $fail
