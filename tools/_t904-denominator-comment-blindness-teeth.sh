#!/usr/bin/env bash
# _t904-denominator-comment-blindness-teeth.sh — prove the comment-stripping fix is load-bearing.
#
# WHY THIS EXISTS. T-886 made the round-trip guard derive its projected-key denominator FROM the
# emitter, so the coverage list could not drift from the code. T-889 then measured that the
# derivation regexed the emitter's RAW TEXT — comments included — so the derivation was movable by
# text the engine never runs. T-904 strips comments before matching.
#
# A fix like this is only demonstrated by a DIFFERENTIAL. "The guard is green now" proves nothing:
# it was green before too. Every leg below therefore runs the SAME mutant tree twice — once with
# the shipped (stripping) guard, once with the guard's strip mechanically reverted to the raw form
# — and REQUIRES THE TWO TO DISAGREE. If the raw variant behaves like the stripped one, the leg
# FAILS as a vacuous differential rather than passing as a kill. That is the C4 lesson from
# T-889: a control that cannot distinguish the two worlds is not a control.
#
# Mutants operate on COPIES in a temp tree. No tracked file is ever written.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTML="$REPO/src/aef-workflow-designer.html"
HARNESS="$REPO/tools/_roundtrip-serialization-cdp.mjs"
FIXTURES="$REPO/tests/fixtures/aef-bpmn"
fail=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

for f in "$HTML" "$HARNESS"; do
  [ -e "$f" ] || { echo "FAIL  missing input: $f"; exit 1; }
done
[ -d "$FIXTURES" ] || { echo "FAIL  missing fixtures dir: $FIXTURES"; exit 1; }

# ---------------------------------------------------------------------------------------------
# tree <name> — a working copy of the tools + src the harness needs.
# ---------------------------------------------------------------------------------------------
tree() {
  mkdir -p "$TMP/$1/tools" "$TMP/$1/src"
  cp "$REPO"/tools/*.mjs "$REPO"/tools/*.py "$TMP/$1/tools/"
  cp "$HTML" "$TMP/$1/src/"
}

# run <name> — run the harness in a tree; echo its exit code; output lands in $TMP/<name>.out
run() {
  local rc=0
  ( cd "$TMP/$1" && ROUNDTRIP_FIXTURES_DIR="$FIXTURES" \
      timeout 300 node tools/_roundtrip-serialization-cdp.mjs ) > "$TMP/$1.out" 2>&1 || rc=$?
  echo "$rc"
}

# unstrip <tree> — mechanically revert the T-904 fix in a tree's guard copy, reproducing the
# pre-fix raw-text derivation. Anchored on exact strings and asserted by count, so a moved anchor
# prints MUTATION SETUP BROKEN instead of silently producing a tree that was never reverted (a
# non-reverted tree would behave identically to the shipped one and read as a vacuous differential
# — which this script would then report as a FAIL, but for the wrong reason).
unstrip() {
  python3 - "$TMP/$1/tools/_roundtrip-serialization-cdp.mjs" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
a = "const body = stripJsComments(html.slice(start, end + 1).join('\\n'));"
b = ".map(l => stripJsComments(l))"
if s.count(a) != 1 or s.count(b) != 1:
    sys.exit(1)
s = s.replace(a, "const body = html.slice(start, end + 1).join('\\n');")
s = s.replace(b, ".map(l => l)")
open(p, 'w', encoding='utf-8').write(s)
PY
}

# drop_authority <tree> — delete `authority` from the emitter's metaKeys, leaving every COMMENT
# in place. This is T-889's M1 mutant. The comment immediately BELOW the literal spells
# node.aef.authority deliberately (T-904 AC5) — below rather than inside, because prose inside the
# array trips the parity checker's own comment blindness (T-907). Under the raw derivation that
# prose alone keeps the key "covered", which is the false green D1 exists to catch.
drop_authority() {
  python3 - "$TMP/$1/src/aef-workflow-designer.html" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
if s.count("    'authority'];") != 1:
    sys.exit(1)
open(p, 'w', encoding='utf-8').write(s.replace("    'authority'];", "    ];"))
PY
}

# mention_phantom <tree> — add a COMMENT ONLY, naming a key nothing projects. Nothing executable
# changes. Injected immediately above the metaKeys literal so it lands inside the function body
# the denominator slices.
mention_phantom() {
  python3 - "$TMP/$1/src/aef-workflow-designer.html" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
anchor = "  const metaKeys = ["
if s.count(anchor) != 1:
    sys.exit(1)
s = s.replace(anchor, "  // phantom: aef.zzzNeverProjected is named here and emitted nowhere\n" + anchor)
open(p, 'w', encoding='utf-8').write(s)
PY
}

echo "== CONTROL SET =="

# C1 — SETUP CONTROL. The unmutated copy must reach a clean exit in this temp tree. Without it,
# any breakage in the copy (missing import, missing fixtures) exits non-zero and would read as a
# kill on every leg below. Requires a clean EXIT, not merely the absence of one error string.
tree c1
c1rc="$(run c1)"
if [ "$c1rc" -eq 0 ]; then
  echo "PASS  C1 unmutated-copy-clean         (temp tree is a working copy, rc=0)"
else
  echo "FAIL  C1 MUTATION SETUP BROKEN        (unmutated copy does not pass: rc=$c1rc)"
  head -c 400 "$TMP/c1.out"; echo; exit 1
fi

# C2 — the stripper itself, exercised against the cases a naive /\/\/.*$/ would get wrong. The
# function is lifted OUT OF THE SHIPPED GUARD rather than retyped here, so this control cannot
# pass against a copy that has drifted from what runs.
node - "$HARNESS" <<'JS' > "$TMP/c2.out" 2>&1
import { readFileSync } from 'fs';
const src = readFileSync(process.argv[2], 'utf8');
const i = src.indexOf('function stripJsComments'), j = src.indexOf('function deriveProjectedKeys');
if (i < 0 || j < 0 || j < i) { console.log('ANCHOR-BROKEN'); process.exit(1); }
const strip = new Function(src.slice(i, j) + '; return stripJsComments;')();
const checks = [
  ['line-comment-removed',   strip('const a = aef.keep; // aef.drop'),        s => /aef\.keep/.test(s) && !/aef\.drop/.test(s)],
  ['block-comment-removed',  strip('const a = aef.keep; /* aef.drop */ b;'),  s => /aef\.keep/.test(s) && !/aef\.drop/.test(s)],
  ['slash-in-string-kept',   strip("const u = 'https://x//y'; const a = aef.keep; // aef.drop"),
                                                                              s => s.includes('https://x//y') && /aef\.keep/.test(s) && !/aef\.drop/.test(s)],
  ['escaped-quote-survived', strip("const s = 'it\\'s // not a comment'; const a = aef.keep;"),
                                                                              s => s.includes('not a comment') && /aef\.keep/.test(s)],
  ['template-literal-kept',  strip('const t = `a // b`; const a = aef.keep;'), s => s.includes('a // b') && /aef\.keep/.test(s)],
  ['newlines-preserved',     strip('a;\n// c\nb;'),                            s => s.split('\n').length === 3],
];
let bad = 0;
for (const [name, out, ok] of checks) { if (!ok(out)) { console.log('SUBFAIL ' + name + ' => ' + JSON.stringify(out)); bad++; } }
console.log(bad ? 'C2-FAIL' : 'C2-OK');
process.exit(bad ? 1 : 0);
JS
if grep -q 'C2-OK' "$TMP/c2.out"; then
  echo "PASS  C2 stripper-handles-literals    (6/6: strings, escapes, templates, blocks, newlines)"
else
  echo "FAIL  C2 stripper-handles-literals"; sed 's/^/        /' "$TMP/c2.out"; fail=1
fi

# C3 — the stripper is a JS stripper and SRC_HTML is an HTML document. An earlier cut of the
# T-904 fix ran it over the WHOLE file to find EVENT_BINDING_FIELD and silently ate 61% of the
# bytes (1,013,174 -> 393,293): CSS /* */ blocks and apostrophes in prose desync a JS quote
# scanner. The bindFields survived that by luck. This control pins the two properties that make
# the narrow per-line read correct — the derived values are exactly the live ones, and the
# whole-file strip (the wrong approach) is measurably destructive, so nobody reintroduces it
# believing it harmless.
node - "$HARNESS" "$HTML" <<'JS' > "$TMP/c3.out" 2>&1
import { readFileSync } from 'fs';
const src = readFileSync(process.argv[2], 'utf8');
const i = src.indexOf('function stripJsComments'), j = src.indexOf('function deriveProjectedKeys');
const strip = new Function(src.slice(i, j) + '; return stripJsComments;')();
const all = readFileSync(process.argv[3], 'utf8');
const rx = /const EVENT_BINDING_FIELD\s*=\s*\{([^}]*)\}/;
const vals = s => { const m = rx.exec(s); return m ? [...m[1].matchAll(/:\s*'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(x => x[1]) : null; };
// the shipped narrow read: strip candidate LINES, require exactly one survivor
const lines = all.split('\n').map(l => strip(l)).filter(l => /const EVENT_BINDING_FIELD\s*=/.test(l));
const narrow = lines.length === 1 ? vals(lines[0]) : null;
const live = vals(all);
const wholeFileBytes = strip(all).length;
const ok = narrow && live && JSON.stringify(narrow) === JSON.stringify(live) && narrow.length === 3;
console.log('narrow=' + JSON.stringify(narrow) + ' live=' + JSON.stringify(live) + ' survivors=' + lines.length);
console.log('whole-file strip would drop ' + (all.length - wholeFileBytes) + ' of ' + all.length + ' bytes');
// the destructive-approach assertion: if a whole-file strip ever became non-destructive this
// control's rationale would be stale, so say so rather than passing quietly.
if (wholeFileBytes > all.length * 0.9) console.log('NOTE whole-file strip is no longer destructive — revisit this control');
console.log(ok ? 'C3-OK' : 'C3-FAIL');
process.exit(ok ? 0 : 1);
JS
if grep -q 'C3-OK' "$TMP/c3.out"; then
  echo "PASS  C3 bindfields-read-is-narrow    ($(grep -o 'survivors=[0-9]*' "$TMP/c3.out"), values match the live literal)"
  grep -q 'NOTE' "$TMP/c3.out" && sed -n '/NOTE/s/^/      /p' "$TMP/c3.out"
else
  echo "FAIL  C3 bindfields-read-is-narrow"; sed 's/^/        /' "$TMP/c3.out"; fail=1
fi

echo
echo "== DIFFERENTIAL SET =="

# D1 — FALSE GREEN. The T-889 M1 mutant (authority dropped from metaKeys) with the comment that
# spells the accessor left in place. Shipped guard must go RED naming the key; raw guard must go
# GREEN. The green half is the defect T-904 fixes; without it this leg proves nothing.
tree d1s; drop_authority d1s || { echo "FAIL  D1 MUTATION SETUP BROKEN (metaKeys anchor moved)"; exit 1; }
tree d1r; drop_authority d1r || { echo "FAIL  D1 MUTATION SETUP BROKEN (metaKeys anchor moved)"; exit 1; }
unstrip d1r               || { echo "FAIL  D1 MUTATION SETUP BROKEN (strip call sites moved — cannot build the raw variant)"; exit 1; }
d1src="$(run d1s)"; d1rrc="$(run d1r)"
d1s_red=0; { [ "$d1src" -ne 0 ] && grep -q "does not project" "$TMP/d1s.out"; } && d1s_red=1
d1r_green=0; [ "$d1rrc" -eq 0 ] && d1r_green=1
if [ "$d1s_red" -eq 1 ] && [ "$d1r_green" -eq 1 ]; then
  echo "PASS  D1 false-green-killed           (stripped: RED on the dropped key | raw: GREEN — the defect, reproduced)"
else
  echo "FAIL  D1 false-green-killed           (stripped rc=$d1src red=$d1s_red | raw rc=$d1rrc green=$d1r_green)"
  [ "$d1r_green" -eq 0 ] && echo "        raw variant did NOT go green: the differential is vacuous, not a kill"
  fail=1
fi

# D2 — FALSE RED. A comment naming a key nothing projects. Nothing executable changes, so the
# shipped guard must stay GREEN; the raw guard must go RED demanding classification for a key the
# emitter never writes.
tree d2s; mention_phantom d2s || { echo "FAIL  D2 MUTATION SETUP BROKEN (metaKeys anchor moved)"; exit 1; }
tree d2r; mention_phantom d2r || { echo "FAIL  D2 MUTATION SETUP BROKEN (metaKeys anchor moved)"; exit 1; }
unstrip d2r                   || { echo "FAIL  D2 MUTATION SETUP BROKEN (strip call sites moved)"; exit 1; }
d2src="$(run d2s)"; d2rrc="$(run d2r)"
d2s_green=0; [ "$d2src" -eq 0 ] && d2s_green=1
d2r_red=0; { [ "$d2rrc" -ne 0 ] && grep -q "zzzNeverProjected" "$TMP/d2r.out"; } && d2r_red=1
if [ "$d2s_green" -eq 1 ] && [ "$d2r_red" -eq 1 ]; then
  echo "PASS  D2 false-red-killed             (stripped: GREEN | raw: RED on a key named only in prose)"
else
  echo "FAIL  D2 false-red-killed             (stripped rc=$d2src green=$d2s_green | raw rc=$d2rrc red=$d2r_red)"
  [ "$d2r_red" -eq 0 ] && echo "        raw variant did NOT go red: the differential is vacuous, not a kill"
  [ "$d2s_green" -eq 0 ] && { echo "        stripped variant went red — the fix does not hold:"; grep -m3 "zzz\|orphan\|does not project" "$TMP/d2s.out" | sed 's/^/          /'; }
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then echo "T-904 teeth: all legs passed"; else echo "T-904 teeth: FAILURES above"; fi
exit "$fail"
