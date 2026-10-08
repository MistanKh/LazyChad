#!/bin/bash
# Verify every file that carries the release version agrees with .version.
#
# Usage: scripts/check-version.sh [tag]   e.g. scripts/check-version.sh v1.2.3
# Run by CI on every push and before publishing a release.
set -u
cd "$(dirname "$0")/.." || exit 1

ver="$(tr -d '[:space:]' < .version)"
fail=0

check() {
    # $1=label $2=value found
    if [ "$2" = "$ver" ]; then
        echo "ok   - $1 ($2)"
    else
        echo "FAIL - $1 is '$2', but .version is '$ver'"
        fail=1
    fi
}

check "PKGBUILD pkgver" "$(sed -n 's/^pkgver=//p' PKGBUILD)"
check "nfpm.yaml version" "$(sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' nfpm.yaml)"

while read -r v; do
    check "README .deb example" "$v"
done < <(grep -oP 'lazychad_\K[0-9]+\.[0-9]+\.[0-9]+(?=-1_all\.deb)' README.md)

while read -r v; do
    check "README .rpm example" "$v"
done < <(grep -oP 'lazychad-\K[0-9]+\.[0-9]+\.[0-9]+(?=-1\.noarch\.rpm)' README.md)

if [ -n "${1:-}" ]; then
    check "release tag $1" "${1#v}"
fi

exit $fail
