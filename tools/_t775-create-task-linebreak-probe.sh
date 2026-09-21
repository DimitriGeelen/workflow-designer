#!/usr/bin/env bash
# T-775 (OBS-364) — does create-task.sh survive a line break in --name or --description?
#
# Two mechanisms, one root cause: user input is injected into YAML frontmatter without
# regard for line structure.
#
#   --name with a break      -> `name: "line one` on one line, the remainder on the next.
#                               That injected line STARTS WITH a frontmatter key, so it
#                               captures the substitution T-774 anchored, emptying the real
#                               field. yaml.safe_load raises ParserError.
#                               This is the one input that defeats T-774: the anchor
#                               honours lines, so an input that manufactures a line wins.
#   --description multi-line -> `description: >` is a folded block scalar; only the first
#                               line was indented, so the block terminated early and the
#                               continuation parsed as a top-level key. ScannerError.
#
# Fix under test: a break in the name is REFUSED at the input boundary; a multi-line
# description is EMITTED CORRECTLY (every line carries the block indent) rather than
# refused, because a description is the one field with a real reason to span lines.
#
# NEGATIVE CONTROLS use the genuine pre-fix script, retrieved from git at the commit that
# precedes this fix — not a reconstruction of what it used to do. A reconstruction only
# proves the reconstruction behaves as written.

set -uo pipefail

ROOT="/opt/832-Workflow-designer"
SCRIPT="$ROOT/.agentic-framework/agents/task-create/create-task.sh"
PREFIX_COMMIT="fcc9904c"   # T-774: the last commit before the T-775 line-break fix
PASS=0
FAIL=0

[ -f "$SCRIPT" ] || { echo "FATAL: script not found: $SCRIPT"; exit 2; }

WORK="$(mktemp -d)"
# The control MUST sit beside the original: create-task.sh derives FRAMEWORK_ROOT from
# "$(dirname "$0")/../.." and sources lib/paths.sh from it, so a copy elsewhere cannot
# start at all — and a control that cannot start reports "no file created", which looks
# exactly like a passing fix (measured while building the T-774 probe).
POISON="$ROOT/.agentic-framework/agents/task-create/.t775-negcontrol.sh"
trap 'rm -rf "$WORK"; rm -f "$POISON"' EXIT

mkfixture() {
    local fx="$WORK/$1"
    rm -rf "$fx"
    mkdir -p "$fx/.tasks/active" "$fx/.tasks/completed" "$fx/.context"
    cp -r "$ROOT/.tasks/templates" "$fx/.tasks/"
    touch "$fx/.framework.yaml"
    printf '%s' "$fx"
}

# create <script> <fixture> <name> <description> [extra args...] ; echoes new file or ""
create() {
    local script="$1" fx="$2" nm="$3" ds="$4"; shift 4
    local before after
    before="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    env PROJECT_ROOT="$fx" TASKS_DIR="$fx/.tasks" CONTEXT_DIR="$fx/.context" \
        "$script" --name "$nm" --description "$ds" "$@" >/dev/null 2>&1
    after="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    [ "$after" -gt "$before" ] || return 0
    ls -t "$fx/.tasks/active/"*.md 2>/dev/null | head -1
}

# parse <file> <key> — prints the round-tripped YAML value, or PARSE-FAIL:<ExceptionName>
parse() {
    python3 -c "
import sys, yaml
p, key = sys.argv[1], sys.argv[2]
fm = open(p, encoding='utf-8').read().split('---')[1]
try:
    d = yaml.safe_load(fm)
except Exception as ex:
    print('PARSE-FAIL:' + type(ex).__name__); raise SystemExit(0)
v = d.get(key)
print('' if v is None else str(v))
" "$1" "$2"
}

ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; shift; for l in "$@"; do printf '        %s\n' "$l"; done; FAIL=$((FAIL + 1)); }

echo "=== T-775: line breaks in name and description ==="
echo
echo "--- the fixed script ---"

FX="$(mkfixture live)"
NL='
'

# 1. A break in the name is refused, and nothing is written.
f="$(create "$SCRIPT" "$FX" "line one${NL}owner: injected" 'single line' --type build --owner agent)"
if [ -z "${f:-}" ]; then
    ok "line break in name — refused, no task file written"
else
    bad "line break in name — a task file was created anyway" "file: $f"
fi

# 2. NEGATIVE CONTROL on the guard itself: a name with no break must still be accepted.
#    Without this leg, a guard that refused EVERY name would score green above.
f="$(create "$SCRIPT" "$FX" 'an ordinary single line name' 'single line' --type build --owner agent)"
if [ -n "${f:-}" ] && [ "$(parse "$f" name)" = "an ordinary single line name" ]; then
    ok "ordinary name — still accepted, so the guard is not refusing everything"
else
    bad "ordinary name — the guard is over-refusing or the value did not round-trip" "file: ${f:-<none>}"
fi

# 3. A multi-line description is emitted correctly, not refused, and round-trips.
f="$(create "$SCRIPT" "$FX" 'multi line description case' "first line${NL}second line${NL}${NL}after a blank" --type build --owner agent)"
if [ -n "${f:-}" ]; then
    d="$(parse "$f" description)"
    o="$(parse "$f" owner)"
    case "$d" in
        PARSE-FAIL:*) bad "multi-line description — frontmatter does not parse" "$d" ;;
        *"first line second line"*"after a blank"*)
            ok "multi-line description — parses, folds, and keeps the paragraph break"
            if [ "$o" = "agent" ]; then
                ok "multi-line description — ownership field still correct"
            else
                bad "multi-line description — ownership field wrong" "owner: [$o]"
            fi
            ;;
        *) bad "multi-line description — value did not round-trip" "got: [$d]" ;;
    esac
else
    bad "multi-line description — refused; it should be emitted correctly, not rejected"
    FAIL=$((FAIL + 1))
fi

echo
echo "--- negative controls: the genuine pre-fix script from $PREFIX_COMMIT ---"

if ! git -C "$ROOT" show "$PREFIX_COMMIT:.agentic-framework/agents/task-create/create-task.sh" > "$POISON" 2>/dev/null; then
    bad "could not retrieve the pre-fix script from $PREFIX_COMMIT" \
        "Without it this probe cannot show that it is able to fail," \
        "so every PASS above is unsupported."
else
    chmod +x "$POISON"
    FXN="$(mkfixture prefix)"

    # 4. The pre-fix script must reproduce the name defect: a file IS written, its
    #    frontmatter does NOT parse, and the ownership field was captured.
    f="$(create "$POISON" "$FXN" "line one${NL}owner: injected" 'single line' --type build --owner agent)"
    if [ -z "${f:-}" ]; then
        bad "pre-fix script refused the broken name — it should not have" \
            "This probe is not measuring the guard it claims to."
    else
        v="$(parse "$f" name)"
        case "$v" in
            PARSE-FAIL:*) ok "pre-fix script reproduces the name defect ($v)" ;;
            *) bad "pre-fix script produced parseable frontmatter" "name: [$v]" ;;
        esac
    fi

    # 5. The pre-fix script must reproduce the description defect.
    f="$(create "$POISON" "$FXN" 'multi line description case' "first line${NL}second line" --type build --owner agent)"
    if [ -z "${f:-}" ]; then
        bad "pre-fix script wrote no file for the description case"
    else
        v="$(parse "$f" description)"
        case "$v" in
            PARSE-FAIL:*) ok "pre-fix script reproduces the description defect ($v)" ;;
            *) bad "pre-fix script produced parseable frontmatter" "description: [$v]" ;;
        esac
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
