#!/bin/sh
# by thinkcy with ChatGPT 20261124
# Patch LuCI DHCP status view: accept string or array host.duid.
# Usage: ./patch-luci-duid.sh [LUCI_SOURCE_DIR]
# Example: ./patch-luci-duid.sh feeds/luci

set -eu
LUCI_DIR="${1:-feeds/luci}"
TARGET="$LUCI_DIR/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/40_dhcp.js"

if [ ! -f "$TARGET" ]; then
    echo "ERROR: Cannot find:"
    echo "  $TARGET"
    echo "Pass the actual LuCI source directory as the first argument."
    exit 1
fi

python3 - "$TARGET" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text(encoding="utf-8")

patched = re.compile(
    r"if\s*\(\s*host\.duid\s*\)\s*\{\s*"
    r"var\s+duids\s*=\s*L\.toArray\s*\(\s*host\.duid\s*\)\s*;\s*"
    r"for\s*\(\s*var\s+j\s*=\s*0\s*;\s*j\s*<\s*duids\.length\s*;\s*j\+\+\s*\)\s*\{\s*"
    r"if\s*\(\s*typeof\s+duids\[j\]\s*===\s*['\"]string['\"]\s*&&\s*duids\[j\]\.length\s*\)\s*\{\s*"
    r"var\s+duid\s*=\s*duids\[j\]\.toUpperCase\s*\(\s*\)\s*;\s*"
    r"this\.isDUIDStatic\[duid\]\s*=\s*true\s*;\s*\}\s*\}\s*\}"
)

if patched.search(source):
    print("Already patched; no changes made.")
    sys.exit(0)

original = re.compile(
    r"if\s*\(\s*host\.duid\s*\)\s*\{\s*"
    r"var\s+duid\s*=\s*host\.duid\.toUpperCase\s*\(\s*\)\s*;\s*"
    r"this\.isDUIDStatic\[duid\]\s*=\s*true\s*;\s*\}"
)

matches = list(original.finditer(source))
if len(matches) != 1:
    print("ERROR: Expected exactly one original host.duid block; found %d." % len(matches))
    print("No changes made. Inspect the source before patching.")
    sys.exit(2)

replacement = (
    "if(host.duid){"
    "var duids=L.toArray(host.duid);"
    "for(var j=0;j<duids.length;j++){"
    "if(typeof duids[j]==='string'&&duids[j].length){"
    "var duid=duids[j].toUpperCase();"
    "this.isDUIDStatic[duid]=true;"
    "}}}"
)

updated = original.sub(lambda _m: replacement, source, count=1)
if not patched.search(updated):
    print("ERROR: Verification failed; file not written.")
    sys.exit(3)

path.write_text(updated, encoding="utf-8")
print("PATCH APPLIED: %s" % path)
print("host.duid now accepts a string or an array; non-string entries are skipped.")
PY

