#!/bin/bash
# Fabric Agent - drift detection commands
# Implements: fw fabric drift, fw fabric validate

do_drift() {
    ensure_fabric_dirs

    local watch_file="$FABRIC_DIR/watch-patterns.yaml"
    local summary_flag="${1:-}"

    echo -e "${BOLD}Fabric Drift Report${NC}"
    echo ""

    # 1. Check for unregistered files
    local unregistered=0
    local orphaned=0
    local stale=0

    if [ -f "$watch_file" ]; then
        # T-1842: delegate pattern expansion to expand_patterns.py — single
        # source of truth for glob + exclude. Was previously a parallel copy
        # of do_scan's reader and dropped exclude: identically (Penelope
        # T-1458, 22-day undetected silent-junk class).
        local registered
        registered=$(grep "^location:" "$COMPONENTS_DIR"/*.yaml 2>/dev/null | sed 's/.*location: //' | sort -u)

        echo -e "${CYAN}Unregistered components:${NC}"
        while IFS= read -r rel_path; do
            [ -z "$rel_path" ] && continue
            # T-2518: was `echo "$registered" | grep -qx "$rel_path"`. Under the
            # inherited `set -euo pipefail`, when grep -q short-circuits on an
            # early match it closes the pipe and `echo` takes SIGPIPE (141);
            # pipefail then makes the pipeline exit 141, so `! 141` → true and a
            # genuinely-registered file is falsely flagged. The race is timing-
            # dependent (files whose location sorts early are hit more often),
            # which is why drift reported a different random subset of carded
            # files each run (OBS-092). Herestring has no producer process to
            # receive SIGPIPE; -F makes the path a fixed string (dots in paths
            # are no longer regex). Same L-387/L-402 class.
            if ! grep -qxF "$rel_path" <<<"$registered" 2>/dev/null; then
                echo "  ! $rel_path"
                unregistered=$((unregistered + 1))
            fi
        done < <(python3 "$LIB_DIR/expand_patterns.py" "$watch_file" "$PROJECT_ROOT" 2>/dev/null)
        [ "$unregistered" -eq 0 ] && echo "  (none)"
    fi

    echo ""

    # 2. Check for orphaned cards (file referenced doesn't exist)
    echo -e "${CYAN}Orphaned cards:${NC}"
    for card in "$COMPONENTS_DIR"/*.yaml; do
        [ -f "$card" ] || continue
        local loc
        loc=$({ grep "^location:" "$card" 2>/dev/null || true; } | head -1 | sed 's/^location: //')
        # T-1673: handle absolute paths (cross-repo cards from T-1652) — don't
        # join with PROJECT_ROOT when the location is already absolute.
        local resolved
        if [ -n "$loc" ] && [ "${loc:0:1}" = "/" ]; then
            resolved="$loc"
        else
            resolved="$PROJECT_ROOT/$loc"
        fi
        if [ -n "$loc" ] && [ ! -f "$resolved" ]; then
            # T-2519: a missing location that is gitignored is a runtime/generated
            # data artifact (e.g. F-004 budget-gate-counter → .budget-gate-counter,
            # created lazily by the budget-gate hook, gitignored, absent between
            # sessions / after a .context/working/ clean). Its transient absence is
            # expected state, not real drift — the same class the stale-edges check
            # already exempts (T-2427/G-070, section 3). A genuinely-deleted
            # *tracked* source file is NOT gitignored, so it still flags. git
            # check-ignore only runs on the rare missing-file branch → no scan
            # slowdown. Exit codes: 0 = ignored (skip), 1 = not ignored (flag),
            # 128 = no git repo / path outside repo (treated as not-ignored →
            # flag, preserving pre-fix behavior — no regression).
            if git -C "$PROJECT_ROOT" check-ignore --quiet -- "$loc" 2>/dev/null; then
                continue
            fi
            local name
            name=$({ grep "^name:" "$card" 2>/dev/null || true; } | head -1 | sed 's/^name: //')
            echo "  ! $name → $loc (file missing)"
            orphaned=$((orphaned + 1))
        fi
    done
    [ "$orphaned" -eq 0 ] && echo "  (none)"

    echo ""

    # 3. Check for stale edges (depends_on targets that don't resolve)
    # T-1674: single python3 pass instead of 2 spawns × N cards (was ~11min on
    # 508 cards). Stdout = unresolved lines for the operator. The count comes
    # back via a final ##STALE_COUNT=N## sentinel which we strip before
    # printing. Output lines preserved byte-for-byte vs the prior impl.
    # T-2427/G-070: target-exists-on-disk → silent (data-artifact dep), only
    # missing-on-disk → stale. Also treats system binaries (no /, no ., found
    # in $PATH) as resolved. Distinguishes real drift from runtime-data noise.
    echo -e "${CYAN}Stale edges:${NC}"
    local _stale_raw _stale_count=0
    _stale_raw=$(python3 - "$COMPONENTS_DIR" "$PROJECT_ROOT" <<'PYEOF' 2>/dev/null
import glob, os, shutil, sys, yaml

components_dir = sys.argv[1]
project_root = sys.argv[2]
SKIP = {'fw-cli', 'cron-audit', 'transcript',
        'check-active-task', 'check-tier0', 'error-watchdog'}

cards = []
known = set()
for cp in sorted(glob.glob(f"{components_dir}/*.yaml")):
    try:
        with open(cp) as cf:
            cd = yaml.safe_load(cf)
    except Exception:
        continue
    if not cd:
        continue
    cards.append(cd)
    known.add(cd.get('id', ''))
    known.add(cd.get('name', ''))
    known.add(cd.get('location', ''))

def _resolves_on_disk(target, root):
    """T-2427/G-070: True if target points at a real on-disk artifact.

    Data-artifact dependencies (logs, ledgers, runtime files, dirs that
    receive output) legitimately have no fabric card but reflect real
    runtime relationships. Only missing-from-disk targets are real drift.
    """
    if not target:
        return False
    # Absolute path → check verbatim
    if target.startswith('/'):
        return os.path.exists(target)
    # Relative path with slash → join against PROJECT_ROOT
    if '/' in target:
        return os.path.exists(os.path.join(root, target))
    # Bare name with no slash + no extension → check $PATH (system binary)
    # e.g. `gh`, `jq`, `dotnet`. Bare names WITH extension also try project-relative first.
    if '.' not in target and shutil.which(target):
        return True
    # Bare name (with or without extension) → also check project-relative
    return os.path.exists(os.path.join(root, target))

# T-2427/G-070: edge types whose semantics make a missing target NOT drift.
# `writes*` declares the script creates the target lazily on first invocation;
# the absence-from-disk is expected pre-bootstrap state, not real drift.
WRITE_TYPES = {'writes', 'writes_data', 'writes_runtime'}

count = 0
for cd in cards:
    name = cd.get('name', '')
    for dep in cd.get('depends_on', []) or []:
        if not isinstance(dep, dict):
            continue
        target = dep.get('target', '')
        edge_type = dep.get('type', '')
        if not target or target in known or target.startswith('all ') or target in SKIP:
            continue
        # T-2427/G-070: skip if target resolves to a real on-disk artifact
        if _resolves_on_disk(target, project_root):
            continue
        # T-2427/G-070: skip write-targets — script creates them, missing is expected
        if edge_type in WRITE_TYPES:
            continue
        print(f"  ! {name} → {target} (unresolved)")
        count += 1
print(f"##STALE_COUNT={count}##")
PYEOF
    )
    if [ -n "$_stale_raw" ]; then
        # Last line is the sentinel; everything before is operator output.
        local _stale_lines
        _stale_lines=$(printf '%s\n' "$_stale_raw" | sed '$d')
        _stale_count=$(printf '%s\n' "$_stale_raw" | tail -1 | sed -n 's/^##STALE_COUNT=\([0-9]*\)##$/\1/p')
        : "${_stale_count:=0}"
        if [ -n "$_stale_lines" ]; then
            printf '%s\n' "$_stale_lines"
        fi
    fi
    stale=$((stale + _stale_count))
    [ "$stale" -eq 0 ] && echo "  (none)"

    echo ""
    echo -e "${BOLD}Summary:${NC} unregistered: $unregistered, orphaned: $orphaned, stale: $stale"

    if [ "$summary_flag" = "--summary" ]; then
        echo "unregistered: $unregistered"
        echo "orphaned: $orphaned"
        echo "stale: $stale"
    fi

    return 0
}

# T-524: card well-formedness. This used to print "checking..." for every card, then
# "Deep validation not yet implemented", then `return 0` — the banner was honest but the
# EXIT CODE was not, so `fw fabric validate && echo ok` reported success for work that was
# never done. An abstention must be distinguishable from a pass (PL-205); "I validated
# nothing" and "everything is valid" may not share an exit code.
#
# SCOPE BOUNDARY vs do_drift, deliberately drawn so the two do not overlap:
#   drift    = card versus the world  (unregistered files, orphaned cards, stale edges)
#   validate = the card ITSELF        (parses, carries the fields every reader assumes, unique id)
# A `location:` that names a file which does not exist is drift's orphan check and is NOT
# repeated here.
#
# WHY THIS EXISTS AT ALL — T-522. A card missing `location:` aborted update-task.sh mid-
# completion under `set -euo pipefail` and silently lost two episodics. That fix added
# `|| true` at both greps, which makes a malformed card NON-FATAL but not VISIBLE: the card
# simply stops participating, and nothing says so. Worse, it is not merely inert — a card
# with no `location:` contributes nothing to the `registered` set built at line 25, so the
# file it describes is reported as UNREGISTERED and the operator is advised to run
# `fw fabric scan`, which would mint a SECOND card for the same file. Silence that
# manufactures duplicates.
#
# Exit: 0 = every card valid, 1 = findings, 2 = REFUSE (nothing was evaluated).
do_validate() {
    ensure_fabric_dirs

    local component="${1:-}"
    local out rc=0

    # `out=$(...)` must not be a bare assignment: under the inherited `set -euo pipefail`
    # a non-zero exit from the substitution terminates the whole script rather than
    # setting rc — the exact defect T-522 diagnosed, and this function's reason to exist.
    # The `|| rc=$?` makes it a compound list, which suspends set -e for the assignment.
    out=$(python3 - "$COMPONENTS_DIR" "$PROJECT_ROOT" "$component" <<'PYEOF'
import glob
import os
import sys

try:
    import yaml
except ImportError:
    print("REFUSE: PyYAML is not available, so no card could be parsed.")
    print("Nothing was evaluated — this is an abstention, not a pass.")
    sys.exit(2)

components_dir, project_root, only = sys.argv[1], sys.argv[2], sys.argv[3]

# Every required field is justified by a READER that misbehaves without it, cited by
# file:line. A field nobody reads is not required — inventing a schema and then enforcing
# it would make this a generator of busywork rather than a detector, and would be the
# "convention used as a classifier" failure T-509 records.
REQUIRED = {
    "id": "depends_on edges name card ids; a card without one can never be resolved as a "
          "dependency target (lib/drift.sh stale-edge pass, lib/deps.sh)",
    "name": "every report prints it as the subject of the line; without it drift renders "
            "'! → <path>' with a blank subject (lib/drift.sh:81)",
    "location": "the ONLY link from a card to the file it describes — registration "
                "matching (lib/drift.sh:25), orphan detection (lib/drift.sh:55), and "
                "component resolution in agents/task-create/update-task.sh (T-522)",
}

cards = sorted(glob.glob(os.path.join(components_dir, "*.yaml")))

if only:
    stem = os.path.splitext(os.path.basename(only))[0]
    kept = []
    for c in cards:
        if os.path.splitext(os.path.basename(c))[0] == stem:
            kept.append(c)
            continue
        try:
            with open(c) as fh:
                doc = yaml.safe_load(fh) or {}
            if isinstance(doc, dict) and str(doc.get("id", "")) == only:
                kept.append(c)
        except Exception:
            pass
    if not kept:
        print("REFUSE: no card matches %r (looked by card id and by filename stem)." % only)
        print("Nothing was evaluated — this is an abstention, not a pass.")
        sys.exit(2)
    cards = kept

if not cards:
    print("REFUSE: no component cards found under %s"
          % os.path.relpath(components_dir, project_root))
    print("Nothing was evaluated — this is an abstention, not a pass. A run over zero")
    print("cards must not be reportable as 'all cards valid'.")
    sys.exit(2)

findings = []          # (card_basename, field_or_kind, detail)
ids_seen = {}          # id -> [basenames]

for path in cards:
    base = os.path.basename(path)
    try:
        with open(path) as fh:
            doc = yaml.safe_load(fh)
    except Exception as exc:
        # An unparseable card is skipped in silence by every python pass in this file
        # (they wrap safe_load in bare try/except) — so it is present, counted by ls, and
        # invisible to the graph. That is the same silence, one level lower.
        findings.append((base, "yaml", "does not parse: %s" % str(exc).splitlines()[0][:120]))
        continue

    if not isinstance(doc, dict):
        findings.append((base, "yaml", "parses to %s, not a mapping" % type(doc).__name__))
        continue

    for field, why in REQUIRED.items():
        if field not in doc:
            findings.append((base, field, "missing — %s" % why))
        elif doc[field] is None or str(doc[field]).strip() == "":
            findings.append((base, field, "present but empty — %s" % why))

    cid = doc.get("id")
    if cid is not None and str(cid).strip():
        ids_seen.setdefault(str(cid).strip(), []).append(base)

for cid, holders in sorted(ids_seen.items()):
    if len(holders) > 1:
        # Two cards claiming one id makes every edge naming it ambiguous, and which one
        # wins is glob order — i.e. the filename, which nobody thinks of as semantic.
        findings.append((", ".join(sorted(holders)), "id",
                         "duplicate id %r held by %d cards" % (cid, len(holders))))

print("Fabric card validation")
print("cards checked: %d" % len(cards))
print("required fields: %s" % ", ".join(sorted(REQUIRED)))
print("")

if not findings:
    print("OK: %d card(s) valid" % len(cards))
    sys.exit(0)

by_card = {}
for base, field, detail in findings:
    by_card.setdefault(base, []).append((field, detail))

for base in sorted(by_card):
    print("  ! %s" % base)
    for field, detail in by_card[base]:
        print("      %s: %s" % (field, detail))

print("")
print("INVALID: %d finding(s) across %d card(s) of %d checked"
      % (len(findings), len(by_card), len(cards)))
sys.exit(1)
PYEOF
    ) || rc=$?

    echo "$out"

    if [ "$rc" -eq 2 ]; then
        echo -e "${YELLOW:-}Refused — nothing was validated (exit 2).${NC:-}" >&2
    elif [ "$rc" -eq 0 ]; then
        echo -e "${GREEN:-}Fabric cards valid${NC:-}"
    else
        echo -e "${RED:-}Fabric card validation FAILED${NC:-}" >&2
    fi
    return "$rc"
}
