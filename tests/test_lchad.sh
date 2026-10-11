#!/usr/bin/env bash
# Tests for bin/lchad with a stub nvim. No network, no sudo; everything lives
# in a temp HOME.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LCHAD="$HERE/../bin/lchad"

fail=0
assert_eq() { if [ "$1" = "$2" ]; then echo "ok   - $3"; else echo "FAIL - $3: got '$1' want '$2'"; fail=1; fi; }

tmp="$(mktemp -d)"
[ -n "$tmp" ] && [ -d "$tmp" ] || { echo "FAIL - mktemp"; exit 1; }
trap 'rm -rf "${tmp:?}"' EXIT

# stub nvim: logs its arguments, prints a version, writes "NVIM-STDOUT" otherwise
mkdir -p "$tmp/bin"
cat > "$tmp/bin/nvim" <<'STUB'
#!/bin/bash
echo "$*" >> "$NVIM_LOG"
if [ "${1:-}" = "--version" ]; then echo "NVIM v0.12.5"; exit 0; fi
echo "NVIM-STDOUT"
STUB
chmod +x "$tmp/bin/nvim"

run_lchad() {
    # $@ = lchad args; isolated HOME/XDG, stub nvim first on PATH
    env -i HOME="${tmp:?}/home" PATH="$tmp/bin:/usr/bin:/bin" NVIM_LOG="$tmp/nvim.log" LAZYCHAD_NVIM="$tmp/bin/nvim" \
        LAZYCHAD_SYSTEM_DIR="$tmp/sys" bash "$LCHAD" "$@"
}

# a packaged config (v2) and a stale user config (v1, no bootstrap.lua)
mkdir -p "$tmp/sys/lua/configs" "$tmp/home/.config/LazyChad/lua/configs"
echo "1.0.10" > "$tmp/sys/.version"
touch "$tmp/sys/init.lua" "$tmp/sys/lua/configs/bootstrap.lua"
echo "1.0.9" > "$tmp/home/.config/LazyChad/.version"
touch "$tmp/home/.config/LazyChad/init.lua"

# --bootstrap with a stale config uses the packaged bootstrap and always quits
: > "$tmp/nvim.log"
run_lchad --bootstrap </dev/null >/dev/null 2>&1
assert_eq "$(grep -c "dofile(\[\[$tmp/sys/lua/configs/bootstrap.lua\]\]).run() +cquit 1" "$tmp/nvim.log")" "1" \
    "stale config: bootstrap falls back to the packaged copy and ends with cquit"
assert_eq "$(grep -c '^--headless +Lazy! restore +Lazy! clean +qa$' "$tmp/nvim.log")" "1" "plugins restored to the pinned versions, then quit"

# with an up-to-date user config, its own bootstrap.lua is used
touch "$tmp/home/.config/LazyChad/lua/configs/bootstrap.lua"
: > "$tmp/nvim.log"
run_lchad --bootstrap </dev/null >/dev/null 2>&1
assert_eq "$(grep -c "home/.config/LazyChad/lua/configs/bootstrap.lua" "$tmp/nvim.log")" "1" "current config uses its own bootstrap"

# --embed: stdout must carry only Neovim's output (msgpack-RPC), even while
# the "system update detected" notice is pending
out="$(run_lchad --embed </dev/null 2>/dev/null)"
assert_eq "$out" "NVIM-STDOUT" "lchad keeps stdout clean for --embed"
assert_eq "$(run_lchad --embed </dev/null 2>&1 >/dev/null | grep -c 'System update detected')" "1" "notices go to stderr"

# an interrupted package upgrade is finished on the next launch
rm -rf "${tmp:?}/home/.local"
mkdir -p "$tmp/home/.local/share/LazyChad.pkg-upgrade/lazy"
run_lchad --version </dev/null >/dev/null 2>&1
assert_eq "$([ -d "$tmp/home/.local/share/LazyChad/lazy" ] && [ ! -e "$tmp/home/.local/share/LazyChad.pkg-upgrade" ] && echo yes)" "yes" \
    "stashed data from an interrupted upgrade is restored"

# version_ok and the user folder (sourced, with a fake config dir)
# shellcheck source=/dev/null
source "$LCHAD"
uf="$(mktemp -d)"
mkdir -p "$uf/sys/templates/user/plugins" "$uf/sys/lua"
echo "1.0.12" > "$uf/sys/.version"; touch "$uf/sys/init.lua"
echo "-- template" > "$uf/sys/templates/user/init.lua"
export LAZYCHAD_DIR="$uf/cfg" SYSTEM_DIR="$uf/sys" HOME="$uf/home"
seed_config 2>/dev/null
assert_eq "$(cat "$uf/cfg/lua/user/init.lua")" "-- template" "first run creates lua/user from the template"
echo "-- mine" > "$uf/cfg/lua/user/init.lua"
echo "1.0.11" > "$uf/cfg/.version"
echo "-- old core edit" > "$uf/cfg/init.lua"
is_tty() { return 0; }
confirm_yes() { return 0; }
REFRESHED=false
seed_config 2>/dev/null
assert_eq "$(cat "$uf/cfg/lua/user/init.lua")" "-- mine" "refresh keeps lua/user"
assert_eq "$(cat "$uf/cfg/.version")" "1.0.12" "refresh installs the new version"
assert_eq "$REFRESHED" "true" "refresh asks for the pinned plugins to be restored"
assert_eq "$(cat "$uf"/cfg_backup_*/init.lua)" "-- old core edit" "other edits go to the backup"
command rm -rf "${uf:?}"

assert_eq "$(version_ok 0.12.5 && echo yes || echo no)" "yes" "version_ok 0.12.5"
assert_eq "$(version_ok 0.13 && echo yes || echo no)"   "yes" "version_ok 0.13"
assert_eq "$(version_ok 1.0.0 && echo yes || echo no)"  "yes" "version_ok 1.0.0"
assert_eq "$(version_ok 0.11.4 && echo yes || echo no)" "no"  "version_ok 0.11.4"
assert_eq "$(version_ok '' && echo yes || echo no)"     "no"  "version_ok empty"

exit $fail
