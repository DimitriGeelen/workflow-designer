#!/usr/bin/env bash
# _t818-probe-controls.sh — do the two newly-wired probes actually fail when their subject
# breaks, and do they say COULD-NOT-MEASURE when their STIMULUS breaks?
#
# T-818. Both probes spent months reporting `pass:false` while asserting nothing:
# _endpoint-overlap died of a TypeError before its last step ran (T-293 moved the halos out
# of the edge's <g> on 2026-07-28), and _saveproject parked in the note modal T-150/T-161
# added on 2026-07-09/10 and blamed the save path it had never invoked. Wiring them into the
# suite on the strength of a green run would repeat exactly the mistake that produced them:
# a probe is not shown to work by passing once.
#
# SO THIS CONTROL DRIVES BOTH BRANCHES, per probe, and they are different questions:
#
#   SUBJECT break    — the editor genuinely regresses. The probe must go RED.
#                      This is the branch everyone remembers to test.
#
#   STIMULUS break   — the editor changes in a way that makes the probe's gesture
#                      unreachable. The probe must go red NAMING THE MISSING STIMULUS,
#                      not fail some downstream assertion about a subject it never
#                      exercised. This is the branch that was missing for 56 and 75 days,
#                      and it is the one PL-206 is about: a control that CAN fail is
#                      worthless if its stimulus was built so it never fires.
#
# HOW: build a sandbox repo (tools/ + src/ + the one corpus map), mutate src/ there, and run
# the real probe out of it. Nothing touches the working tree. Each mutation asserts it
# matched EXACTLY ONCE — a mutation that silently does not apply turns "the probe caught it"
# into "the probe ran against unmutated source", which is this task's defect wearing a
# control's clothes.
#
# A clean baseline runs first for each probe. Without it a red result proves nothing.
#
# Exit: 0 all controls hold | 1 a control failed | 3 setup / could-not-measure

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP="arc-lifecycle"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

command -v node >/dev/null 2>&1 || cannot "node not on PATH"
for f in tools/_endpoint-overlap-verify-cdp.mjs tools/_saveproject-verify-cdp.mjs \
         tools/_cdp-attach.mjs tools/gallery-serve.py \
         "examples/aef-processes/rendered/$MAP.bpmn" src/aef-workflow-designer.html; do
    [ -f "$REPO/$f" ] || cannot "missing: $f"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A sandbox repo laid out exactly as the probes expect: they resolve REPO as
# dirname(import.meta.url)/.. and read src/ and examples/ from there. Copies, not symlinks —
# node resolves symlinked module paths to their real location, which would silently point
# the probe back at the working tree and make every mutation below a no-op.
build_sandbox() {
    rm -rf "$WORK/repo"
    mkdir -p "$WORK/repo/tools" "$WORK/repo/src" "$WORK/repo/examples/aef-processes/rendered"
    cp "$REPO"/tools/*.mjs "$WORK/repo/tools/"
    cp "$REPO/tools/gallery-serve.py" "$WORK/repo/tools/"
    cp "$REPO/src/aef-workflow-designer.html" "$WORK/repo/src/"
    cp "$REPO/examples/aef-processes/rendered/$MAP.bpmn" "$WORK/repo/examples/aef-processes/rendered/"
}

# mutate <file> <old> <new> — exactly one occurrence, or this is a setup failure. A mutation
# that does not land is indistinguishable in the result from a probe that failed to notice.
mutate() {
    python3 - "$1" "$2" "$3" <<'PY' || cannot "mutation did not apply cleanly to $1 — the source moved; this control is measuring nothing until it is updated"
import io, sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = io.open(p, encoding='utf-8').read()
if s.count(old) != 1:
    sys.stderr.write("expected 1 occurrence, found %d\n" % s.count(old)); sys.exit(1)
io.open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
}

run_probe() { timeout 240 node "$WORK/repo/tools/$1" > "$WORK/out" 2>&1; }

# step_state <step-name> -> pass | fail | absent
step_state() {
    python3 - "$WORK/out" "$1" <<'PY'
import io, json, sys
try:
    d = json.loads(io.open(sys.argv[1], encoding='utf-8').read())
except Exception:
    print('absent'); sys.exit(0)
for s in d.get('steps', []):
    if s.get('step') == sys.argv[2]:
        print('pass' if s.get('pass') else 'fail'); sys.exit(0)
print('absent')
PY
}

SRC="src/aef-workflow-designer.html"
echo "=== T-818 probe controls ==="

# ---------------------------------------------------------------- _endpoint-overlap
echo "-- _endpoint-overlap-verify-cdp.mjs"
build_sandbox
if run_probe _endpoint-overlap-verify-cdp.mjs; then
    ok "baseline: unmutated src -> probe PASSES"
else
    bad "baseline should pass" "the probe fails on clean source; every break below would be meaningless. Output: $(tail -3 "$WORK/out")"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# SUBJECT: revert the T-136 fix itself — drop the line in edgeHitTestAt that lets a sibling
# under the pointer win. The halo then swallows the click, which is the operator's original
# complaint. The probe must notice.
build_sandbox
mutate "$WORK/repo/$SRC" \
  "    if (preferNotId && id !== preferNotId) return id; // a sibling under the pointer wins" \
  "    // T-818 control: sibling preference removed on purpose"
if run_probe _endpoint-overlap-verify-cdp.mjs; then
    bad "subject break: T-136 fall-through removed" "the probe PASSED with the fix reverted — it does not guard the behaviour it is named for"
else
    st="$(step_state hittest-prefers-sibling)"
    if [ "$st" = "fail" ]; then
        ok "subject break: fall-through removed -> probe FAILS at hittest-prefers-sibling"
    else
        bad "subject break: wrong step reported" "probe failed, but hittest-prefers-sibling is '$st' — it went red for some other reason, which is not evidence it watches this"
    fi
fi

# STIMULUS: rename the halo's data-role, standing in for the T-293-class relocation that
# actually happened. The probe must report endpoint-halo-found false — NOT crash, and NOT
# fail some assertion about the editor, which it has not exercised.
build_sandbox
mutate "$WORK/repo/$SRC" \
  "class: 'edge-handle edge-handle-endpoint-hit', 'data-role': 'src'" \
  "class: 'edge-handle edge-handle-endpoint-hit', 'data-role': 'src-T818-moved'"
if run_probe _endpoint-overlap-verify-cdp.mjs; then
    bad "stimulus break: halo unreachable" "the probe PASSED with its own gesture impossible — the 56-day condition, unchanged"
else
    st="$(step_state endpoint-halo-found)"
    if [ "$st" = "fail" ]; then
        ok "stimulus break: halo unreachable -> named step endpoint-halo-found is red"
    else
        bad "stimulus break: not named" "endpoint-halo-found is '$st' — the probe went red without saying its gesture was unreachable, which is how this rotted unnoticed the first time"
    fi
fi

# ---------------------------------------------------------------- _saveproject
echo "-- _saveproject-verify-cdp.mjs"
build_sandbox
if run_probe _saveproject-verify-cdp.mjs; then
    ok "baseline: unmutated src -> probe PASSES"
else
    bad "baseline should pass" "the probe fails on clean source; every break below would be meaningless. Output: $(tail -3 "$WORK/out")"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# SUBJECT: the note the modal collected stops reaching the server. Everything else about the
# save still works, so this is precisely the leg added in T-818 and nothing else can catch it.
build_sandbox
mutate "$WORK/repo/$SRC" \
  "body: JSON.stringify({ id, bpmn, png, note })," \
  "body: JSON.stringify({ id, bpmn, png })," 
if run_probe _saveproject-verify-cdp.mjs; then
    bad "subject break: note dropped from POST" "the probe PASSED while the note the operator typed was discarded in transit"
else
    st="$(step_state note-roundtrip)"
    if [ "$st" = "fail" ]; then
        ok "subject break: note dropped -> probe FAILS at note-roundtrip"
    else
        bad "subject break: wrong step reported" "note-roundtrip is '$st' — the probe went red elsewhere, so this leg is not what caught it"
    fi
fi

# STIMULUS: the note step disappears from the save gesture. The save still SUCCEEDS — that is
# the point. A probe that only watched the outcome would go green and quietly stop testing the
# gesture the operator actually performs. This one must say the gesture changed.
build_sandbox
mutate "$WORK/repo/$SRC" \
  "    const note = await promptSaveNote(id);" \
  "    const note = '';   // T-818 control: modal step removed on purpose"
if run_probe _saveproject-verify-cdp.mjs; then
    bad "stimulus break: modal step removed" "the probe PASSED — it is watching the save's OUTCOME, not the operator's gesture, and would not notice the gesture changing under it again"
else
    st="$(step_state save-note-modal-opened)"
    if [ "$st" = "fail" ]; then
        ok "stimulus break: modal removed -> named step save-note-modal-opened is red"
    else
        bad "stimulus break: not named" "save-note-modal-opened is '$st' — red without naming the changed gesture, which is the 75-day condition"
    fi
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
