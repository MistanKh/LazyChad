#!/usr/bin/env bash
# Replays the dpkg and RPM upgrade order from LazyChad <= 1.0.9 (whose
# postrm/%postun wiped every user's data) against temporary home dirs, and
# checks the new hooks keep the data. Hooks run under dash when available,
# like an RPM /bin/sh scriptlet. No root needed; nothing outside $tmp is touched.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
S="$HERE/../scripts"
SH_BIN="$(command -v dash || command -v sh)"

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

tmp="$(mktemp -d)"
[ -n "$tmp" ] && [ -d "$tmp" ] || { echo "FAIL - mktemp"; exit 1; }
trap 'rm -rf "${tmp:?}"' EXIT
export LAZYCHAD_HOMES="${tmp:?}/h/alice ${tmp:?}/h/bob ${tmp:?}/h/root"

seed() {
    rm -rf "${tmp:?}/h"
    local h
    for h in $LAZYCHAD_HOMES; do
        mkdir -p "$h/.config/LazyChad" "$h/.local/share/LazyChad/lazy" "$h/.cache/LazyChad"
        echo mine > "$h/.config/LazyChad/mine.lua"
    done
}

old_wiping_postrm() {
    # What LazyChad <= 1.0.9's postremove did, whatever its arguments.
    local h
    for h in $LAZYCHAD_HOMES; do
        rm -rf "${h:?}/.config/LazyChad" "${h:?}/.local/share/LazyChad" \
            "${h:?}/.local/state/LazyChad" "${h:?}/.cache/LazyChad"
    done
}

kept() {
    local n=0 h
    for h in $LAZYCHAD_HOMES; do
        [ -f "$h/.config/LazyChad/mine.lua" ] && [ -d "$h/.local/share/LazyChad/lazy" ] && n=$((n + 1))
    done
    echo "$n"
}

stashes() { find "${tmp:?}/h" -name '*.pkg-upgrade' | wc -l | tr -d ' '; }

# dpkg: new preinst upgrade -> old postrm upgrade -> new postinst configure
seed
"$SH_BIN" "$S/linux-preinstall.sh" upgrade 1.0.9-1
old_wiping_postrm
"$SH_BIN" "$S/linux-postinstall.sh" configure 1.0.9-1 >/dev/null
assert_eq "$(kept)" "3" "deb upgrade from 1.0.9 keeps every user's data"
assert_eq "$(stashes)" "0" "deb upgrade leaves no stash behind"

# rpm: new %pre 2 -> new %post 2 -> old %postun 1 -> new %posttrans
seed
"$SH_BIN" "$S/linux-preinstall.sh" 2
"$SH_BIN" "$S/linux-postinstall.sh" 2 >/dev/null
assert_eq "$(stashes)" "9" "rpm %post must not restore before the old %postun (3 homes x 3 dirs)"
old_wiping_postrm
"$SH_BIN" "$S/linux-posttrans.sh"
assert_eq "$(kept)" "3" "rpm upgrade from 1.0.9 keeps every user's data"
assert_eq "$(stashes)" "0" "rpm upgrade leaves no stash behind"

# dpkg aborts the upgrade after preinst: the new postrm restores
seed
"$SH_BIN" "$S/linux-preinstall.sh" upgrade 1.0.9-1
"$SH_BIN" "$S/linux-postremove.sh" abort-upgrade 1.0.9-1
assert_eq "$(kept)" "3" "aborted deb upgrade restores data"

# fresh installs never move anything
seed
"$SH_BIN" "$S/linux-preinstall.sh" install
"$SH_BIN" "$S/linux-preinstall.sh" 1
assert_eq "$(stashes)" "0" "fresh install stashes nothing"
assert_eq "$(kept)" "3" "fresh install leaves data in place"

# a dir recreated meanwhile is never overwritten; the stash is kept
seed
"$SH_BIN" "$S/linux-preinstall.sh" upgrade 1.0.9-1
mkdir -p "${tmp:?}/h/alice/.config/LazyChad"
"$SH_BIN" "$S/linux-postinstall.sh" configure 1.0.9-1 >/dev/null
assert_eq "$([ -f "${tmp:?}/h/alice/.config/LazyChad.pkg-upgrade/mine.lua" ] && echo yes)" "yes" \
    "existing dir wins; old data stays in the stash"

# purge also removes a leftover stash, so a later reinstall can't restore it
seed
mkdir -p "${tmp:?}/h/bob/.cache/LazyChad.pkg-upgrade"
"$SH_BIN" "$S/linux-postremove.sh" purge >/dev/null
assert_eq "$(stashes)" "0" "purge removes leftover upgrade stashes"
assert_eq "$(kept)" "0" "purge removes user data"

# the three copies of the restore function must stay identical
fn() { bash -c "export LAZYCHAD_HOOK_SOURCED=1; source '$1'; declare -f lazychad_restore_user_data"; }
assert_eq "$(fn "$S/linux-postinstall.sh")" "$(fn "$S/linux-posttrans.sh")" "restore identical in postinstall and posttrans"
assert_eq "$(fn "$S/linux-postremove.sh")" "$(fn "$S/linux-posttrans.sh")" "restore identical in postremove and posttrans"

exit $fail
