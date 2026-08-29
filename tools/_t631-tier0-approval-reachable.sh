#!/bin/bash
# T-631 — is the Tier-0 approval route reachable while Tier 0 is blocking? And is any
# OTHER registered hook printing a remedy it would refuse?
#
# WHY THIS ONE WAS WORTH ASKING FIRST. G-020 (T-628) wedged an agent, which held a second
# write surface and escaped. check-tier0 is matched on Bash and prints `fw tier0 approve`
# as its route forward — a Bash command, passing back through the hook that just blocked.
# If that were refused, the wedged party would be the OPERATOR, at the exact moment the
# framework is asking them to exercise sovereignty, and with no second surface to escape
# through. Strictly worse than the instance that started this.
#
# THE ANSWER IS NO, AND THE NEGATIVE IS THE POINT. Measured below: the control fires and
# the remedy passes. Recording a clean negative with its evidence is the difference
# between "we checked" and "we assumed"; PL-205 in this project is about exactly the
# absences that get reported without being measured.
#
# THE REFINEMENT THIS PRODUCED, which is the part worth keeping. AEF's rule (@775) is
# "run the remedy verbatim while the gate is firing". 577 added (@776) "and through the
# same surface the gate is restricting". Working this one surfaced a third clause:
#
#     AND BY THE PARTY THE REMEDY ADDRESSES.
#
# `fw tier0 approve` is the operator's act. An operator types it in their own terminal,
# where PreToolUse hooks do not run at all — so for the party it addresses, this remedy is
# reachable by construction, and measuring it against the agent's surface would have
# answered a question nobody asked. The measurement below is still worth having, because
# "the hook does not classify its own remedy as destructive" is a real property that a
# future pattern change could break.
#
# AND THE TRIAGE RULE, which is what makes the population closeable rather than a
# 9-hook slog: A REMEDY IS ONLY AT RISK WHEN THE HOOK THAT PRINTS IT MATCHES THE TOOL THE
# REMEDY NEEDS. A Write-matched hook prescribing a Bash command cannot refuse it — the
# hook never sees it. That narrows the registered PreToolUse population from nine hooks to
# the two that are Bash-matched AND print Bash remedies: check-tier0 (this file) and
# check-active-task (T-386/T-628/T-629, all three of its gates). Leg 3 below re-derives
# that from .claude/settings.json on every run, so adding a tenth hook that breaks the
# assumption fails here instead of silently widening the unprobed set.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
HOOK="$PROJ/.agentic-framework/agents/context/check-tier0.sh"
SETTINGS="$PROJ/.claude/settings.json"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t631-$$-$(date +%s)"
MUT="$(dirname "$HOOK")/.t631-mutant-$$.sh"
trap 'rm -f "$MUT" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active"
printf 'project: t631-sandbox\n' > "$SANDBOX/.framework.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

run_hook() {  # <hook> <command>  -> RC, OUT
    local hook="$1" cmd="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

echo "=== T-631 Tier-0 approval reachability ==="
echo

echo "--- anti-vacuity: the gate must actually fire on something"
# NOTHING is approved by this file. The control is a destructive command against a
# throwaway sandbox root, and the assertion is on the hook's banner — the pending-approval
# file it writes lands in the sandbox and dies with it.
run_hook "$HOOK" 'git push --force origin master'
if printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
    ok "control: a destructive command is blocked (banner present)"
else
    bad "control: Tier 0 did not fire — every leg below would be vacuous"
    echo "COULD-NOT-MEASURE: no firing gate to measure a remedy against." >&2
    exit 3
fi

echo
echo "--- the printed CLI remedy, run verbatim through the gate that prints it"
run_hook "$HOOK" 'fw tier0 approve'
if [ "$RC" -eq 0 ] && ! printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
    ok "'fw tier0 approve' is NOT refused by Tier 0 (rc=0) — the route forward is open"
else
    bad "Tier 0 refuses its own approval command (rc=$RC) — the OPERATOR is wedged"
fi

echo
echo "--- population: which registered PreToolUse hooks could refuse their own remedy?"
# Re-derived from the enforcement registry every run rather than pinned as a list, so a
# newly added hook widens the check instead of silently escaping it.
python3 - "$SETTINGS" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
bash_matched = []
for m in d.get("hooks", {}).get("PreToolUse", []):
    matcher = m.get("matcher", "*")
    for h in m.get("hooks", []):
        name = h.get("command", "").split()[-1]
        # A remedy that is a shell command can only be refused by a hook that sees Bash.
        if "Bash" in matcher or matcher in ("*", ""):
            bash_matched.append(name)
print("  Bash-matched PreToolUse hooks: %d" % len(bash_matched))
for n in sorted(bash_matched):
    print("    - %s" % n)
open("/tmp/t631-bashmatched.txt", "w").write("\n".join(sorted(bash_matched)))
PY

# The two that are Bash-matched AND print Bash-shaped remedies are the two already
# probed. budget-gate and check-project-boundary are Bash-matched but their remedies are
# not commands they would refuse (budget-gate explicitly allowlists commit/handover at
# critical; the boundary gate's remedy is "write inside the project", not a command).
UNPROBED=$(grep -vE 'check-tier0|check-active-task|budget-gate|check-project-boundary' /tmp/t631-bashmatched.txt 2>/dev/null || true)
if [ -z "$UNPROBED" ]; then
    ok "every Bash-matched hook is either probed (tier0, active-task) or has a non-command remedy"
else
    bad "Bash-matched hook(s) with no remedy-reachability probe: $(echo $UNPROBED | tr '\n' ' ')"
fi
rm -f /tmp/t631-bashmatched.txt

echo
echo "--- teeth (mutate live source, assert the remedy leg goes RED)"
# Make the classifier treat the remedy itself as destructive. If the leg above cannot be
# turned red by that, it was not measuring the classifier at all.
python3 - "$HOOK" "$MUT" <<'PY'
import sys
src = open(sys.argv[1]).read()
# Add a pattern that matches the REMEDY itself. This is the only mutation that can move
# the leg above: it makes the classifier treat `fw tier0 approve` as destructive, which is
# precisely the world the leg claims we are not in.
#
# An earlier draft of these teeth injected a no-op `case` and asserted only that the
# mutant still reached the block. That certified nothing — it could not have turned the
# remedy leg red, so the leg's greenness was never in question and the "teeth" were
# decoration. Same family as the partial mutation in T-629 and 577's `!`-inverted leg
# (@774 item 5): the instrument reports success while measuring less than it claims.
# THE MUTATION MUST TARGET THE LAYER THAT ACTUALLY DECIDES FOR THIS INPUT.
#
# check-tier0 has TWO independent classifiers: a bash keyword pre-filter that `exit 0`s
# on anything not matching a short regex, and only then the Python PATTERNS list. A first
# attempt at these teeth added a PATTERNS entry for the remedy — and the leg stayed
# green, correctly, because `fw tier0 approve` never reaches PATTERNS. The pre-filter had
# already let it out.
#
# That is the sharper reason the remedy is reachable, and it is not the reason we
# assumed: not "no pattern matches it" but "it never gets as far as the patterns". The
# pre-filter already screens some `fw` verbs (`fw .*--force`, `fw .*inception .*decide`),
# so `fw` is genuinely in its scope — one more clause there and the operator's approval
# route would start being refused. Which is what the leg above now guards.
#
# Generalised: A MUTATION AIMED AT THE WRONG LAYER PRODUCES A GREEN LEG AND LOOKS LIKE
# CONFIRMATION. Ours went red instead only because the leg asserts the blocked banner
# rather than the mutation having been applied.
anchor = "|fw\\s.*inception\\s.*decide'"
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: pre-filter anchor not found exactly once — teeth cannot certify anything\n")
    sys.exit(1)
src = src.replace(anchor, "|fw\\s.*inception\\s.*decide|fw\\s.*tier0\\s.*approve'", 1)
pat_anchor = "PATTERNS = [\n"
inject = pat_anchor + "    (r'\\btier0\\s+approve\\b', 'T-631 MUTANT: the remedy, classified as destructive'),\n"
open(sys.argv[2], 'w').write(src.replace(pat_anchor, inject, 1))
PY
if [ ! -s "$MUT" ]; then
    bad "teeth: could not build the mutant — no teeth were demonstrated"
elif ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: mutant has a syntax error — cannot certify the leg"
else
    ok "teeth: mutant parses (its failure below is behavioural, not syntactic)"
    run_hook "$MUT" 'git push --force origin master'
    if printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
        ok "teeth: mutant still reaches the Tier-0 block (the leg below is about the right gate)"
        run_hook "$MUT" 'fw tier0 approve'
        if printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
            ok "teeth: a classifier that DID match the remedy turns the leg red — it has bite"
        else
            bad "teeth: even a classifier matching the remedy leaves the leg green — it measures nothing"
        fi
    else
        bad "teeth: mutant does not reach the Tier-0 block — teeth would be vacuous"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
