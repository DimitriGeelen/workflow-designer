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
  env "$@" bash -c "pass(){ echo \"PASS|\$1\"; }; warn(){ echo \"WARN|\$1\"; }; fail(){ echo \"FAIL|\$1\"; }; $branch" 2>&1
}

# T-374 moved this branch head: the expander-unavailable arm was inserted ahead of
# the empty-watch-set arm, so the anchor is now FABRIC_EXPAND_OK. This probe caught
# that as "it moved; re-anchor" rather than passing over a branch it could no longer
# find — which is the whole reason the branch is extracted instead of restated.
# FABRIC_EXPAND_OK=1 in both drives keeps the EMPTY-SET arm the one under test;
# without it the new first arm would answer, and this leg would silently change
# subject while still looking green.
b1=$(awk '/^        if \[ "\$\{FABRIC_EXPAND_OK:-1\}" -eq 0 \]; then$/{f=1} f{print} f && /^        fi$/{exit}' "$AUDIT")
if [ -z "$b1" ]; then
  bad "could not extract the 'Fabric:' verdict branch from audit.sh — it moved; re-anchor"
else
  empty=$(drive "$b1" FABRIC_EXPAND_OK=1 fabric_watched=0 fabric_unreg=0 fabric_registered=17)
  full=$(drive "$b1" FABRIC_EXPAND_OK=1 fabric_watched=146 fabric_unreg=0 fabric_registered=17)
  case "$empty" in
    WARN*UNMEASURED*) ok "block 1: watched=0 raises WARN naming coverage UNMEASURED" ;;
    *)                bad "block 1: watched=0 emits: $empty" ;;
  esac
  if [ "$empty" != "$full" ]; then
    ok "block 1: watched=0 and watched=146 emit DIFFERENT verdicts — not constant"
  else
    bad "block 1: an empty watch set is indistinguishable from a full one: $empty"
  fi
fi

b2=$(awk '/^    if \[ "\$\{drift_watched:-0\}" -eq 0 \] 2>\/dev\/null; then$/{f=1} f{print} f && /^    fi$/{exit}' "$AUDIT")
if [ -z "$b2" ]; then
  bad "could not extract the 'Fabric drift:' verdict branch from audit.sh — it moved"
else
  empty=$(drive "$b2" drift_watched=0 drift_unreg=0 drift_total=17)
  full=$(drive "$b2" drift_watched=146 drift_unreg=0 drift_total=17)
  case "$empty" in
    WARN*"nothing was checked"*) ok "block 2: watched=0 raises WARN naming that nothing was checked" ;;
    *)                           bad "block 2: watched=0 emits: $empty" ;;
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
c2=$(printf '%s\n' "$findings" | sed -n 's/^\[[A-Z]*\] Fabric drift: \([0-9]\+\) source file(s) have no fabric card.*/\1/p' | head -1)
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
elif [ "$n1" = "$c2" ] && [ "${d1:-0}" -gt 0 ]; then
  ok "audit's two coverage checks agree: $n1 unregistered of $d1 watched"
else
  bad "the two coverage checks DISAGREE ($n1 vs $c2, denominator $d1) — this is the"
  bad "      T-345 defect, and it is only visible over a non-empty watch set."
  bad "      Both numbers were read from severity-marked findings in this run's own"
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
