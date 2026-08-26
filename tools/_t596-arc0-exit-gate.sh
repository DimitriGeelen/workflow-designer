#!/usr/bin/env bash
# _t596-arc0-exit-gate.sh — evaluate the Arc-0 exit gate's third clause, and prove the
# evaluation can fail.
#
#   (no args)     run the gate against the real register. Exit 0 satisfied / 1 blocked /
#                 2 integrity violation.
#   --self-test   run the poison controls. Exit 0 only if every arm behaves.
#
# WHY --self-test EXISTS
#
# The real register is BLOCKED (exit 1) and will stay blocked until the operator answers
# H1/H3/H5/H6. A gate that is red anyway proves nothing by being red — a gate that had
# silently stopped reading its input would look identical. So the controls do not ask
# "is it red"; they ask "is it red for the STATED reason, and can it be green at all".
#
# Every arm poisons a COPY under mktemp. Tracked files are never written.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1

REG="docs/research/executable-workflow/operator-decisions.yaml"
ENV_FILE="docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml"
CHECK="tools/_t596_arc0_check.py"

for f in "$REG" "$ENV_FILE" "$CHECK"; do
  [ -f "$f" ] || { echo "FAIL  missing input: $f"; exit 2; }
done

if [ "${1:-}" != "--self-test" ]; then
  exec python3 "$CHECK" "$REG" "$ENV_FILE" "$REPO"
fi

fail=0

# ── Arm 1: the real register must be BLOCKED (1), not integrity-violating (2) ──
# This is the honest current state. If it ever returns 2, the register itself broke.
python3 "$CHECK" "$REG" "$ENV_FILE" "$REPO" --quiet >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 1 ]; then
  echo "PASS  real-register-blocked-cleanly   (rc 1 — open questions, integrity intact)"
elif [ "$rc" -eq 0 ]; then
  echo "PASS  real-register-satisfied         (rc 0 — every blocking question answered)"
else
  echo "FAIL  real-register-blocked-cleanly   (rc $rc — integrity violation in the live register)"
  fail=1
fi

# ── Arm 2: the ACCEPT path must be reachable, using only REAL entries ─────────
# Drop the open questions and keep H2 and H4, both of which carry genuine, externally
# sourced operator decisions. If this cannot go green, the gate rejects everything and
# its red on the real register would mean nothing.
tmp="$(mktemp -d)"
python3 - "$REG" "$tmp/accept.yaml" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
d['questions'] = [q for q in d['questions'] if q.get('status') == 'resolved']
yaml.safe_dump(d, open(sys.argv[2], 'w', encoding='utf-8'))
PY
python3 "$CHECK" "$tmp/accept.yaml" "$ENV_FILE" "$REPO" --quiet >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "PASS  accept-path-reachable           (real resolved entries alone satisfy clause 3)"
else
  echo "FAIL  accept-path-reachable           (gate rejects even properly sourced entries)"
  fail=1
fi
rm -rf "$tmp"

# ── Arm 3+: integrity poisons must return 2, not merely non-zero ──────────────
# rc 1 would mean the gate noticed nothing and was red only because of the open
# questions that were already there — a blind pass. Only rc 2 counts.
poison() {
  local label="$1" mode="$2"
  local tmp; tmp="$(mktemp -d)"
  python3 - "$REG" "$tmp/p.yaml" "$mode" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
mode = sys.argv[3]
qs = d['questions']
h2 = next(q for q in qs if q['id'] == 'H2')
if mode == 'self_certify':
    h2.pop('source_of_truth', None)
elif mode == 'absent_source':
    h2['source_of_truth']['file'] = 'docs/research/executable-workflow/no-such-file.yaml'
elif mode == 'disagree_chosen':
    h2['chosen'] = '/opt/0503-codex-cli-playground'
elif mode == 'agent_decided':
    h2['decided_by'] = 'agent'
elif mode == 'unsourced_new_resolution':
    # The shape that matters most: an open question flipped to resolved with no source.
    h1 = next(q for q in qs if q['id'] == 'H1')
    h1['status'] = 'resolved'
    h1['decided_by'] = 'operator'
yaml.safe_dump(d, open(sys.argv[2], 'w', encoding='utf-8'))
PY
  python3 "$CHECK" "$tmp/p.yaml" "$ENV_FILE" "$REPO" --quiet >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "PASS  poison-caught [$label]"
  else
    echo "FAIL  poison-caught [$label]         (rc $rc — expected 2; GUARD IS BLIND to this shape)"
    fail=1
  fi
  rm -rf "$tmp"
}

poison "register-self-certifies"   self_certify
poison "source-file-absent"        absent_source
poison "register-contradicts-env"  disagree_chosen
poison "agent-recorded-as-decider" agent_decided
poison "open-flipped-unsourced"    unsourced_new_resolution

if [ "$fail" -eq 0 ]; then
  echo "7/7 T-596 Arc-0 exit gate control legs passed"
  exit 0
fi
echo "T-596 Arc-0 exit gate control legs FAILED"
exit 1
