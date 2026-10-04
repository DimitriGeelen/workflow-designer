#!/usr/bin/env bash
# _t1028-note-resolve-teeth.sh — `fw note resolve` gives a fixed observation an exit, with a carrier.
#
# WHY (T-914, erased silently by the 1.7.740 re-vendor; found by the T-1020 census): the inbox's
# largest class is "already fixed, content lives elsewhere". Dismiss records a decision nobody made,
# promote files a duplicate task, so with no resolve verb those stay PENDING forever — which is why
# the inbox grows monotonically (128 pending at the census). The carrier is MANDATORY and VALIDATED:
# resolved-with-no-pointer is the same defect T-912 removed from promote.
#
# Legs (scratch project, real CLI, hermetic):
#   1. resolve with a real task carrier: status resolved + carrier/kind/at recorded
#   2. resolve with an existing path carrier and a reason: reason recorded
#   3. every OTHER entry in the inbox is byte-identical after a resolve
#   4. refusals write nothing: no carrier; a task id with no task file; a path that does not exist;
#      an observation that is not pending
# Exit 0 = all legs pass, 1 = a leg fails, 2 = cannot run.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FWR="${T1028_FRAMEWORK:-$ROOT/.agentic-framework}"
[ -x "$FWR/agents/observe/observe.sh" ] || { echo "CANNOT RUN: no observe.sh under $FWR"; exit 2; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/        /' | head -6; }

P="$T/p"
mkdir -p "$P/.tasks/active" "$P/.tasks/completed" "$P/.tasks/templates" "$P/.context/project" "$P/docs"
cp "$ROOT/.tasks/templates/default.md" "$P/.tasks/templates/" 2>/dev/null || true
printf 'project_name: t1028\n' > "$P/.framework.yaml"; git -C "$P" init -q 2>/dev/null
printf -- '---\nid: T-500\nname: carrier\nstatus: work-completed\n---\n' > "$P/.tasks/completed/T-500-carrier.md"
printf 'notes\n' > "$P/docs/thread.md"
note() { (cd "$P" && PROJECT_ROOT="$P" FRAMEWORK_ROOT="$FWR" CLAUDECODE= "$FWR/agents/observe/observe.sh" "$@") 2>&1; }
field() { python3 - "$P/.context/inbox.yaml" "$1" "$2" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
for o in d.get('observations', []) or []:
    if o.get('id') == sys.argv[2]:
        print(o.get(sys.argv[3])); break
PY
}
others_hash() { python3 - "$P/.context/inbox.yaml" "$1" <<'PY'
import sys, hashlib
lines = open(sys.argv[1]).read().split("\n"); out, skip = [], False
for l in lines:
    if l.startswith("- id: "):
        skip = l.strip() == "- id: " + sys.argv[2]
    if not skip:
        out.append(l)
print(hashlib.sha256("\n".join(out).encode()).hexdigest())
PY
}
cap() { note "$1" | grep -oE 'OBS-[0-9]+' | head -1; }

echo "=== T-1028: fw note resolve ==="
o1=$(cap "fixed already by the carrier task"); o2=$(cap "thread continued in a doc"); o3=$(cap "an unrelated pending one")
[ -n "$o1" ] && [ -n "$o3" ] || { echo "CANNOT RUN: capture produced no OBS ids"; exit 2; }

before=$(others_hash "$o1")
out=$(note resolve "$o1" --carrier T-500)
if [ "$(field "$o1" status)" = "resolved" ] && [ "$(field "$o1" resolved_carrier)" = "T-500" ] \
   && [ "$(field "$o1" resolved_carrier_kind)" = "task" ] && [ "$(field "$o1" resolved_at)" != "None" ]; then
  ok "resolve with a task carrier records status, carrier, kind and time"
else bad "resolve with a task carrier" "$out"; fi
[ "$before" = "$(others_hash "$o1")" ] && ok "every other inbox entry is byte-identical" || bad "other entries changed"

out=$(note resolve "$o2" --carrier docs/thread.md --reason "moved to the design thread")
if [ "$(field "$o2" status)" = "resolved" ] && [ "$(field "$o2" resolved_carrier_kind)" = "path" ] \
   && [ "$(field "$o2" resolved_reason)" = "moved to the design thread" ]; then
  ok "resolve with a path carrier records the reason"
else bad "resolve with a path carrier and reason" "$out"; fi

refuse() { # $1 label, rest = args; the target must stay pending and the call must fail
  local label="$1"; shift
  local snap; snap=$(sha256sum "$P/.context/inbox.yaml" | cut -c1-64)
  out=$(note resolve "$@"); rc=$?
  if [ "$rc" -ne 0 ] && [ "$snap" = "$(sha256sum "$P/.context/inbox.yaml" | cut -c1-64)" ]; then ok "refused, nothing written: $label"
  else bad "must refuse and write nothing: $label (rc=$rc)" "$out"; fi
}
refuse "no carrier"                      "$o3"
refuse "task id with no task file"       "$o3" --carrier T-999
refuse "path that does not exist"        "$o3" --carrier docs/nope.md
refuse "observation that is not pending" "$o1" --carrier T-500

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
