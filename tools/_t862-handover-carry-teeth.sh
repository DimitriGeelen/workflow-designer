#!/bin/bash
# T-862 — teeth for Suggested First Action carry-forward (OBS-383).
#
# WHAT IT DEFENDS. handover.sh regenerates the Suggested First Action section on
# every run. Before T-862 it did so unconditionally, so hand-authored content had
# a shelf life of exactly one regeneration — measured four times on 2026-09-25/26,
# cleanest pair cfc7e9ed -> f98bf459: 4,982 chars replaced by 7 lines, one commit
# apart, focus unchanged.
#
# TWO MUTATIONS, NOT ONE, AND THAT IS THE POINT OF THIS FILE.
#
# A single "did the fix do something" mutation is satisfied by an implementation
# that carries EVERYTHING, and carry-everything is worse than the bug it fixes:
# it would present a plan written for a different task as this task's next step,
# with a provenance banner making it look authoritative. The bug loses content;
# over-firing invents guidance. So the suite is split and each half is killed by
# the mutation that the OTHER half survives:
#
#   --mutation            strips carrying    -> CARRY_CASES die, GUARD_CASES live
#   --mutation-overfire   strips the guard   -> GUARD_CASES die, CARRY_CASES live
#
# Each mode's survivors are its control set: if they go red the harness itself is
# broken and every red in that run is false, which is reported as MUTATION SETUP
# BROKEN rather than read as a clean kill. That failure is not hypothetical — it
# is exactly what T-849's first mutation run did (mutant copied to a temp dir,
# could not resolve lib/paths.sh, all 14 cases red, and it looked like a pass).
#
# WHY IT SOURCES A SLICE. handover.sh runs top-to-bottom and commits, audits and
# pushes; it cannot be sourced. The block between the two T-862 markers is
# extracted and sourced instead, so these tests run the REAL functions. If either
# marker moves, extraction yields nothing and the suite exits 4 announcing it can
# no longer reach its subject (PL-332: a probe nothing re-runs starts misinforming;
# a probe that silently stops reaching its subject does so faster).

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/.agentic-framework/agents/handover/handover.sh}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t862.XXXXXX")"
trap 'rm -rf "$WORK"; rm -f "${MUT:-}"' EXIT

PASS=0; FAIL=0
CARRY_CASES="enriched_same_focus_is_carried carry_is_labelled_with_origin carry_label_states_age unmarked_but_names_focus_is_carried stale_carry_banner_is_stripped"
GUARD_CASES="changed_focus_regenerates stub_predecessor_is_not_carried unmarked_not_naming_focus_refuses"
# Controls for BOTH mutations: these assert properties that neither the carrying
# nor the guard can affect, so they are what distinguishes "the mutant is blind"
# from "the mutant is broken".
#
# no_predecessor_falls_back belongs HERE, not with the guards. It was classified
# as a guard case first and the overfire run refused it: with no LATEST.md,
# _sfa_predecessor_file returns early and the focus guard is never consulted, so
# the case cannot die to a guard mutation. The mutation harness caught a
# misclassification in the suite rather than a defect in the subject — which is
# the behaviour a control set exists to produce.
HELPER_CASES="extract_reads_only_its_section focus_marker_always_emitted no_predecessor_falls_back"

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

# ── reach the subject ───────────────────────────────────────────────────────────
SLICE="$WORK/slice.sh"
awk '/^# ── SUGGESTED FIRST ACTION CARRY-FORWARD \(T-862, OBS-383\) ──/{f=1}
     /^# ── end T-862 carry-forward ──/{exit}
     f' "$SUBJECT" > "$SLICE"
if ! grep -q '_sfa_compose()' "$SLICE"; then
    echo "TEETH BROKEN — could not extract the T-862 block from $SUBJECT."
    echo "Either marker was renamed/removed, or the functions moved. This probe"
    echo "can no longer test what it claims to test. Not reporting a pass."
    exit 4
fi

# ── fixtures ────────────────────────────────────────────────────────────────────
HDIR="$WORK/handovers"; mkdir -p "$HDIR" "$WORK/ctx/working"
export CONTEXT_DIR="$WORK/ctx"
export HANDOVER_DIR="$HDIR"
printf 'current_task: T-737\n' > "$WORK/ctx/working/focus.yaml"
# shellcheck disable=SC1090
source "$SLICE"

ENRICHED_MARK='DRAIN PLAN: 55 legs, 48 with witnesses. Do NOT batch these.'

mk_pred() { # $1 = filename, $2 = section body, $3 = optional ISO timestamp
    { printf -- '---\nsession_id: %s\ntimestamp: %s\n---\n\n' "${1%.md}" "${3:-2026-09-26T00:00:00Z}"
      printf '## Where We Are\n\nsomething\n\n'
      printf '## Suggested First Action\n\n%s\n\n' "$2"
      printf '## Files Changed This Session\n\nnone\n'
    } > "$HDIR/$1"
    ln -sfn "$1" "$HDIR/LATEST.md"
}

echo "=== T-862 Suggested-First-Action carry-forward teeth ==="
echo "subject: $SUBJECT"
echo

# ── mutation modes ──────────────────────────────────────────────────────────────
run_mutation() { # $1 = label, $2 = sed/python transform tag, $3 = cases that must die, $4 = cases that must live
    local label="$1" tag="$2" must_die="$3" must_live="$4"
    MUT="$(dirname "$SUBJECT")/.t862-mutated-$$.sh"
    python3 - "$SUBJECT" "$MUT" "$tag" <<'PYEOF'
import re, sys
src, dst, tag = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(src).read()
if tag == "nocarry":
    # Strip carrying: compose degenerates to "emit the generated line".
    m = re.search(r"\n_sfa_compose\(\) \{.*?\n\}\n", t, re.S)
    if not m:
        sys.exit("mutation anchor not found — _sfa_compose was renamed or removed")
    repl = ("\n_sfa_compose() {\n"
            "    printf '<!-- sfa-focus: %s -->\\n' \"${FOCUS_TASK:-none}\"\n"
            "    printf '%s\\n' \"$1\"\n}\n")
    t = t[:m.start()] + repl + t[m.end():]
elif tag == "overfire":
    # Strip the guard only: carry regardless of whose plan it is.
    if "if [ -n \"$origin\" ]; then" not in t:
        sys.exit("mutation anchor not found — the focus guard was restructured")
    t = t.replace(
        "    if _sfa_is_stub \"$body\"; then printf '%s\\n' \"$generated\"; return 0; fi",
        "    :", 1)
    t = re.sub(r"    if \[ -n \"\$origin\" \]; then\n.*?\n    fi\n",
               "    age_note='GUARD STRIPPED'\n", t, count=1, flags=re.S)
else:
    sys.exit("unknown mutation tag")
open(dst, "w").write(t)
PYEOF
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutated copy"; exit 1; }
    bash -n "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    echo "=== T-862 MUTATION RUN ($label) ==="
    local out; out=$(SUBJECT="$MUT" bash "${BASH_SOURCE[0]}" 2>&1)
    printf '%s\n' "$out" | sed 's/^/  | /'
    echo
    local broken="" survivors="" c
    for c in $must_live $HELPER_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" || broken="$broken $c"
    done
    if [ -n "$broken" ]; then
        echo "MUTATION SETUP BROKEN — cases that do NOT depend on this mutation also failed:$broken"
        echo "The mutant is not merely undetecting, it is not working. Every red above is false."
        rm -f "$MUT"; exit 1
    fi
    for c in $must_die; do
        printf '%s' "$out" | grep -q "PASS  $c\$" && survivors="$survivors $c"
    done
    rm -f "$MUT"
    if [ -n "$survivors" ]; then
        echo "MUTATION FAILED — these pass WITHOUT the behaviour they claim to test:$survivors"
        exit 1
    fi
    echo "MUTATION OK ($label) — control cases stayed green, every dependent case went red."
}

if [ "${1:-}" = "--mutation" ]; then
    run_mutation "carrying stripped" nocarry "$CARRY_CASES" "$GUARD_CASES"; exit 0
fi
if [ "${1:-}" = "--mutation-overfire" ]; then
    run_mutation "focus guard stripped" overfire "$GUARD_CASES" "$CARRY_CASES"; exit 0
fi

# ── CARRY CASES ─────────────────────────────────────────────────────────────────
mk_pred "S-2026-0926-0154.md" "<!-- sfa-focus: T-737 -->
$ENRICHED_MARK
Second line of the plan."
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: handover.sh reports 3 urgent observations')"

printf '%s' "$out" | grep -qF -- "$ENRICHED_MARK" \
  && ok enriched_same_focus_is_carried \
  || bad enriched_same_focus_is_carried "authored content was dropped when focus was unchanged — this is OBS-383 itself"

printf '%s' "$out" | grep -q 'Carried forward from .S-2026-0926-0154.' \
  && ok carry_is_labelled_with_origin \
  || bad carry_is_labelled_with_origin "carried silently — a reader cannot tell this from fresh authorship, which is a new false-green"

# Age is the half of provenance that makes staleness judgeable. A banner naming
# only the origin session tells a reader where the text came from, not whether to
# trust it — and a label with no age reads as fresh. Timestamp is deliberately far
# back so the assertion cannot pass by accident on a near-now fixture.
mk_pred "S-2026-0901-1200.md" "<!-- sfa-focus: T-737 -->
$ENRICHED_MARK" "2026-09-01T12:00:00Z"
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: something')"
printf '%s' "$out" | grep -qE 'Carried forward from .*[0-9]+d old' \
  && ok carry_label_states_age \
  || bad carry_label_states_age "banner carries no age: $(printf '%s' "$out" | grep -m1 'Carried forward from')"

# Unmarked predecessor (written before the marker existed) that names the focus task.
mk_pred "S-2026-0925-1441.md" "$ENRICHED_MARK
This plan is about T-737 and its drain."
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: something')"
printf '%s' "$out" | grep -qF -- "$ENRICHED_MARK" \
  && ok unmarked_but_names_focus_is_carried \
  || bad unmarked_but_names_focus_is_carried "a legacy handover naming the current focus was discarded"

# A predecessor that already carries a banner must not stack a second one.
mk_pred "S-2026-0925-1500.md" "<!-- sfa-focus: T-737 -->
<!-- sfa-carry-begin -->
> **Carried forward from \`S-OLD\`** — focus T-737 unchanged.
<!-- sfa-carry-end -->

$ENRICHED_MARK"
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: something')"
if [ "$(printf '%s' "$out" | grep -c 'Carried forward from')" -eq 1 ] \
   && ! printf '%s' "$out" | grep -q 'S-OLD'; then
    ok stale_carry_banner_is_stripped
else
    bad stale_carry_banner_is_stripped "provenance banners stacked: $(printf '%s' "$out" | grep -c 'Carried forward from') present, S-OLD leaked=$(printf '%s' "$out" | grep -c 'S-OLD')"
fi

# ── GUARD CASES — the over-firing defence ───────────────────────────────────────
mk_pred "S-2026-0926-0154.md" "<!-- sfa-focus: T-737 -->
$ENRICHED_MARK"
FOCUS_TASK="T-999"
out="$(_sfa_compose 'Continue T-999: a different task entirely')"
if ! printf '%s' "$out" | grep -qF -- "$ENRICHED_MARK" \
   && printf '%s' "$out" | grep -q 'Continue T-999'; then
    ok changed_focus_regenerates
else
    bad changed_focus_regenerates "a plan written for T-737 was presented as T-999's next step — worse than the bug being fixed"
fi

mk_pred "S-2026-0926-0201.md" "<!-- sfa-focus: T-737 -->
Continue T-737: handover.sh reports 3 urgent observations"
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: handover.sh reports 3 urgent observations')"
if ! printf '%s' "$out" | grep -q 'Carried forward from'; then
    ok stub_predecessor_is_not_carried
else
    bad stub_predecessor_is_not_carried "a generator-grade stub was given a provenance banner it has no claim to"
fi

mk_pred "S-2026-0925-0900.md" "$ENRICHED_MARK
This plan concerns T-101 and nothing else."
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: something')"
if ! printf '%s' "$out" | grep -qF -- "$ENRICHED_MARK"; then
    ok unmarked_not_naming_focus_refuses
else
    bad unmarked_not_naming_focus_refuses "unattributable content was carried onto an unrelated task — unknown provenance must fail closed"
fi

rm -f "$HDIR/LATEST.md"
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: first ever handover')"
printf '%s' "$out" | grep -q 'Continue T-737: first ever handover' \
  && ok no_predecessor_falls_back \
  || bad no_predecessor_falls_back "a missing LATEST.md (first handover in a repo) broke generation instead of falling through"

# ── HELPER CASES — independent of the carry decision, so they are the controls ──
cat > "$WORK/sample.md" <<'SAMPLE'
## Gotchas

not this

## Suggested First Action

the body
second line

## Files Changed This Session

not this either
SAMPLE
got="$(_sfa_extract "$WORK/sample.md")"
if printf '%s' "$got" | grep -q 'the body' \
   && ! printf '%s' "$got" | grep -q 'not this'; then
    ok extract_reads_only_its_section
else
    bad extract_reads_only_its_section "section extraction bled into neighbours: $(printf '%s' "$got" | tr '\n' '/')"
fi

mk_pred "S-2026-0926-0201.md" "Continue T-737: stub"
FOCUS_TASK="T-737"
out="$(_sfa_compose 'Continue T-737: stub')"
printf '%s' "$out" | grep -q '<!-- sfa-focus: T-737 -->' \
  && ok focus_marker_always_emitted \
  || bad focus_marker_always_emitted "no attribution marker written — the next run cannot tell whose plan this was"

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
