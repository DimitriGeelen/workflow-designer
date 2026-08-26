#!/usr/bin/env bash
# _t594-prose-claim-teeth.sh — guard the H2 attribution in the EWCR handoff envelope.
#
# HISTORY, because the guard's PROPERTY changed and that is the interesting part.
#
# T-593 found a manufactured claim that the operator had resolved H2, and removed it from
# the envelope's STRUCTURED fields — verifying that by walking YAML keys ending in `_by`.
# T-594 found the same claim still alive in PROSE, because a key-walker cannot see prose,
# and added an absence check: no free text may assert an operator resolution.
#
# T-595: the operator ANSWERED H2 in session. The assertion is now TRUE. An absence check
# would fire on a legitimate, correctly-sourced record and would push the fix toward
# deleting the operator's own decision to go green — the same failure mode as T-594's first
# draft, which would have deleted governance history.
#
# So the guard changes property rather than being deleted:
#
#   OLD (T-594):  no text may claim the operator resolved H2
#   NEW (T-595):  a resolution is allowed — but ONLY WITH PROVENANCE. If status is
#                 `resolved`, there must be a `decision_record` that quotes a source.
#
# That is the difference between the fabricated attribution and the real one. It was never
# the words; it was whether anyone could check them. A guard keyed on the words could not
# tell the two apart. This one can.
#
# Exits 0 only if every direction holds. Poisons COPIES under mktemp; tracked files are
# never written.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1

ENV_FILE="docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml"
[ -f "$ENV_FILE" ] || { echo "FAIL  envelope missing: $ENV_FILE"; exit 1; }

fail=0

# The check under test, as a function, so every arm runs the IDENTICAL expression.
provenance_check() {
  python3 - "$1" <<'PY'
import sys, yaml
try:
    r = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))['to_project_resolution']
except Exception as e:
    print(f"    unreadable: {e}"); sys.exit(1)
if r.get('status') != 'resolved':
    # Unresolved is always acceptable — the question simply stands open.
    sys.exit(0)
rec = (r.get('decision_record') or '').strip()
if len(rec) < 200:
    print(f"    resolved with no usable decision_record (len={len(rec)})"); sys.exit(1)
if '"' not in rec and "'" not in rec:
    print("    decision_record quotes no source — provenance is unverifiable"); sys.exit(1)
if not r.get('decided_by'):
    print("    resolved with no decided_by"); sys.exit(1)
sys.exit(0)
PY
}

# ── Direction 1: the real envelope must be accepted ────────────────────────────
if provenance_check "$ENV_FILE"; then
  echo "PASS  real-envelope-accepted         (resolution carries quoted provenance)"
else
  echo "FAIL  real-envelope-accepted         (see reason above)"
  fail=1
fi

# ── Direction 2: resolutions WITHOUT provenance must be rejected ───────────────
# One arm per way the provenance can be missing. A guard that only caught the exact shape
# we already fixed would pass this control while staying blind to the next instance.
poison() {
  local label="$1"; shift
  local tmp; tmp="$(mktemp -d)"; local f="$tmp/env.yaml"
  cp "$ENV_FILE" "$f"
  python3 - "$f" "$@" <<'PY'
import sys, yaml, io
p = sys.argv[1]; mode = sys.argv[2]
d = yaml.safe_load(open(p, encoding='utf-8'))
r = d['to_project_resolution']
if mode == 'drop_record':
    r.pop('decision_record', None)
elif mode == 'empty_record':
    r['decision_record'] = '   '
elif mode == 'unquoted_record':
    r['decision_record'] = 'The operator decided this at some point. ' * 8
elif mode == 'drop_decider':
    r.pop('decided_by', None)
yaml.safe_dump(d, open(p, 'w', encoding='utf-8'))
PY
  if provenance_check "$f" >/dev/null 2>&1; then
    echo "FAIL  poison-rejected [$label]       (rc 0 — GUARD IS BLIND to this shape)"
    fail=1
  else
    echo "PASS  poison-rejected [$label]"
  fi
  rm -rf "$tmp"
}

poison "no-decision-record"   drop_record
poison "empty-record"         empty_record
poison "record-quotes-nobody" unquoted_record
poison "no-decided-by"        drop_decider

# ── Direction 3: the guard must not be trivially green ─────────────────────────
# An unresolved envelope is legitimately accepted, so `exit 0` alone proves nothing about
# the guard's ability to fail. Direction 2 covers that — this arm proves the ACCEPT path is
# reachable for a resolved envelope, i.e. the guard is not simply rejecting everything.
tmp="$(mktemp -d)"
cp "$ENV_FILE" "$tmp/env.yaml"
if provenance_check "$tmp/env.yaml" >/dev/null 2>&1; then
  echo "PASS  accept-path-reachable          (a properly sourced resolution passes)"
else
  echo "FAIL  accept-path-reachable          (guard rejects even a well-formed record)"
  fail=1
fi
rm -rf "$tmp"

# ── Direction 4: the T-593 correction record must survive ──────────────────────
# The artifact should keep evidence that a fabricated attribution once stood here. A "fix"
# that quietly dropped it would look identical to a clean history.
if python3 -c "
import yaml,sys
r=yaml.safe_load(open('$ENV_FILE',encoding='utf-8'))['to_project_resolution']
c=(r.get('correction') or '')
sys.exit(0 if ('T-593' in c and len(c)>200) else 1)"; then
  echo "PASS  correction-record-preserved    (the fabricated attribution stays on record)"
else
  echo "FAIL  correction-record-preserved    (T-593's correction note was lost)"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "7/7 T-595 provenance guard legs passed"
  exit 0
fi
echo "T-595 provenance guard legs FAILED"
exit 1
