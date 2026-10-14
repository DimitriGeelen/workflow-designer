#!/bin/bash
# _t1178-inception-template.sh — T-1178: the project inception template works end to end and survives an upgrade.
#  1. an inception created from it (temp project) carries ## Hypothesis and the score fields;
#  2. AEF's T-2188 schema hook allows an ordinary edit of it;
#  3. the T-866 GO gate refuses the unfilled placeholder and passes a filled hypothesis;
#  4. AEF's upgrade template sync (T-3965), dry-run on a COPY, would KEEP it (not overwrite it again, as 1.8.2 did).
# Prints one ok/FAIL line per check; exit 0 only if no FAIL. Nothing in the repo is written.
# Usage: _t1178-inception-template.sh [template]   (default: the repo's .tasks/templates/inception.md)
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW=$REPO/.agentic-framework
U=${AEF_ROOT:-/opt/999-Agentic-Engineering-Framework}
REL=.tasks/templates/inception.md
TMPL=${1:-$REPO/$REL}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*"; fails=$((fails + 1)); }

mkdir -p "$T/p/.tasks/active" "$T/p/.tasks/completed" "$T/p/.context/working"
cp -r "$REPO/.tasks/templates" "$T/p/.tasks/"
cp "$TMPL" "$T/p/$REL"
(cd "$T/p" && git init -q .)
if ! (cd "$T/p" && PROJECT_ROOT="$T/p" bash "$FW/agents/task-create/create-task.sh" --name "Probe inception" --type inception \
      --owner agent --recommendation GO --rationale "throwaway probe for T-1178" --description "probe" >/dev/null 2>"$T/create.err"); then
  fail "an inception could not be created from the template:"; tail -5 "$T/create.err"; exit 1
fi
F=$(ls "$T"/p/.tasks/active/T-*.md | head -1)

# 1. what the created inception carries
grep -q '^## Hypothesis$' "$F" && ok "the created inception has ## Hypothesis" || fail "the created inception has no ## Hypothesis"
grep -q 'We will know that we are successful when we see' "$F" && ok "it has the success-clause phrase the gate looks for" || fail "no success-clause phrase"
grep -q '^voi_score: ' "$F" && grep -q '^target_blast_radius: ' "$F" && ok "it has the score fields T-2188 requires" || fail "score fields missing"
grep -q 'voi_score_source: human' "$F" && ok "it says how to override a score (T-865)" || fail "no T-865 override note"

# 2. AEF's schema hook on an ordinary edit of it
python3 - "$F" > "$T/hook.json" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Edit", "tool_input": {"file_path": sys.argv[1], "old_string": "## Problem Statement", "new_string": "## Problem Statement\n\nProbe."}}))
PY
if PROJECT_ROOT="$T/p" bash "$FW/agents/context/check-inception-schema.sh" < "$T/hook.json" >/dev/null 2>"$T/hook.err"; then
  ok "the T-2188 schema hook allows an edit of it"
else
  fail "the T-2188 schema hook refuses an edit of it"; tail -3 "$T/hook.err"
fi

# 3. the T-866 GO gate
# shellcheck disable=SC1091
source "$FW/lib/task-audit.sh" 2>/dev/null
if ! command -v audit_inception_hypothesis >/dev/null; then fail "the GO gate function did not load"; exit 1; fi
if audit_inception_hypothesis "$F" go >/dev/null 2>&1; then fail "the GO gate passed the unfilled placeholder"; else ok "the GO gate refuses the unfilled placeholder"; fi
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
t = t.replace("We believe that <change>,", "We believe that restoring the template,")
t = t.replace("we will achieve <outcome>.", "we will achieve inceptions that pass the GO gate.")
t = t.replace("We will know that we are successful when we see <measurable signal>.",
              "We will know that we are successful when we see fw verify-queue --task T-866 report 8/8 passed.")
open(p, "w").write(t)
PY
if audit_inception_hypothesis "$F" go >/dev/null 2>"$T/gate.err"; then ok "the GO gate passes once the hypothesis is filled"; else fail "the GO gate refuses a filled hypothesis"; tail -3 "$T/gate.err"; fi

# 4. the current upgrade would keep it
if [ -f "$U/lib/upgrade_template_sync.py" ]; then
  mkdir -p "$T/u/.tasks/templates" && cp "$TMPL" "$T/u/$REL"
  out=$(python3 "$U/lib/upgrade_template_sync.py" "$T/u" "$U/$REL" "$REL" --dry-run "--known=$U/lib/upgrade_template_shipped.py" 2>&1)
  case "$out" in
    WOULD-KEPT*) ok "an upgrade would keep it (upstream copy goes to .upstream)";;
    *) fail "an upgrade would not keep it: $out";;
  esac
else
  echo "SKIP upgrade check: no $U/lib/upgrade_template_sync.py"
fi

[ "$fails" -eq 0 ] && { echo "PASS — inception template"; exit 0; }
echo "FAIL — $fails check(s)"; exit 1
