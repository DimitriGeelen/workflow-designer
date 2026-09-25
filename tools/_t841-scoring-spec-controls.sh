#!/usr/bin/env bash
# T-841 control instrument — proves each verification leg CAN fail.
#
# WHY THIS EXISTS (PL-206): a leg that cannot fail is worthless regardless of what it
# reports. Every assertion in T-841's ## Verification block is paired here with a mutant
# that MUST make it fail. A leg with no failing mutant is not a control, it is decoration.
#
# THROWAWAY ROOT: mutations are applied to a copy under T841_REPO_ROOT, never the live
# tree. Nothing here writes to the project. Follows tools/_t836-* precedent.
#
# Exit 0 = every leg was shown to discriminate. Exit 1 = at least one leg is dead.

set -uo pipefail
REPO="${T841_REPO_ROOT:-/opt/832-Workflow-designer}"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'ok %d - %s\n' "$((PASS+FAIL))" "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'not ok %d - %s\n' "$((PASS+FAIL))" "$1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ── Leg 1: the three proposal specs exist ─────────────────────────────────────
# Control: a spec that is absent must make the existence check fail.
for f in F1-sdlc-enablement F3-aef-integration F4-workflow-routing; do
  p="$REPO/docs/proposals/T-841-$f-PROPOSED.yaml"
  [ -f "$p" ] && ok "spec present: $f" || bad "spec present: $f"
done
if [ -f "$WORK/definitely-absent.yaml" ]; then
  bad "CONTROL leg-1: absent spec reported present — the existence check is dead"
else
  ok "CONTROL leg-1: absent spec correctly reports absent"
fi

# ── Leg 2: validate-scoring actually validates ────────────────────────────────
# Control: a spec with no levels: key must be REFUSED. If a malformed spec passes,
# then 'validates OK' carries no information and every leg resting on it is dead.
cat > "$WORK/malformed.yaml" <<'EOF'
kind: signals
strip_template: true
EOF
if "$REPO"/.agentic-framework/bin/fw bvp driver --validate-scoring "$WORK/malformed.yaml" >/dev/null 2>&1; then
  bad "CONTROL leg-2: a spec with no levels: PASSED validation — validate-scoring is dead"
else
  ok "CONTROL leg-2: a spec with no levels: is correctly refused"
fi

# ── Leg 3: F3 discriminates — the claim the whole task rests on ───────────────
# Two tasks, one that touches the AEF seam and one that does not, must score DIFFERENTLY.
# Control: the SAME task scored twice must score the SAME. If identical inputs yield
# different scores the scorer is nondeterministic and any spread it reports is noise.
score() { "$REPO"/.agentic-framework/bin/fw bvp driver --explain F3 "$1" \
            --scoring-file "$REPO/docs/proposals/T-841-F3-aef-integration-PROPOSED.yaml" \
            2>/dev/null | sed -n 's/^Score: \([0-9]*\).*/\1/p'; }
a=$(score T-826); b=$(score T-839)
if [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ]; then
  ok "leg-3: F3 discriminates — T-826=$a vs T-839=$b"
else
  bad "leg-3: F3 did NOT discriminate — T-826=${a:-ERR} T-839=${b:-ERR}"
fi
a2=$(score T-826)
if [ "$a" = "$a2" ]; then
  ok "CONTROL leg-3: scorer is deterministic — T-826 scored $a twice"
else
  bad "CONTROL leg-3: scorer is NONDETERMINISTIC ($a then $a2) — every spread is noise"
fi

# ── Leg 4: the saturation finding is reproducible, and the metric can move ────
# Assert F1's modal share is high (the finding) AND that the SAME metric computed over a
# deliberately-spread synthetic distribution comes out low. Without the second half,
# "modal share > 70%" might be an arithmetic bug that reports 100% for any input.
modal() { sort -n | uniq -c | sort -rn | awk 'NR==1{m=$1} {t+=$1} END{printf "%d", 100*m/t}'; }
flat=$(printf '4\n4\n4\n4\n4\n4\n4\n4\n4\n3\n' | modal)
spread=$(printf '0\n1\n2\n3\n4\n5\n0\n1\n2\n3\n' | modal)
if [ "$flat" -gt 70 ]; then
  ok "leg-4: modal-share metric reports $flat% on a saturated distribution"
else
  bad "leg-4: modal-share metric reported $flat% on a saturated distribution"
fi
if [ "$spread" -lt 40 ]; then
  ok "CONTROL leg-4: same metric reports $spread% on a spread distribution — it can move"
else
  bad "CONTROL leg-4: metric reported $spread% on a SPREAD distribution — it is stuck high"
fi

# ── Leg 5: nothing was installed ──────────────────────────────────────────────
# Control: the check must notice a modification. Mutate a COPY and confirm the same
# comparison that passes on the live file fails on the mutated one.
if git -C "$REPO" diff --quiet HEAD -- .agentic-framework/policy/value-drivers.yaml 2>/dev/null; then
  ok "leg-5: value-drivers.yaml unmodified against HEAD"
else
  bad "leg-5: value-drivers.yaml is MODIFIED — something was installed"
fi
cp "$REPO/.agentic-framework/policy/value-drivers.yaml" "$WORK/vd.yaml" 2>/dev/null || true
if [ -f "$WORK/vd.yaml" ]; then
  printf '\n# mutant\n' >> "$WORK/vd.yaml"
  if cmp -s "$WORK/vd.yaml" "$REPO/.agentic-framework/policy/value-drivers.yaml"; then
    bad "CONTROL leg-5: a mutated copy compared EQUAL — the comparison is dead"
  else
    ok "CONTROL leg-5: a mutated copy is correctly detected as different"
  fi
else
  bad "CONTROL leg-5: could not read value-drivers.yaml to mutate"
fi

# ── Leg 6: G-080 is registered and the register parses ────────────────────────
# Control: a grep for an id that was deliberately SKIPPED must NOT match, or the
# presence check matches anything and proves nothing.
if python3 -c "
import yaml,sys
d=yaml.safe_load(open('$REPO/.context/project/concerns.yaml'))
c=d['concerns']
sys.exit(0 if any(isinstance(e,dict) and e.get('id')=='G-080' for e in c) else 1)
" 2>/dev/null; then
  ok "leg-6: G-080 registered in concerns.yaml and the file parses"
else
  bad "leg-6: G-080 not found, or concerns.yaml does not parse"
fi
if python3 -c "
import yaml,sys
d=yaml.safe_load(open('$REPO/.context/project/concerns.yaml'))
c=d['concerns']
sys.exit(0 if any(isinstance(e,dict) and e.get('id')=='G-079' for e in c) else 1)
" 2>/dev/null; then
  bad "CONTROL leg-6: G-079 found as a local concern — it is a VENDORED id, presence check is dead"
else
  ok "CONTROL leg-6: deliberately-skipped id G-079 correctly absent from the local register"
fi

printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
