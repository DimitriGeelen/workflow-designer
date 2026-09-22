#!/usr/bin/env bash
# _t830-correlation-gate-controls.sh — does the correlation gate actually discriminate?
#
# T-830. The rule this gate replaces was TRUE, WRITTEN DOWN, AND INERT: the manifest has
# forbidden opening a peer handoff against an unassigned correlation since 2026-08-26, and a
# handoff opened anyway on 2026-08-27 and stayed open two months. Nothing evaluated it.
#
# So a gate that only ever reports green on a tree that already passes would be the same
# defect wearing a different costume. Each branch below is a DIFFERENT way the ruling rots:
#
#   UNASSIGNED       the slot goes back to where H3 found it.
#   MINTED           someone writes a free string instead of a derived one — the exact act
#                    that produced three correlations and H3 itself.
#   DANGLING         the value is derived but the arc it derives from is gone. This is the
#                    self-invalidating property under test: a derived reference must STOP
#                    WORKING rather than quietly name nothing.
#   PROVISIONAL      assigned_by is an agent. Must exit 2, not 1 and not 0 — transport is
#                    fine, completion is not. An agent-assigned value that could close a
#                    completion gate would let the agent ratify its own correlation, which
#                    is the whole thing H3 was opened about.
#   HANDOFF-OPEN     a handoff exists while a slot is unusable. The rule that was prose.
#
# A clean baseline runs first, or every red below proves nothing.
#
# Exit: 0 every branch behaves | 1 a branch failed | 3 setup

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO/tools/_t830-correlation-gate.py"
MAN_REL="docs/research/executable-workflow/source-manifest.yaml"
ENV_REL="docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml"
ARC_REL=".context/arcs/ewcr-governed-delivery.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$GATE" ] || cannot "gate not found: $GATE"
for f in "$MAN_REL" "$ENV_REL" "$ARC_REL"; do
    [ -f "$REPO/$f" ] || cannot "missing: $f"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Copies, not symlinks: the gate resolves ROOT from its own location, and a symlinked tool
# would resolve back to the real tree and make every mutation below a silent no-op.
build() {
    rm -rf "$WORK/repo"
    mkdir -p "$WORK/repo/tools" \
             "$WORK/repo/docs/research/executable-workflow" \
             "$WORK/repo/.context/arcs"
    cp "$GATE" "$WORK/repo/tools/"
    cp "$REPO/$MAN_REL" "$WORK/repo/$MAN_REL"
    cp "$REPO/$ENV_REL" "$WORK/repo/$ENV_REL"
    cp "$REPO/$ARC_REL" "$WORK/repo/$ARC_REL"
}
run() { python3 "$WORK/repo/tools/$(basename "$GATE")" > "$WORK/out" 2>&1; }

# set_slot <key> <value>  — rewrite one correlation value, asserting it matched once.
set_slot() {
    python3 - "$WORK/repo/$MAN_REL" "$1" "$2" <<'PY' || cannot "mutation did not apply — the manifest moved and this control is measuring nothing"
import io, re, sys
p, key, val = sys.argv[1], sys.argv[2], sys.argv[3]
s = io.open(p, encoding='utf-8').read()
pat = re.compile(r'^(  %s: ).*$' % re.escape(key), re.M)
if len(pat.findall(s)) != 1:
    sys.stderr.write("expected 1 %s line, found %d\n" % (key, len(pat.findall(s)))); sys.exit(1)
io.open(p, 'w', encoding='utf-8').write(pat.sub(r'\g<1>%s' % val, s))
PY
}
set_prov() {
    python3 - "$WORK/repo/$MAN_REL" "$1" <<'PY' || cannot "provenance mutation did not apply"
import io, re, sys
p, who = sys.argv[1], sys.argv[2]
s = io.open(p, encoding='utf-8').read()
pat = re.compile(r'^(    assigned_by: ).*$', re.M)
if len(pat.findall(s)) != 1:
    sys.stderr.write("expected 1 assigned_by line, found %d\n" % len(pat.findall(s))); sys.exit(1)
io.open(p, 'w', encoding='utf-8').write(pat.sub(r'\g<1>%s' % who, s))
PY
}

echo "=== T-830 correlation gate controls ==="

build
if run; then
    ok "baseline: real manifest -> gate PASSES (exit 0)"
else
    bad "baseline should pass" "gate is red on the real tree; every branch below would be meaningless. $(tail -5 "$WORK/out")"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# --- UNASSIGNED: back to where H3 found it.
build; set_slot shared_initiative_correlation "UNASSIGNED"
run; rc=$?
if [ "$rc" -eq 1 ] && grep -q "RULE: assigned" "$WORK/out"; then
    ok "UNASSIGNED slot -> exit 1, RULE: assigned"
else
    bad "UNASSIGNED not caught" "exit $rc; the state H3 was opened over would pass unnoticed"
fi

# --- MINTED: a free string, which is the act that produced three correlations.
build; set_slot shared_initiative_correlation '"EWCR-ARC0-ATTEST-832"'
run; rc=$?
if [ "$rc" -eq 1 ] && grep -q "RULE: derived" "$WORK/out"; then
    ok "minted free string -> exit 1, RULE: derived"
else
    bad "minted string not caught" "exit $rc; the gate would accept the fourth minted value"
fi

# --- DANGLING: derived, but the arc is gone. The self-invalidating property.
build; rm -f "$WORK/repo/$ARC_REL"
run; rc=$?
if [ "$rc" -eq 1 ] && grep -q "RULE: resolves" "$WORK/out"; then
    ok "arc deleted -> exit 1, RULE: resolves (derivation is checked, not decorative)"
else
    bad "dangling derivation not caught" "exit $rc; a derived value that names nothing is a minted string with extra steps"
fi

# --- PROVISIONAL: exit 2 specifically. Not 0 and not 1.
build; set_prov "agent"
run; rc=$?
if [ "$rc" -eq 2 ]; then
    ok "agent-assigned -> exit 2 PROVISIONAL (transport fine, completion refused)"
elif [ "$rc" -eq 0 ]; then
    bad "provisional treated as ratified" "exit 0 — an agent could ratify its own correlation, which is the entire subject of H3"
else
    bad "provisional mis-reported" "exit $rc, expected 2 — transport must stay usable; only the completion claim fails"
fi

# --- HANDOFF-OPEN: the rule that was prose for two months.
build; set_slot designer_agent_correlation "UNASSIGNED"
run; rc=$?
if [ "$rc" -eq 1 ] && grep -q "RULE: no-handoff-without-correlation" "$WORK/out"; then
    ok "handoff open + unusable slot -> exit 1, RULE: no-handoff-without-correlation"
else
    bad "inert rule still inert" "exit $rc; the sentence that failed to stop a real handoff on 2026-08-27 is still not a check"
fi

# --- and the negative control for that one: no handoff, same bad slot -> must NOT cite it.
build; set_slot designer_agent_correlation "UNASSIGNED"; rm -f "$WORK/repo/$ENV_REL"
run; rc=$?
if [ "$rc" -eq 1 ] && ! grep -q "RULE: no-handoff-without-correlation" "$WORK/out"; then
    ok "no handoff open -> slot still red, but the handoff rule is NOT falsely cited"
else
    bad "handoff rule fires without a handoff" "it would report a violation that is not occurring, and a rule that cries wolf is one readers learn to skip"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
