#!/usr/bin/env bash
# T-1489: shard coverage reads the expected legs from the COMMIT the shards tested, not from the working tree. On
# 2026-11-23 an uncommitted new browser leg made a green split read "159 of 161 ran; missing 2" and refused the round.
#   C1 a clone of HEAD whose working tree declares one more browser leg (uncommitted): legs that cover HEAD's list are
#      "ok" with T1480_REF=HEAD
#   C2 the same legs minus one HEAD leg: RED, naming it (the check still bites)
# Control: T1489_COVERAGE=<shard-coverage.py before T-1489> fails C1 (it reads the working tree: "missing 1").
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT=${T1489_COVERAGE:-$ROOT/tools/pool/shard-coverage.py}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
git clone -q --shared "$ROOT" "$W/r" && git -C "$W/r" checkout -q "$(git -C "$ROOT" rev-parse HEAD)" || { echo "SETUP BROKEN: clone"; exit 2; }
cp "$SCRIPT" "$W/r/tools/pool/shard-coverage.py"
(cd "$W/r" && bash tests/run-bridge-tests.sh --list-legs 2>/dev/null) | awk '$1 == "browser" {printf "browser\t%s\tfirst\t1\t0\t1\n", $2}' > "$W/legs.tsv"
n=$(wc -l < "$W/legs.tsv"); [ "$n" -gt 10 ] || { echo "SETUP BROKEN: $n browser legs listed"; exit 2; }
python3 - "$W/r/tests/run-bridge-tests.sh" <<'PY'   # the uncommitted edit: one more browser leg, beside the first one
import re, sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
m = re.search(r'^leg browser .*$', s, re.M)
open(p, 'w', encoding='utf-8').write(s[:m.end()] + '\nleg browser "t1489_uncommitted_probe" true' + s[m.end():])
PY
(cd "$W/r" && bash tests/run-bridge-tests.sh --list-legs 2>/dev/null) | grep -qx 'browser t1489_uncommitted_probe' || { echo "SETUP BROKEN: the probe leg is not listed"; exit 2; }
fails=0
out=$(cd "$W/r" && T1480_REF=HEAD python3 tools/pool/shard-coverage.py browser "$W/legs.tsv" 2>&1); rc=$?
[ "$rc" = 0 ] && grep -q '^shard-coverage: ok' <<<"$out" && echo "PASS  C1 an uncommitted extra leg does not count: $out" || { echo "FAIL  C1 rc=$rc: $out"; fails=1; }
first=$(head -1 "$W/legs.tsv" | cut -f2); tail -n +2 "$W/legs.tsv" > "$W/short.tsv"
out=$(cd "$W/r" && T1480_REF=HEAD python3 tools/pool/shard-coverage.py browser "$W/short.tsv" 2>&1); rc=$?
[ "$rc" = 1 ] && grep -q "$first" <<<"$out" && echo "PASS  C2 a HEAD leg that did not run is still RED and named ($first)" || { echo "FAIL  C2 rc=$rc: $out"; fails=1; }
[ "$fails" = 0 ] && echo "T-1489 coverage ref: GREEN" || echo "T-1489 coverage ref: RED"
exit "$fails"
