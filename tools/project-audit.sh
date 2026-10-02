#!/usr/bin/env bash
# project-audit.sh — 832's OWN audit rails, in a file no re-vendor can touch (T-999, T-995 B3).
#
# WHY THIS FILE EXISTS. These rails lived inside the vendored .agentic-framework/agents/audit/audit.sh.
# Upgrades overwrite that file, and they deleted the rails without a word: T-382 (release lag) and
# T-660 (Human AC actionability) went with the T-840 upgrade on 2026-09-25, the other six with the
# 1.7.740 re-vendor on 2026-10-01. For eight days nothing reported that our own Watchtower served a
# designer two releases old (T-1007) — the release-lag rail that would have said so was gone.
# The divergence register could not see it either: it declares changes per FILE, and audit.sh still
# differed from upstream in other ways, so losing two of its local changes changed nothing it measures.
#
# Upstream audit.sh has no extension point (docs/reports/T-1005-audit-sh-classification.md); the ask
# is with AEF. Until it exists this script runs on its own schedule and writes its own report.
#
# Each rail below is carried over VERBATIM from its last committed form (comments included), so its
# history and reasoning travel with it: the six check_* functions from the pre-1.7.740 audit.sh
# (2659abad^), T-382 from 8d4077fa, T-660 from 73f7c3fd. The only shims are pass/warn/fail.
#
# Usage: bash tools/project-audit.sh [--quiet]
# Writes .context/audits/project/LATEST.yaml (+ a dated copy). Exit 0 all pass, 1 warn, 2 fail.
set -uo pipefail
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FRAMEWORK_ROOT="${FRAMEWORK_ROOT:-$PROJECT_ROOT/.agentic-framework}"
export PROJECT_ROOT FRAMEWORK_ROOT
QUIET=0; [ "${1:-}" = "--quiet" ] && QUIET=1
if [ -t 1 ] && [ $QUIET -eq 0 ]; then RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
else RED=''; YELLOW=''; GREEN=''; NC=''; fi
PASS_COUNT=0; WARN_COUNT=0; FAIL_COUNT=0; FINDINGS=()
_say() { [ $QUIET -eq 1 ] || echo -e "$@"; }
# Same line shapes as audit.sh's pass/warn/fail, so a reader (or a teeth script) sees one format.
pass() { _say "${GREEN}[PASS]${NC} $1"; PASS_COUNT=$((PASS_COUNT + 1)); FINDINGS+=("PASS|$1||"); }
warn() { _say "${YELLOW}[WARN]${NC} $1"; _say "       Evidence: $2"; _say "       Mitigation: $3"
         WARN_COUNT=$((WARN_COUNT + 1)); FINDINGS+=("WARN|$1|$2|$3"); }
fail() { _say "${RED}[FAIL]${NC} $1"; _say "       Evidence: $2"; _say "       Mitigation: $3"
         FAIL_COUNT=$((FAIL_COUNT + 1)); FINDINGS+=("FAIL|$1|$2|$3"); }

_say "=== PROJECT AUDIT (832, tools/project-audit.sh) ==="

# T-382 / G-024 — a consumer-visible fix must not sit unreleased with nothing
# reporting it. The gap is not "src differs from the release" (always true, and the
# G-015 mistake) but AGE: how long the product's oldest unshipped change has waited.
# Runs in `structure` because that is the section the daily/cron path actually
# executes (G-013) — a check placed in a section nobody runs is the gap, not the fix.
check_release_lag() {
    local _probe="$PROJECT_ROOT/tools/_t382-release-lag.py"
    [ -f "$_probe" ] || return 0
    local _out _rc
    _out=$(python3 "$_probe" 2>&1); _rc=$?
    local _l1 _l2
    _l1=$(printf '%s' "$_out" | grep -m1 'oldest unshipped product change' || true)
    _l2=$(printf '%s' "$_out" | grep -m1 'peer pin behind' || true)
    case "$_rc" in
        0) pass "Release lag: src, released artifact and peer pin are in step" ;;
        1) warn "Release lag: ${_l1:-${_l2:-below threshold}}" \
                "A fix a consumer cannot get is not shipped (G-024)" \
                "Cut a release, or record why the delay is intended" ;;
        2) warn "Release lag EXCEEDED: ${_l1:-${_l2:-see probe}}" \
                "G-024: a consumer-visible fix has sat unreleased past the incident threshold" \
                "Run: python3 tools/_t382-release-lag.py" ;;
        3) warn "Release lag UNMEASURED — $(printf '%s' "$_out" | grep -m1 'COULD NOT MEASURE')" \
                "An unmeasured lag is not a clean one (G-024)" \
                "Run: python3 tools/_t382-release-lag.py" ;;
    esac
}
check_release_lag

# T-382 — a gap with no closure condition can never be closed, and a closure
# condition written under a key the renderer ignores is worse: `fw gaps` prints
# "Trigger: " for it, so it reads as decided-to-have-none rather than unrendered.
# G-024 sat that way with 587 characters written. Absence and invisibility must not
# share one appearance.
check_gap_triggers() {
    local _f="$PROJECT_ROOT/.context/project/concerns.yaml"
    [ -f "$_f" ] || return 0
    local _out
    _out=$(python3 - "$_f" <<'PY' 2>/dev/null
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
gaps = d.get('concerns', d.get('gaps', [])) or []
watching = [g for g in gaps if g.get('status') == 'watching']
# The renderer (bin/fw, `fw gaps`) reads decision_trigger and nothing else.
RENDERED = 'decision_trigger'
missing, unread = [], []
for g in watching:
    if (g.get(RENDERED) or '').strip():
        continue
    alt = [k for k in g if k != RENDERED and 'trigger' in k and (g.get(k) or '').strip()]
    (unread if alt else missing).append('%s%s' % (g.get('id'), '(%s)' % ','.join(alt) if alt else ''))
print('%d|%d|%s|%s' % (len(missing), len(unread), ' '.join(missing), ' '.join(unread)))
PY
) || return 0
    local _nm _nu _m _u
    IFS='|' read -r _nm _nu _m _u <<< "$_out"
    if [ "${_nu:-0}" -gt 0 ]; then
        warn "Gap closure condition written under an UNREAD key: $_u" \
             "\`fw gaps\` renders only 'decision_trigger' — these print as empty" \
             "Rename the key to decision_trigger so the register shows it"
    fi
    if [ "${_nm:-0}" -gt 0 ]; then
        warn "Watching gap(s) with no closure condition: $_m" \
             "A gap that cannot be closed is permanent furniture (T-382)" \
             "Add decision_trigger: to each, or downgrade/close the gap"
    fi
    if [ "${_nm:-0}" -eq 0 ] && [ "${_nu:-0}" -eq 0 ]; then
        pass "Gap register: every watching gap has a renderable closure condition"
    fi
}
check_gap_triggers

# T-660: is the operator's queue actionable, not merely present?
#
# P-010 gates on Agent ACs, P-011 runs Verification, and the ### Human section is explicitly
# non-blocking — so the one class of criterion a PERSON must act on had no instrument at all.
# 010-termlink put it exactly at rail @891: gate-green and operator-actionable are separate
# properties, and only the first was measured. Measured here 2026-08-31: 13 of 51 live-queue
# tasks could not be acted on as written, nine of them unruled inceptions whose first step
# read `Run: fw task review T-XXX` — the literal placeholder.
#
# WARN, not FAIL: an unactionable AC costs the operator a sitting, it does not corrupt
# anything, and a structure FAIL blocks push. Same reasoning as the T-657 line above.
_ha_tool="$PROJECT_ROOT/tools/_t660-human-ac-actionability.py"
if [ -f "$_ha_tool" ]; then
    _ha_out=$(cd "$PROJECT_ROOT" && PROJECT_ROOT="$PROJECT_ROOT" python3 "$_ha_tool" 2>&1)
    if [ $? -ne 0 ]; then
        _ha_n=$(printf '%s\n' "$_ha_out" | grep -c 'NOT ACTIONABLE' || true)
        warn "Human AC actionability: $_ha_n live-queue task(s) ask for something that cannot be executed as written (T-660)" \
             "$(printf '%s\n' "$_ha_out" | grep -A1 'NOT ACTIONABLE' | head -5)" \
             "An AC the operator must decode before running is a deferred sitting, not a pending decision. Detail: python3 tools/_t660-human-ac-actionability.py"
    else
        pass "Human AC actionability: every unticked Human AC in the live queue is executable as written"
    fi
fi

# T-931 — stale ownership. The half check_delegation_surface above CANNOT see.
#
# That rail measures OPEN Human criteria and buckets them. A task whose criteria are all ticked —
# or which never had a Human criterion at all — contributes nothing to it, because there is nothing
# open to classify. So a task can be 100% blocked on `owner: human` and the delegation surface
# reports a clean PASS over it. That is not a flaw in that rail; it answers a different question.
# Nobody was asking this one.
#
# Measured on 832 the day this was written: 112 active tasks carried `owner: human` and 45 of them
# had no open Human criterion behind the field. Ten had every Human criterion TICKED — the operator
# had already exercised the judgement and the task stayed shut anyway. Thirteen had every Agent
# criterion ticked too, and ten of those thirteen had been reported by CTL-029 as "completable, not
# closed" for a month. CTL-029 reads checkboxes; it cannot say why a completable task will not
# close, because the cause is a frontmatter field no check read.
#
# Operator ruling 2026-09-29: `owner: human` is a sovereignty claim only while a Human criterion is
# actually open. This rail is the DETECTOR half of that ruling and runs on cron. The CORRECTOR
# (tools/_t931-ownership-sweep.sh) is attended and must never run unattended — a wrong predicate
# sweeping the corpus would strip real claims with nobody watching. A detector can only over-report.
check_stale_ownership() {
    [ -d "$PROJECT_ROOT/.tasks/active" ] || return 0
    local _tool="$PROJECT_ROOT/tools/_t931-ownership.py"
    if [ ! -f "$_tool" ]; then
        return 0   # predicate not vendored here; silent rather than noisy on other projects
    fi

    # The facts line comes from the tool, exactly as check_delegation_surface above takes its own
    # from `lib.delegation_cli surface --facts`. An earlier draft inlined the python as a heredoc
    # inside this command substitution: `bash -n` passed the whole file and it blew up at run time
    # with "syntax error near unexpected token `||`", because a substitution body is parsed lazily.
    # A lint that goes green on broken code is the same false green this rail exists to remove.
    local _facts
    _facts=$(cd "$PROJECT_ROOT" && python3 "$_tool" --facts 2>/dev/null || true)

    # T-3105: an unreadable or empty result must NOT render as a clean bill of health. "no stale
    # ownership" and "the predicate never ran" are different facts that look identical in a PASS.
    if [ -z "$_facts" ]; then
        warn "Stale task ownership — NOT EVALUATED: the ownership predicate produced no result" \
             "The check ran and measured nothing. A PASS here would assert coverage it does not have (T-3105)." \
             "Run by hand: cd $PROJECT_ROOT && python3 tools/_t931-ownership.py | tail -2"
        return 0
    fi

    local _scanned _human _stale _ready _names
    IFS=$'\t' read -r _scanned _human _stale _ready _names <<< "$_facts"

    if [ "${_scanned:-0}" -eq 0 ]; then
        warn "Stale task ownership — NOT EVALUATED: candidate set empty (0 active task file(s))" \
             "The scan walked no tasks, so the T-931 rail asserted nothing this run" \
             "Confirm .tasks/active is really empty and not a mis-scoped glob"
        return 0
    fi

    if [ "${_stale:-0}" -gt 0 ]; then
        warn "Stale task ownership: $_stale of $_human human-owned task(s) have no open Human criterion" \
             "owner: human is a sovereignty claim only while a Human criterion is open (T-931). ${_ready} of these also have every Agent criterion ticked — those are blocked on a signature with nothing to sign. First few: $_names" \
             "Review: cd $PROJECT_ROOT && bash tools/_t931-ownership-sweep.sh   (dry run; add --apply to correct)"
    else
        pass "Task ownership: all $_human human-owned task(s) have an open Human criterion behind the field — examined $_scanned active task file(s)"
    fi
}
check_stale_ownership

# T-936 (OBS-448) — accidental screen captures written into the tree.
#
# FOUR TIMES IN SEVEN DAYS. A `python3 - <<'PY'` heredoc body, or a broken multi-line `python3 -c "`,
# leaks to the shell and its first line — `import yaml,glob,sys`, `import importlib.util`, `import
# re,io` — resolves not to Python but to ImageMagick's import(1), which CAPTURES THE SCREEN and writes
# PostScript named after the following token. Exit 0, no error, the expected output still appears. 37MB
# sat at the repository root for six days. The fourth was created by the agent itself while writing the
# observation about the other three, and this check found it ninety minutes later on its first run.
#
# T-391 swept this class on 2026-08-08 and closed. That was mitigation; four recurrences say prevention
# never existed (G-019). Prevention is the operator's — removing import(1) from PATH, or enabling the
# PreToolUse gate this task authored. DETECTION is what belongs here, and six days of invisibility is
# the part that actually cost something.
#
# The rail never opens the raster. These are images of the operator's screen; the tool reads a capped
# PostScript header and reports size and canvas so exposure can be judged without anyone paging through
# a desktop. Cron runs this; nothing here deletes anything.
check_stray_captures() {
    local _tool="$PROJECT_ROOT/tools/_t936-stray-capture-scan.py"
    [ -f "$_tool" ] || return 0     # not vendored here; silent rather than noisy elsewhere

    local _facts
    _facts=$(cd "$PROJECT_ROOT" && python3 "$_tool" --facts 2>/dev/null || true)
    if [ -z "$_facts" ]; then
        warn "Stray screen captures — NOT EVALUATED: the capture scan produced no result" \
             "The check ran and measured nothing. A PASS here would assert coverage it does not have (T-3105)." \
             "Run by hand: cd $PROJECT_ROOT && python3 tools/_t936-stray-capture-scan.py"
        return 0
    fi

    local _n _bytes _canvas _paths
    IFS=$'\t' read -r _n _bytes _canvas _paths <<< "$_facts"

    if [ "${_n:-0}" -gt 0 ]; then
        warn "Stray screen capture(s) in the tree: $_n, $(( _bytes / 1048576 ))MB, largest canvas $_canvas" \
             "ImageMagick import(1) ran instead of python — a heredoc or quoted -c block leaked to the shell (OBS-448). These are images of the operator's SCREEN: $_paths" \
             "Look at them or delete them — that is the operator's call, not the agent's. Prevention: enable the bare-import gate (see T-936) or remove import(1) from PATH"
    else
        pass "No stray screen captures — scanned the repository root and working directories by PostScript header, not by filename (all four known cases had none)"
    fi
}
check_stray_captures

# T-941 — the arc-2 boundary inventory, on a schedule instead of on a hope.
#
# The tool itself was never the problem. It derives the route set from gallery-serve.py's own
# dispatch by AST and refuses to let a route inherit a neighbour's fence, so it flagged
# GET /api/instances as UNCLASSIFIED from the day T-884 shipped it and exited non-zero every
# single time. Nothing ran it. Its only caller was T-681's P-011 verification block, and T-681
# sat with all its Agent ACs ticked and unclosed for three weeks — so the finding inherited that
# task's closure rate, which was zero. The identical omission also left the route out of
# tests/test_designer_render.py's CONSOLE_WHITELIST, and that copy was read in three weeks only
# because a release walked into it (PL-363).
#
# WARN, not FAIL, and the choice is deliberate: an unclassified route is an unreviewed fence,
# not a live breach — unlike the tracked-secret rail below, which FAILs. The cost of that choice
# is real, because a warning in an eleven-warning report is exactly how the last one went unread,
# so the mitigation line carries the one command that fixes it rather than advice to go looking.
check_boundary_inventory() {
    local _tool="$PROJECT_ROOT/tools/_t682-boundary-inventory.py"
    [ -f "$_tool" ] || return 0     # not this project; silent rather than noisy elsewhere
    [ -f "$PROJECT_ROOT/tools/gallery-serve.py" ] || return 0

    local _out _rc
    _out=$(cd "$PROJECT_ROOT" && python3 "$_tool" 2>&1); _rc=$?

    if [ "$_rc" -eq 0 ]; then
        # Report what it measured, not just that it ran — "OK" with no denominator is the
        # empty-candidate-set failure this file warns about everywhere else (T-3105).
        pass "Boundary inventory: $(printf '%s' "$_out" | head -1)"
    else
        warn "Boundary inventory drift: a designer route is unfenced or unclassified" \
             "$(printf '%s' "$_out" | grep -E 'IN SERVER|IN INVENTORY|UNCLASSIFIED' | tr '\n' ';' | sed 's/;$//')" \
             "Add its ROUTE_SEMANTICS row (verify what it MUTATES against the call graph, not the HTTP verb), then: cd $PROJECT_ROOT && python3 tools/_t682-boundary-inventory.py --write"
    fi
}
check_boundary_inventory

# T-945 — RESTORES the delivery surface the 1.7.68 re-vendor deleted on 2026-09-25
# (7b5e227e), which is the reason four reverted local fixes went unseen for five days.
#
# WHY THIS IS AN AUDIT LINE AND NOT A BETTER CHECK — carried forward from the original
# T-657 region, because it is still the correct reasoning. tools/_t517-vendor-divergence.py
# was already correct. It had been found red after a long unread stretch TWICE before this,
# and was right both times. Its only host was a ~13-minute bridge suite that nothing runs on
# a schedule, so its verdict reached no one. Detection was never the variable; delivery was.
# The 13 minutes was never THIS check's cost: measured standalone, 270-340ms.
#
# WHAT IS NEW, AND WHY RESTORING IT VERBATIM WOULD HAVE FAILED. The original counted
# UNRECORDED|STALE|RECLASSIFIED into ONE number. Today that number is 1362, and the eleven
# that matter would be invisible inside it:
#     STALE        11   a declared local fix now matches baseline — LOST or adopted
#     RECLASSIFIED  2   declared under the wrong mode
#     UNRECORDED 1349   never declared — bookkeeping debt from the re-vendor itself
# Those are different questions. One asks whether our work was destroyed; the other asks
# whether the manifest is current. Merged, the first hides behind the second, and a warning
# reading "1362" is exactly the decay every other rail in this file guards against. So they
# are two lines, and the stale line NAMES THE FILES — fabric.py and extract-decisions.py are
# how this was found, and a bare count would not have led anyone to them.
#
# WARN, NOT FAIL, deliberately: a structure FAIL blocks push and its only bypass is Tier-0
# gated. The original's revisit trigger is carried forward and the counter now reads three —
# "if an unrecorded entry survives three consecutive audits, WARN has failed the same way the
# bridge suite did and this should become FAIL."
#
# AND THIS RAIL WILL ITSELF BE REVERTED. audit.sh carries 17 local commits and is the
# most-overwritten file in this tree. The durable fix is upstream adoption, asked for at
# framework:pickup @249. This is the stopgap that makes the next loss visible in <=15 minutes
# instead of five days.
check_vendor_divergence() {
    local _tool="$PROJECT_ROOT/tools/_t517-vendor-divergence.py"
    [ -f "$_tool" ] || return 0                       # inert where it is not vendored
    [ "$PROJECT_ROOT" != "${FRAMEWORK_ROOT:-}" ] || return 0   # the framework does not vendor itself

    local _out _rc
    _out=$(cd "$PROJECT_ROOT" && python3 "$_tool" 2>&1); _rc=$?

    if [ "$_rc" -eq 0 ]; then
        local _dec
        _dec=$(printf '%s\n' "$_out" | grep -oE 'declared[ :]+[0-9]+' | grep -oE '[0-9]+' | head -1)
        pass "Vendor divergence: all ${_dec:-0} diverged path(s) declared"
        return 0
    fi

    # Parse the summary line rather than grep-counting rows: "FAIL — N unrecorded, M stale, K reclassified"
    local _sum _stale _recl _unrec
    _sum=$(printf '%s\n' "$_out" | grep -m1 -E '^FAIL' || true)
    _stale=$(printf '%s' "$_sum" | grep -oE '[0-9]+ stale'        | grep -oE '^[0-9]+' || echo 0)
    _recl=$(printf  '%s' "$_sum" | grep -oE '[0-9]+ reclassified' | grep -oE '^[0-9]+' || echo 0)
    _unrec=$(printf '%s' "$_sum" | grep -oE '[0-9]+ unrecorded'   | grep -oE '^[0-9]+' || echo 0)

    if [ "${_stale:-0}" -eq 0 ] && [ "${_recl:-0}" -eq 0 ] && [ "${_unrec:-0}" -eq 0 ]; then
        warn "Vendor divergence: the check failed but reported no counts — NOT EVALUATED" \
             "$(printf '%s\n' "$_out" | tail -3)" \
             "Run by hand: cd $PROJECT_ROOT && python3 tools/_t517-vendor-divergence.py"
        return 0
    fi

    # LINE 1 — the revert signal. This is the one that means our work may be gone.
    if [ "${_stale:-0}" -gt 0 ] || [ "${_recl:-0}" -gt 0 ]; then
        # ${_recl:+...} suppresses on EMPTY, not on zero — and _recl is the string "0",
        # which is non-empty. Test the number.
        local _recl_txt=""
        [ "${_recl:-0}" -gt 0 ] && _recl_txt="; $_recl reclassified"
        warn "Vendor divergence: $_stale declared local fix(es) NO LONGER DIVERGE — adopted upstream, or LOST to a re-vendor$_recl_txt" \
             "$(printf '%s\n' "$_out" | grep -A1 -E 'STALE|RECLASSIFIED' | grep -oE '\.agentic-framework/[^ ]+' | sed 's/:$//' | sort -u | head -12 | tr '\n' ' ')" \
             "Resolve each at its own guard: guard still passes => upstream adopted it; guard fails => the fix was LOST and must be restored (T-945, method in docs/reports/T-944-bridge-suite-triage.md)"
    fi

    # LINE 2 — bookkeeping. Real, but it is debt, not destruction. Kept separate on purpose.
    if [ "${_unrec:-0}" -gt 0 ]; then
        # Evidence is the TOOL'S OWN BYTES, not a sentence of ours. A rail that renders a
        # hardcoded message could be reporting anything, including a stale belief about what
        # the tool found — and the operator would have no way to tell from the audit alone.
        warn "Vendor divergence: $_unrec undeclared vendored path(s) differ from baseline (T-945, orig T-657)" \
             "$(printf '%s\n' "$_out" | grep -E 'UNRECORDED' | head -4 | sed 's/^[[:space:]]*//' | tr '\n' ' ')[manifest behind the tree — largely the 1.7.68 re-vendor's own 1407 changed files, T-944]" \
             "A local fix recorded nowhere is destroyed by the next re-vendor without trace. Declare each with an upstream: lane: python3 tools/_t517-vendor-divergence.py"
    fi
}
check_vendor_divergence

# T-952 — the bridge suite's redness and staleness must reach a reader.
#
# tools/_t813-suite-age.py has run daily since T-917 and is correct. Its verdict goes to
# `logger -t agentic-cron` and NOWHERE ELSE: `grep -c '_t813\|run-history'` on this file was
# 0 before this rail. So the framework has known, every day, how red and how stale the
# gating suite is, and told no surface anyone reads. That is the identical shape to _t517
# before T-945 — a correct detector with no delivery surface — and it is why this rail
# exists rather than another detector.
#
# DELIBERATELY NOT a scheduled run of the suite itself. T-917 measured that and refused:
# ~650-1045s, a browser per CDP probe, SIGTERMed near 600s, and it has twice exited 0 while
# reporting 9 failures (OBS-430). The rc=143 rows sitting in tests/.run-history.tsv are that
# prediction already come true. Scheduling it would manufacture a permanently-red rail or a
# false green; this reads what the monitor already knows, in milliseconds.
#
# AND THIS RAIL WILL BE REVERTED. audit.sh carries 17 local commits and is the
# most-overwritten file in this tree (T-945 says the same thing a few lines up). Stopgap;
# the durable fix is upstream adoption.
check_bridge_suite_ratchet() {
    local _tool="$PROJECT_ROOT/tools/_t952-bridge-suite-ratchet.py"
    [ -f "$_tool" ] || return 0                       # inert where it is not vendored
    [ -f "$PROJECT_ROOT/tests/.run-history.tsv" ] || {
        warn "Bridge suite: NOT EVALUATED — no run history exists" \
             "tests/.run-history.tsv is absent, so nobody has run the suite since recording began (the T-813 F-03 condition)" \
             "This is NOT zero failures. Run once by hand: cd $PROJECT_ROOT && bash tests/run-bridge-tests.sh"
        return 0
    }

    local _out _rc
    _out=$(cd "$PROJECT_ROOT" && python3 "$_tool" 2>&1); _rc=$?

    # Evidence is the TOOL'S OWN BYTES. A rail rendering a fixed sentence could be
    # reporting anything, including a stale belief about what the tool found (T-945).
    local _latest _floor _age
    _latest=$(printf '%s\n' "$_out" | grep -m1 'latest complete' | sed 's/^[^:]*: *//')
    _floor=$(printf  '%s\n' "$_out" | grep -m1 'baseline floor'  | sed 's/^[^:]*: *//')
    _age=$(printf    '%s\n' "$_out" | grep -m1 -oE '\([0-9]+d [0-9]+h old\)')

    if [ "$_rc" -eq 0 ]; then
        pass "Bridge suite: failure floor held — ${_latest:-unknown} ${_age:-}"
        return 0
    fi

    warn "Bridge suite: $(printf '%s\n' "$_out" | grep -m1 -E '^FAIL' | sed 's/^FAIL: *//' | cut -c1-140)" \
         "floor ${_floor:-unknown}; latest ${_latest:-unknown} ${_age:-}" \
         "Run by hand: cd $PROJECT_ROOT && python3 tools/_t952-bridge-suite-ratchet.py (a RISE means something that passed now fails; STALE means the suite has not been run, and a floor is not held by a measurement nobody took)"
}
check_bridge_suite_ratchet

# T-938 — a secret-bearing path that git can see. THIS FAILS, it does not WARN.
#
# SECOND INSTANCE OF THE SAME CLASS IN THIS PROJECT. T-410: Watchtower's session signing key
# (.fw-secret-key) was tracked from 2b9c8ffa for TWO MONTHS, pushed to origin and mirrored to GitHub.
# T-938: Watchtower's API-key store (.context/secrets/api-keys.enc, written by web/secrets_store.py)
# was tracked, committed 973813ea, pushed to origin/bleeding-edge, three days before anyone looked.
# Same component, same project, three months apart. T-410 fixed one path and not the mechanism that
# writes secrets into a repository nobody ignored, and the second instance is the receipt (G-019).
#
# WHY FAIL AND NOT WARN, which is the only interesting decision here. This report currently carries
# ten warnings. A committed credential added as an eleventh is a line the operator has been trained to
# scroll past — that is precisely how the last one survived three days and the one before it two
# months. The severity has to match the consequence: a push makes the exposure irreversible, and
# `fw handover` pushes. Everything else in this file can wait for a triage pass; this cannot.
#
# It never reads a secret. Tracked-ness and ignored-ness are git metadata; the file's contents are
# never opened, and for this task the operator ruled against rotation, which makes the file's
# continued confidentiality the entire mitigation.
check_secret_paths_visible_to_git() {
    command -v git >/dev/null 2>&1 || return 0
    (cd "$PROJECT_ROOT" && git rev-parse --git-dir >/dev/null 2>&1) || return 0

    # ONE ENCODING OF "IS THIS NAME KEY MATERIAL". tools/tracked-secret-artifacts.py already owns that
    # judgement — DEFINITIVE suffixes and names, dotenv, and the secrecy-word x credential-noun pair
    # at disjoint spans — with an allowlist and a census mode. An earlier draft of this rail carried
    # its own five-pattern list, which would have drifted from the tool within a week; the delegation
    # boundary in this same corpus is encoded twice and was measured disagreeing (G-052). So the rail
    # CALLS the tool for the tracked question and adds only the axis the tool does not have.
    #
    # WHY THE RAIL EXISTS AT ALL IF THE TOOL DOES THE JUDGING: the tool was written in August (T-410)
    # and NOTHING EVER RAN IT. Not the audit, not a hook, not cron. `.context/secrets/api-keys.enc`
    # was tracked and public for three days while a scanner built to prevent exactly that sat on disk
    # uninvoked — and its rule would have missed the file anyway (basename-only, singular nouns; both
    # fixed under T-938). An instrument nobody calls is not a control.
    local _tracked="" _unignored="" _f
    local _tool="$PROJECT_ROOT/tools/tracked-secret-artifacts.py"
    if [ -f "$_tool" ] && command -v python3 >/dev/null 2>&1; then
        if ! _tracked="$(cd "$PROJECT_ROOT" && python3 "$_tool" 2>&1)"; then
            # Non-zero exit means it found tracked key material. Its own report names the files.
            _tracked="$(printf '%s' "$_tracked" | grep -vE '^tracked-secret scan ok' | head -6 | tr '\n' ' ')"
        else
            _tracked=""
        fi
    fi

    # THE AXIS THE TOOL DOES NOT HAVE: present on disk but not ignored. Not yet leaked, but one broad
    # `git add` from it — and `fw handover` stages .context/. This is the near-miss state, so it warns
    # rather than fails.
    local _pats=(".context/secrets" "api-keys.enc" ".fw-secret-key" ".litellm" "credentials.json")
    local _p
    for _p in "${_pats[@]}"; do
        while IFS= read -r _f; do
            [ -n "$_f" ] || continue
            (cd "$PROJECT_ROOT" && git check-ignore -q "$_f" 2>/dev/null) || _unignored="$_unignored $_f"
        done < <(cd "$PROJECT_ROOT" && find . -path ./.git -prune -o -name "*${_p}*" -print 2>/dev/null | head -5)
    done

    _unignored="$(printf '%s' "$_unignored" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')"

    # T-939 — THE HISTORY AXIS, and it WARNS rather than FAILS. Deliberate asymmetry.
    #
    # `--history` judges every path ever present in reachable history: the set a clone actually
    # receives. The index cannot answer that, and the gap is not theoretical — it is how T-938's purge
    # looked complete the moment `git rm --cached` ran, while 109 commits still carried the blob. It is
    # also the resurrection case: a stale clone that pulls and pushes makes old commits reachable again
    # while the tip keeps the deletion, so the index stays green and every clone has the secret back.
    #
    # WHY WARN AND NOT FAIL, when the index case fails. A secret in history whose value has been
    # rotated is not a live exposure: `.fw-secret-key` sits in this repo's history from T-410 and the
    # key it signs with was replaced, so the committed one signs nothing. Failing on it would make the
    # audit permanently red until someone rewrites 2400 commits on master — a remedy the operator has
    # already weighed and declined once. A red that cannot be cleared is a red people learn to bypass,
    # which is how the index finding would have been missed too. Live exposure fails; historical
    # residue warns and names rotation as the remedy that actually closes it.
    local _hist=""
    if [ -f "$_tool" ] && command -v python3 >/dev/null 2>&1; then
        if ! _hist="$(cd "$PROJECT_ROOT" && timeout 300 python3 "$_tool" --history 2>&1)"; then
            _hist="$(printf '%s' "$_hist" | grep -E '^\s+\[' | head -4 | tr -s ' ' | tr '\n' ' ')"
        else
            _hist=""
        fi
    fi

    if [ -n "$_tracked" ]; then
        fail "SECRET TRACKED BY GIT: $_tracked" \
             "In the index, therefore in history and probably already pushed. Encrypted is not safe when the key derives from /etc/machine-id (world-readable): the encryption protects the file only while it stays on this machine, and makes it LOOK safe to commit. Second instance of this class here — T-410 was the session signing key, two months, mirrored to GitHub." \
             "git rm --cached the path, add a PATTERN (not a path) to .gitignore, then decide about history — a rewrite plus force-push is Tier 0 and the operator's. Rotate unless the operator rules otherwise."
    elif [ -n "$_hist" ]; then
        warn "Secret in reachable git HISTORY (not the index): $_hist" \
             "Nothing is tracked now, but every clone of this repository still receives it. The index cannot see this — it is how T-938's purge read as complete while 109 commits still carried the blob, and it is how a stale clone that pulls-and-pushes silently restores one." \
             "ROTATE the value; that is what makes the historical copy harmless. A git filter-repo rewrite plus force-push is defence-in-depth AFTER rotation and is Tier 0 — the operator's call, never the agent's."
    elif [ -n "$_unignored" ]; then
        warn "Secret-bearing path on disk but NOT gitignored: $_unignored" \
             "Not yet tracked, so nothing has leaked — but one broad 'git add' makes it the case above, and handover commits stage .context/" \
             "Add a pattern covering it to .gitignore, then verify with: git check-ignore -v <path>"
    else
        pass "No secret-bearing path is tracked or unignored — tracked-ness judged by tools/tracked-secret-artifacts.py over the whole index, ignored-ness over ${#_pats[@]} on-disk pattern(s)"
    fi
}
check_secret_paths_visible_to_git

# ── report ─────────────────────────────────────────────────────────────────────────────────
OUT_DIR="$PROJECT_ROOT/.context/audits/project"; mkdir -p "$OUT_DIR"
printf '%s\n' "${FINDINGS[@]}" | PASS_COUNT=$PASS_COUNT WARN_COUNT=$WARN_COUNT FAIL_COUNT=$FAIL_COUNT \
  OUT="$OUT_DIR/LATEST.yaml" python3 -c '
import os, sys, yaml, datetime
rows = []
for line in sys.stdin.read().splitlines():
    if not line:
        continue
    lvl, title, ev, mit = (line.split("|", 3) + ["", "", ""])[:4]
    rows.append({"level": lvl, "check": title, "evidence": ev, "mitigation": mit})
doc = {"generated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
       "source": "tools/project-audit.sh (T-999)",
       "summary": {k: int(os.environ[k.upper() + "_COUNT"]) for k in ("pass", "warn", "fail")},
       "findings": rows}
yaml.safe_dump(doc, open(os.environ["OUT"], "w"), sort_keys=False, allow_unicode=True, width=120)'
cp "$OUT_DIR/LATEST.yaml" "$OUT_DIR/$(date +%Y-%m-%d).yaml"
_say ""; _say "=== SUMMARY === Pass: $PASS_COUNT  Warn: $WARN_COUNT  Fail: $FAIL_COUNT  -> $OUT_DIR/LATEST.yaml"
[ $FAIL_COUNT -gt 0 ] && exit 2
[ $WARN_COUNT -gt 0 ] && exit 1
exit 0
