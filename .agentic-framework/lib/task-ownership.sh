#!/usr/bin/env bash
# task-ownership.sh — is a task's `owner: human` a live sovereignty claim, or stale metadata?
#
# T-931, operator ruling 2026-09-29: `owner: human` is a sovereignty claim only while a Human
# acceptance criterion is actually OPEN. When none is open, the field asserts a judgement
# requirement that does not exist. Reverting it is R-033 read correctly, not R-033 bypassed.
#
# THIN SHIM BY DESIGN. The predicate itself lives in ONE place — tools/_t931-ownership.py — and is
# not re-implemented here. The delegation boundary is already encoded twice in this corpus (the
# scanner that enforces it and the predicate that reports it), which is open as G-052; a third
# encoding of "what is a Human acceptance criterion" in bash would make that worse. Same shape and
# same override point as lib/instance-position.sh, which is the established pattern here.
#
# FAILS SAFE, AND SAFE MEANS DO NOT FLIP. Every path that cannot reach a definite OWNER-STALE
# verdict — python3 missing, tool absent, parse error, non-zero exit, unexpected output — returns
# non-zero, which leaves `owner: human` exactly where it is. The dangerous direction is reverting
# ownership that is still justified, so ambiguity must never resolve toward the write. This is the
# opposite of instance-position.sh's `return 0` fail-open, deliberately: that shim's silent no-op
# skips a record, this one's would strip a sovereignty claim.
#
# Override point, used by tools/_t931-ownership-teeth.sh:
#   FW_OWNERSHIP_TOOL   path to _t931-ownership.py (default <root>/tools/_t931-ownership.py)

# fw_ownership_verdict <task-file> [root]
# Prints the verdict word on stdout. Exit 0 when a verdict was obtained, non-zero otherwise.
fw_ownership_verdict() {
    local file="${1:-}" root="${2:-${PROJECT_ROOT:-$(pwd)}}"
    [ -n "$file" ] && [ -f "$file" ] || return 1
    local tool="${FW_OWNERSHIP_TOOL:-$root/tools/_t931-ownership.py}"
    [ -f "$tool" ] && command -v python3 >/dev/null 2>&1 || return 1

    local out rc
    out="$(python3 - "$tool" "$file" <<'PY' 2>/dev/null
import sys, importlib.util
spec = importlib.util.spec_from_file_location("t931", sys.argv[1])
if spec is None or spec.loader is None:
    raise SystemExit(3)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print(m.verdict(sys.argv[2])[0])
PY
)"; rc=$?
    [ "$rc" -eq 0 ] || return 1
    case "$out" in
        OWNER-STALE|OWNER-JUSTIFIED|NOT-HUMAN-OWNED) printf '%s' "$out"; return 0 ;;
        *) return 1 ;;   # an unrecognised word is not a verdict, and must not read as one
    esac
}

# fw_ownership_is_stale <task-file> [root] — exit 0 ONLY on a definite OWNER-STALE.
fw_ownership_is_stale() {
    local v
    v="$(fw_ownership_verdict "${1:-}" "${2:-${PROJECT_ROOT:-$(pwd)}}")" || return 1
    [ "$v" = "OWNER-STALE" ]
}

# log_ownership_reversion <task-id> <old-owner> <new-owner> [root]
# Appends one JSON line naming the rule that authorised the write. A sanctioned write to a
# protected field that leaves no record is indistinguishable from an unsanctioned one.
log_ownership_reversion() {
    local task_id="${1:-}" old="${2:-}" new="${3:-}" root="${4:-${PROJECT_ROOT:-$(pwd)}}"
    local log="$root/.context/audits/ownership-reversions.jsonl"
    mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
    printf '{"ts":"%s","task":"%s","from":"%s","to":"%s","rule":"T-931","verdict":"OWNER-STALE","authority":"no open Human acceptance criterion","actor":"framework"}\n' \
        "$(date -u +%FT%TZ)" "$task_id" "$old" "$new" >> "$log" 2>/dev/null || true
    return 0
}
