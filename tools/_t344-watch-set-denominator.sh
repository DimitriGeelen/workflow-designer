#!/usr/bin/env bash
# _t344-watch-set-denominator.sh — a coverage check whose denominator is empty
# must be RED, not green.
#
# THE DEFECT THIS EXISTS FOR. `.fabric/watch-patterns.yaml` shipped as the
# untailored `fw context init` default and matched zero files in this repo. Both
# of audit.sh's fabric coverage checks then compared the empty set against the
# registry and printed:
#
#     [PASS] Fabric: 17 registered, 0 unregistered
#     [PASS] Fabric drift: All watched source files registered (17 cards)
#
# Both statements are TRUE of an empty watch set, and both read as full coverage.
# 13% of our source was carded. The failure direction was green, so no moment of
# attention was ever created and it sat from 28 Jul.
#
# WHY THE CONFIG EDIT IS NOT THE FIX. `fw context init` regenerates that default
# whenever it runs, and its patterns are plausible enough to survive a glance
# (src/**/*.py, web/, agents/, bin/, crates/, **/*.ts, **/*.go — a reasonable
# project, just not this one). Tailoring the file fixes today's instance; this
# guard is what makes the class report itself. Legs 1-2 assert the config, legs
# 3-6 assert that the AUDIT would say so if the config regressed.
#
# WHY IT DRIVES audit.sh's REAL BRANCHES. Legs 3-6 extract the two verdict
# branches from audit.sh at runtime rather than restating them here. A restated
# branch keeps agreeing with a string literal long after the shipped one changed
# — a false green about a false green (PL-061, and the T-352 gate lesson).
#
# Usage: bash tools/_t344-watch-set-denominator.sh
# Exit 0 = watch set non-empty AND both audit branches report an empty one.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WATCH="${T344_WATCH:-$REPO/.fabric/watch-patterns.yaml}"
AUDIT="${T344_AUDIT:-$REPO/.agentic-framework/agents/audit/audit.sh}"
EXPANDER="$REPO/.agentic-framework/agents/fabric/lib/expand_patterns.py"

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "T-344 — is the fabric coverage denominator non-empty, and does an empty one go red?"
echo

# --- 1-2: the config itself ---------------------------------------------------
n=$(python3 "$EXPANDER" "$WATCH" "$REPO" 2>/dev/null | wc -l)
if [ "${n:-0}" -gt 0 ]; then
  ok "watch set expands to $n file(s) — the coverage checks have a population"
else
  bad "watch set expands to 0 files — every coverage number below is vacuous;"
  bad "      this is the exact state T-344 repaired, and it has regressed"
fi

# The product file is the one this arc is about; a watch set that misses it is
# tailored in name only. Named explicitly rather than trusted to a count: 146
# files could be watched with this one absent and leg 1 would still be green.
if python3 "$EXPANDER" "$WATCH" "$REPO" 2>/dev/null | grep -qx "src/aef-workflow-designer.html"; then
  ok "the product file src/aef-workflow-designer.html is in the watch set"
else
  bad "src/aef-workflow-designer.html is NOT watched — the ~10k-line file this arc"
  bad "      is about is absent from its own coverage denominator"
fi

# --- 3-6: would the audit SAY so? ---------------------------------------------
# Extract each verdict branch live and drive it with the empty-denominator input
# and a healthy one. Both arms are required to differ: a branch that emits the
# same verdict either way is the constant-check defect T-345 removed, and
# re-introducing it here would be invisible to a one-armed test.
drive() { # <branch-text> <env assignments...>
  local branch="$1"; shift
  env "$@" bash -c "pass(){ echo \"PASS|\$1\"; }; warn(){ echo \"WARN|\$1\"; }; fail(){ echo \"FAIL|\$1\"; }; pass_over(){ echo \"PASS|\$3\"; }; $branch" 2>&1
}

# T-1221: since AEF T-2735 (vendored with 1.7.68) audit.sh has ONE coverage check, the drift block in
# check_fabric_coverage. Its verdict chain is extracted as block 1, and the empty-watch-set signal that
# follows it as block 2. The anchors before T-1221 (FABRIC_EXPAND_OK, `drift_watched:-0 -eq 0`) named
# the two pre-T-2735 blocks and reported "it moved" from v1.7.68 on, which is the extraction doing its job.
b1=$(awk '/^    if ! \[\[ "\$drift_unreg" =~ \^\[0-9\]\+\$ \]\]; then$/{f=1} f{print} f && /^    fi$/{exit}' "$AUDIT")
if [ -z "$b1" ]; then
  bad "could not extract the 'Fabric:' coverage verdict chain from audit.sh — it moved; re-anchor"
else
  broken=$(drive "$b1" drift_unreg=ERR drift_total=17 drift_watched=0 CONTEXT_DIR=/nonexistent)
  gap=$(drive "$b1" drift_unreg=40 drift_total=17 drift_watched=146 CONTEXT_DIR=/nonexistent)
  full=$(drive "$b1" drift_unreg=0 drift_total=17 drift_watched=146 CONTEXT_DIR=/nonexistent)
  case "$broken" in
    FAIL*UNMEASURED*) ok "block 1: a failed expander raises FAIL naming coverage UNMEASURED" ;;
    *)                bad "block 1: a failed expander emits: $broken" ;;
  esac
  case "$gap" in
    WARN*"40 unregistered (of 146 watched"*) ok "block 1: unregistered files raise WARN with the count and its denominator" ;;
    *)                                        bad "block 1: 40 of 146 unregistered emits: $gap" ;;
  esac
  if [ "$broken" != "$full" ] && [ "$gap" != "$full" ]; then
    ok "block 1: broken, gap and full coverage emit three DIFFERENT verdicts — not constant"
  else
    bad "block 1: verdicts collapse (broken=$broken | gap=$gap | full=$full)"
  fi
fi

b2=$(awk '/^    if \[\[ "\$drift_watched" =~ \^\[0-9\]\+\$ \]\] && \[ "\$drift_watched" -eq 0 \] \\$/{f=1} f{print} f && /^    fi$/{exit}' "$AUDIT")
if [ -z "$b2" ]; then
  bad "could not extract the empty-watch-set branch from audit.sh — it moved; re-anchor"
else
  empty=$(drive "$b2" drift_watched=0 drift_total=17 drift_carded_unwatched=0)
  full=$(drive "$b2" drift_watched=146 drift_total=17 drift_carded_unwatched=0)
  case "$empty" in
    WARN*"matches 0 files"*) ok "block 2: watched=0 with cards present raises WARN naming the empty watch set" ;;
    *)                       bad "block 2: watched=0 emits: $empty" ;;
  esac
  if [ "$empty" != "$full" ]; then
    ok "block 2: watched=0 and watched=146 emit DIFFERENT verdicts — not constant"
  else
    bad "block 2: an empty watch set is indistinguishable from a full one: $empty"
  fi
fi

# --- 7: the two surfaces must agree on the denominator ------------------------
# T-345 was two checks over one question returning different numbers. The fix
# added a second number to both; if THOSE disagree the same defect is back one
# level down. expand_patterns.py is the third consumer and the shared one.
a1=$(cd "$REPO" && PROJECT_ROOT="$REPO" python3 -c "
import yaml, glob, os
root = os.environ['PROJECT_ROOT']
data = yaml.safe_load(open('$WATCH'))
w = set()
for p in data.get('patterns', []) or []:
    g = p.get('glob','') if isinstance(p, dict) else str(p)
    if not g: continue
    for m in glob.glob(os.path.join(root, g), recursive=True):
        if os.path.isfile(m): w.add(os.path.relpath(m, root))
print(len(w))")
if [ "$a1" = "$n" ]; then
  ok "audit's expander and expand_patterns.py agree on the denominator ($n)"
else
  bad "denominators DISAGREE: expand_patterns.py=$n, audit's inline expander=$a1."
  bad "      Most likely cause: an 'exclude:' key in watch-patterns.yaml — honored"
  bad "      by expand_patterns.py, silently ignored by audit.sh (measured 1 vs 50)"
fi

# --- 8: the audit's two coverage checks must agree on the count ---------------
# T-345's subject, re-asserted where it can now actually fail. At T-345's own
# completion both checks returned 0 over an empty watch set and agreed for the
# wrong reason; agreement over an empty population is not evidence. Over this
# watch set the pre-T-345 build returns 0 while the sibling returns 133, so this
# leg has a population that can separate them.
# No literal counts: the numbers move whenever a tool or a card is added, and a
# literal integer in a gate is the moving-global defect wearing prose (G-015).
# T-550: read the audit's OWN FINDINGS, never its summary of past ones.
#
# This leg used to anchor on the bare text `unregistered (of N watched)` anywhere in the
# report, taking the first match. T-525 changed the finding to `(of N watched — P% covered,
# <direction>)`, so that anchor stopped matching the line it was written for — and did not
# go quiet. The report ends with a TREND ANALYSIS section that reprints recurring findings
# from the last 14 days verbatim, in the shape they had when they were recorded, so the first
# match became `Fabric: 40 registered, 185 unregistered (of 222 watched) (7 times)` — a
# fortnight-old aggregate read as today's number and compared against today's drift count.
# Measured: it reported `DISAGREE (185 vs 199)` on a day both checks said 199.
#
# The general shape, worth stating because it is not "the regex went stale": a report that
# summarises its own history contains a copy of every sentence it used to print, so an anchor
# that goes stale REBINDS onto the archive of its own past rather than failing to match. The
# original code guarded the silence case explicitly and could not have guarded this one.
# Note the error is not directionally safe either — it manufactured a false red here, and
# produces a false green on any day the historical aggregate happens to equal today's drift.
#
# So both numbers are now required to come from a SEVERITY-MARKED line, which is what the
# audit prefixes its own findings with and what a trend echo (`  - Fabric: ...`) never has.
# T344_AUDIT_TRANSCRIPT substitutes a recorded report for a live run. It exists so
# tools/_t550-audit-parse-anchor-teeth.py can present transcripts this tree cannot produce on
# demand — a stale-anchor report, a genuine disagreement — without waiting ~17s per audit.
if [ -n "${T344_AUDIT_TRANSCRIPT:-}" ]; then
  audit_out=$(cat "$T344_AUDIT_TRANSCRIPT")
else
  audit_out=$("$REPO/.agentic-framework/bin/fw" audit --section structure 2>&1)
fi
findings=$(printf '%s\n' "$audit_out" | grep -E '^\[(PASS|WARN|FAIL|INFO)\]' || true)
c1=$(printf '%s\n' "$findings" | sed -n 's/^\[[A-Z]*\] Fabric: [0-9]\+ registered, \([0-9]\+\) unregistered (of \([0-9]\+\) watched.*/\1 \2/p' | head -1)
# T-1221: since AEF T-2735 the audit has ONE coverage count, so the second number is no longer the audit's
# old "Fabric drift:" line but an INDEPENDENT count made here: watched files (expand_patterns.py) that no
# card in .fabric/components names as its location. T344_INDEPENDENT ("<unregistered> <watched>") stands in
# for it beside a recorded transcript, so the T-550 teeth can present both sides without this tree.
if [ -n "${T344_INDEPENDENT:-}" ]; then
  ind="$T344_INDEPENDENT"
else
  ind=$(cd "$REPO" && python3 "$EXPANDER" "$WATCH" "$REPO" 2>/dev/null | python3 -c "
import sys, glob, yaml
locs = set()
for p in glob.glob('.fabric/components/*.yaml'):
    try:
        d = yaml.safe_load(open(p))
    except Exception:
        continue
    if isinstance(d, dict) and d.get('location'):
        locs.add(d['location'])
w = [l.strip() for l in sys.stdin if l.strip()]
print(len([f for f in w if f not in locs]), len(w))")
fi
c2=$(echo "$ind" | awk '{print $1}'); d2=$(echo "$ind" | awk '{print $2}')
n1=$(echo "$c1" | awk '{print $1}'); d1=$(echo "$c1" | awk '{print $2}')
if [ -z "$n1" ] || [ -z "$c2" ]; then
  # Full coverage is the one legitimate reason a count is absent, and it too must be read off
  # a severity-marked finding rather than from anywhere in the report.
  if printf '%s\n' "$findings" | grep -qE '^\[[A-Z]*\] Fabric: [0-9]+ registered, 0 unregistered'; then
    ok "both coverage checks report full coverage over a non-empty watch set"
  else
    bad "could not read both coverage counts from the audit's own findings (coverage="
    bad "      ${n1:-none}, drift=${c2:-none}). The anchor has gone stale: re-derive it from"
    bad "      the current verdict text. Do NOT widen the search back to the whole report —"
    bad "      TREND ANALYSIS reprints old findings verbatim, so a widened anchor silently"
    bad "      matches a historical aggregate and reports it as today (T-550)."
  fi
elif [ "$n1" = "$c2" ] && [ "$d1" = "$d2" ] && [ "${d1:-0}" -gt 0 ]; then
  ok "audit and the independent count: coverage checks agree: $n1 unregistered of $d1 watched"
else
  bad "coverage checks DISAGREE (audit $n1 of $d1, independent $c2 of $d2) — the T-345"
  bad "      defect class, visible only over a non-empty watch set."
  bad "      The audit's number was read from a severity-marked finding in this run's own"
  bad "      output, so this is a live disagreement and not a trend echo (T-550)."
fi

echo
echo "  $pass passed, $fail failed"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$fail" -eq 0 ] || exit 1
exit 0
