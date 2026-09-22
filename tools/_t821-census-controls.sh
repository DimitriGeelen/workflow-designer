#!/usr/bin/env bash
# _t821-census-controls.sh — does the swallowed-failure census actually discriminate?
#
# T-821. The census exists because of PL-288: "a chosen-set assertion cannot find what you
# forgot to choose." It is the answer to my own hand-picked list of instrumented sites. But
# a census that only ever reports 0 findings on a tree that already passes is the same
# defect one level up — it would look like coverage and add none.
#
# FOUR BRANCHES, each a different way the thing can go quietly wrong:
#
#   1. a NEW bare catch appears        -> must become a FINDING (the forgot-to-choose case)
#   2. an instrumented site loses its  -> must become a FINDING (a regression that reads as
#      aefRecordFault call                a harmless cleanup in review)
#   3. an excused pattern gains a copy -> must trip the COUNT (an excuse is a claim about
#                                         the sites that existed when it was written; without
#                                         the count it becomes a licence)
#   4. a catch inside a COMMENT        -> must NOT be counted. The census's first run
#                                         reported one of its own doc lines as a finding.
#                                         Prose is not product.
#
# A clean baseline runs first, or every red below proves nothing.
#
# Exit: 0 all branches hold | 1 a branch failed | 3 setup

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CENSUS="$REPO/tools/_t821-swallowed-failure-census.py"
SRC_REL="src/aef-workflow-designer.html"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$CENSUS" ] || cannot "census not found: $CENSUS"
[ -f "$REPO/$SRC_REL" ] || cannot "source not found: $SRC_REL"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

build() {
    rm -rf "$WORK/repo"
    mkdir -p "$WORK/repo/tools" "$WORK/repo/src"
    cp "$CENSUS" "$WORK/repo/tools/"
    cp "$REPO/$SRC_REL" "$WORK/repo/src/"
}
run() { python3 "$WORK/repo/tools/$(basename "$CENSUS")" > "$WORK/out" 2>&1; }
findings() { sed -n 's/^  FINDINGS *\([0-9]*\).*/\1/p' "$WORK/out" | head -1; }

# inject <text-to-append-into-a-function-body>
inject() {
    python3 - "$WORK/repo/src/$(basename "$SRC_REL")" "$1" <<'PY' || cannot "injection failed — the anchor moved"
import io, sys
p, payload = sys.argv[1], sys.argv[2]
s = io.open(p, encoding='utf-8').read()
anchor = "function aefFaults() { return _faults.slice(); }"
if s.count(anchor) != 1:
    sys.stderr.write("anchor count %d\n" % s.count(anchor)); sys.exit(1)
io.open(p, 'w', encoding='utf-8').write(s.replace(anchor, anchor + "\n" + payload))
PY
}

echo "=== T-821 census controls ==="

build
if run; then
    BASE_F="$(findings)"
    ok "baseline: unmutated src -> census PASSES (findings=$BASE_F)"
else
    bad "baseline should pass" "the census is red on clean source; every branch below would be meaningless. $(tail -4 "$WORK/out")"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# 1. a new bare catch nobody decided about
build
inject 'function _t821ControlNewSwallow(){ try { JSON.parse("{"); } catch (_) {} }'
if run; then
    bad "new bare catch not caught" "the census PASSED with a brand-new swallowed failure in the tree — it is measuring my list, not the product, which is the exact PL-288 hole it exists to close"
else
    if [ "$(findings)" = "1" ]; then
        ok "new bare catch -> FINDINGS 0 to 1"
    else
        bad "new bare catch: wrong count" "expected FINDINGS=1, got $(findings) — it went red for some other reason"
    fi
fi

# 2. an instrumented site silently loses its recorder call
build
python3 - "$WORK/repo/src/$(basename "$SRC_REL")" <<'PY' || cannot "de-instrument mutation did not apply — src moved"
import io, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8').read()
# TWO sites, not one: the XML panel's Copy button and the fault panel's own Copy
# button. This control was written expecting one and refused rather than guessing —
# which is the behaviour it is here to enforce, met on its first run.
old = "catch (e) { aefRecordFault('clipboard-write', e); }"
if s.count(old) != 2:
    sys.stderr.write("expected 2, found %d\n" % s.count(old)); sys.exit(1)
io.open(p, 'w', encoding='utf-8').write(s.replace(old, "catch (_) {}"))
PY
if run; then
    bad "de-instrumented site not caught" "a site that HAD a recorder call lost it and the census stayed green — the regression that reads as a harmless cleanup"
else
    ok "instrumented site de-instrumented -> FINDINGS $(findings)"
fi

# 3. an excused pattern gains another copy
build
# On its OWN LINE, deliberately. Excuse signatures are the catch's source line, so the same
# code inlined into a wrapper is a DIFFERENT signature and lands as a finding instead — which
# is what the first version of this control did, and it tested the wrong mechanism while
# looking green-adjacent. The census errs toward false FINDINGS on reformatting, never toward
# false silence, so that asymmetry is safe; it still has to be driven deliberately.
inject 'function _t821ControlExtraExcused(){
  try { renderFaultIndicator(); } catch (_) {}
}'
if run; then
    bad "excuse count not enforced" "a second copy of an excused one-liner appeared and the census stayed green — the excuse has become a licence rather than a claim about specific sites"
else
    if grep -q 'EXCUSE COUNT MOVED' "$WORK/out"; then
        ok "extra copy of an excused pattern -> EXCUSE COUNT MOVED"
    else
        bad "excuse count: wrong signal" "census went red but did not report a moved count — it caught this as something else"
    fi
fi

# 4. prose is not product
build
inject '// _t821 control: this comment mentions catch (_) {} and must not be counted'
if run; then
    ok "catch inside a comment -> still passes (prose is not product)"
else
    bad "comment counted as a site" "a commented-out catch was scored as a finding — the census's own first run made this mistake and this branch is why it cannot come back. $(tail -4 "$WORK/out")"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
