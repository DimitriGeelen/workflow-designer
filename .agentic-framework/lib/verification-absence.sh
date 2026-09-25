#!/usr/bin/env bash
# T-843 — uncontrolled-absence-assertion predicates for the P-011 close gate.
#
# WHAT AN UNCONTROLLED ABSENCE ASSERTION IS. A verification leg that asserts something is
# NOT present, where nothing establishes the search could have succeeded:
#
#     ! grep -q 'T-843' .context/working/.gate-bypass-log.yaml
#
# Delete or rename that file and the leg passes vacuously and reports a clean result. A
# broken pattern and a satisfied assertion produce the identical green.
#
# WHY THIS IS A GATE AND NOT ONLY A CENSUS. The project-local census that finds these has
# been red since 2026-09-01, and across that window the count it measures rose from 78 to
# 122. It is accurate, it ratchets, and it stopped nothing — because running it is OPT-IN
# (7 task files of 840) so it measures at audit time and never at the moment a leg is
# admitted. Two of the 122 were added by the agent inside the two tasks whose subject was
# that an assertion must be able to fail. Discipline did not substitute for position.
#
# THE CLASSIFIER IS NOT REIMPLEMENTED HERE. These predicates shell to
# tools/_t560-absence-assertion-census.py --block, which reuses the same classify() /
# patterns_in() / control_level() the corpus census uses. L-533: run THIS expression, not a
# re-typed copy. A bash reimplementation would drift, and then the corpus number and the
# close decision would mean different things. Mirroring matters in both directions: only
# control level NONE blocks. EXISTENCE-controlled legs are weakly controlled and the census
# does not count them, so this gate must not either.
#
# PORTABILITY, AND THE HONEST DEGRADATION. This lib is framework-side; the census is
# currently project-local. When the census cannot be found, these predicates report NOTHING
# and _fw_absence_classifier_available returns 1, so the call site prints NOT EVALUATED
# rather than passing (which would claim coverage) or failing (which would block every close
# in every project that does not have the census). That is the same T-3105 distinction the
# gate itself enforces on unreadable legs, applied to the gate's own dependency.

# Resolve the classifier. PROJECT_ROOT first (project-local tool), then the framework tree,
# so an upstreamed copy is found without changing callers.
_fw_absence_classifier() {
    local c
    for c in \
        "${PROJECT_ROOT:-}/tools/_t560-absence-assertion-census.py" \
        "${FRAMEWORK_ROOT:-}/tools/_t560-absence-assertion-census.py" \
        "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)/tools/_t560-absence-assertion-census.py"
    do
        [ -n "$c" ] && [ -f "$c" ] && { printf '%s' "$c"; return 0; }
    done
    return 1
}

# Is the classifier present? Callers MUST check this before treating empty output as clean.
_fw_absence_classifier_available() {
    _fw_absence_classifier >/dev/null 2>&1
}

# Print each leg in "$1" that the census would count as UNCONTROLLED (control level NONE).
# Empty output means clean ONLY IF _fw_absence_classifier_available succeeded.
find_uncontrolled_absence_legs() {
    local script
    script="$(_fw_absence_classifier)" || return 0
    printf '%s\n' "$1" | python3 "$script" --block --uncontrolled 2>/dev/null || true
}

# Print each absence leg whose PATTERN the parser cannot extract. These are NOT EVALUATED:
# never counted as uncontrolled (that would fail a close over a parser limit) and never
# counted as controlled (that would claim coverage). The call site reports them and does
# not block on them.
find_unparseable_absence_legs() {
    local script
    script="$(_fw_absence_classifier)" || return 0
    printf '%s\n' "$1" | python3 "$script" --block --unparseable 2>/dev/null || true
}
