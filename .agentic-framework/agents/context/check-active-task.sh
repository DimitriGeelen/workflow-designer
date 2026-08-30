#!/bin/bash
# Task-First Enforcement Hook — PreToolUse gate for Write/Edit/Bash tools
# Blocks file modifications when no active task is set in focus.yaml.
#
# Exit codes (Claude Code PreToolUse semantics):
#   0 — Allow tool execution
#   2 — Block tool execution (stderr shown to agent)
#
# Receives JSON on stdin with tool_name and tool_input.
# For Write/Edit: checks tool_input.file_path
# For Bash: checks tool_input.command against safe-command allowlist (T-650)
#
# Exempt paths (framework operations that don't need task context):
#   .context/   — Context fabric management
#   .tasks/     — Task creation/updates
#   .claude/    — Claude Code settings
#
# Part of: Agentic Engineering Framework (P-002: Structural Enforcement)

set -uo pipefail

# --- FW_SAFE_MODE escape hatch (T-650) ---
# Disables task gate only. Tier 0 and boundary check remain active.
if [ "${FW_SAFE_MODE:-0}" = "1" ]; then
    echo "SAFE MODE: Task gate bypassed (FW_SAFE_MODE=1)" >&2
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$FRAMEWORK_ROOT/lib/paths.sh"
source "$FRAMEWORK_ROOT/lib/config.sh"
fw_hook_crash_trap "check-active-task"
FOCUS_FILE="$PROJECT_ROOT/.context/working/focus.yaml"

# Read stdin (JSON from Claude Code)
INPUT=$(cat)

# Extract tool name and inputs
TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null)

# T-2463/T-2465 (OBS-080): re-anchor PROJECT_ROOT to the per-call stdin `cwd` so a
# worktree session reads the worktree's focus, not main's. In a worktree session
# this gate is invoked as <main>/bin/fw hook and bin/fw resolves PROJECT_ROOT to
# the MAIN repo; the shared resolver re-anchors to the project the tool actually
# ran in. Logic now lives in lib/paths.sh:fw_reanchor_from_cwd (generalized from
# the original inline block so every hook shares one implementation). No-op for
# non-worktree sessions. Recompute FOCUS_FILE after, since it caches PROJECT_ROOT.
fw_reanchor_from_hook_stdin "$INPUT"
FOCUS_FILE="$PROJECT_ROOT/.context/working/focus.yaml"

# --- Bash tool: safe-command fast path (T-650) ---
if [ "$TOOL_NAME" = "Bash" ]; then
    BASH_CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

    # fw hook commands are always allowed (hooks calling hooks)
    case "$BASH_CMD" in
        "fw hook "*|"bin/fw hook "*)
            exit 0
            ;;
    esac

    # T-2410 case 2: universal --help / --version exemption.
    # Any command with --help or --version is read-only by convention (the flag
    # short-circuits all real work in every fw subcommand and 99% of other
    # tools). Without this, `fw upstream --help` blocked at the work-completed
    # focus gate purely because `upstream` is not in the safe-list — but the
    # user just wanted to read help. Matches at any position so `cd … && fw
    # upstream --help` is also exempt.
    if [[ "$BASH_CMD" =~ (^|[[:space:]])(--help|--version)([[:space:]]|$) ]]; then
        exit 0
    fi

    # Source safe-command allowlist
    source "$SCRIPT_DIR/lib/safe-commands.sh" 2>/dev/null || true

    # Check write patterns FIRST — even "safe" commands with redirects are writes
    if type has_bash_write_pattern &>/dev/null && has_bash_write_pattern "$BASH_CMD"; then
        # Command has write patterns — fall through to active-task check
        :
    elif type is_bash_safe_command &>/dev/null && is_bash_safe_command "$BASH_CMD"; then
        # Safe command with no write patterns — allow without task.
        #
        # T-392: DEFERRED, not immediate. This `exit 0` used to fire ~240 lines above
        # the focus-drift gate, so every command on the safe-list bypassed drift
        # detection entirely. `fw context add-learning --task T-OTHER` is on that list,
        # which is why drift pattern 2 was not merely weak but UNREACHABLE — no anchor
        # fix could rescue a block that never executed (T-607 widened the anchor and
        # said so explicitly). The exit now happens after the gate, at the marked site.
        _deferred_safe_exit=1
    elif [[ "$BASH_CMD" =~ (^|[[:space:]]|/)fw[[:space:]]+(work-on|task[[:space:]]+create|context[[:space:]]+focus|inception)([[:space:]]|$) ]]; then
        # Task-bootstrap commands always allowed (T-2052) — they ESTABLISH the
        # active task, so gating them on one is a deadlock; the "No active task"
        # block message below even lists them as the unblock path. Whole-command
        # match survives a `cd … && bin/fw …` prefix and multi-line forms, which
        # is_bash_safe_command's first-word base extraction misses (that fragility
        # is what caused the deadlock). Reached only when no write pattern is
        # present — the if-branch above already caught those.
        exit 0
    fi

    # Non-safe or write-pattern Bash commands: fall through to active-task check.
    # FILE_PATH stays empty for Bash — exempt-path check won't match,
    # so we go straight to the task-exists check.
fi

# Extract file path from tool input (supports file_path and notebook_path for NotebookEdit)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    print(ti.get('file_path', '') or ti.get('notebook_path', ''))
except:
    print('')
" 2>/dev/null)

# B-005 (T-229): Protect hook enforcement config from agent modification.
# .claude/settings.json controls which hooks run — modifying it can disable all enforcement.
# Block this specifically BEFORE the general exempt-path check.
case "$FILE_PATH" in
    */settings.json)
        # Only block if it's the Claude Code settings file
        if echo "$FILE_PATH" | grep -q '\.claude/settings\.json$'; then
            echo "" >&2
            echo "BLOCKED: Cannot modify .claude/settings.json — this controls enforcement hooks." >&2
            echo "" >&2
            echo "Modifying this file could disable task gates, Tier 0 checks, and budget enforcement." >&2
            echo "Changes to hook configuration require human review." >&2
            echo "" >&2
            echo "Policy: B-005 (Enforcement Config Protection)" >&2
            exit 2
        fi
        ;;
esac

# Exempt paths — framework operations that are part of task management itself
# Anchored to PROJECT_ROOT to prevent matching arbitrary paths (e.g., /root/.claude/)
case "$FILE_PATH" in
    "$PROJECT_ROOT"/.context/*|"$PROJECT_ROOT"/.tasks/*|"$PROJECT_ROOT"/.claude/*|"$PROJECT_ROOT"/.git/*)
        exit 0
        ;;
esac

# T-1431 / T-1274: Claude Code auto-memory writes to
# <home>/.claude/projects/<project>/memory/*.md — outside PROJECT_ROOT.
# Blocking these defeats the mechanism meant to prevent recurrence of
# problems, and does so exactly when it's most needed (mid-onboarding,
# before T-001-T-005 complete). Exempt the auto-memory directory
# globally, regardless of user prefix or task state.
case "$FILE_PATH" in
    */.claude/projects/*/memory/*)
        exit 0
        ;;
esac

# If no .context/ directory exists yet (fresh project), allow — bootstrap case
if [ ! -d "$PROJECT_ROOT/.context/working" ]; then
    exit 0
fi

# If no focus file exists: block if project is initialized, allow if bootstrap (T-002)
#
# T-392: a deferred safe command settles here. With no focus file there is no focus to
# drift from, so the gate below has nothing to say and the safe-list verdict stands.
# Without this the deferral would have converted "ls is always allowed" into "ls is
# blocked until you run context init" — a safe command must not acquire a task
# precondition just because the drift gate now runs later.
if [ ! -f "$FOCUS_FILE" ] && [ -n "${_deferred_safe_exit:-}" ]; then
    exit 0
fi

if [ ! -f "$FOCUS_FILE" ]; then
    if [ -f "$PROJECT_ROOT/.framework.yaml" ]; then
        # Project is initialized but governance not active — block
        echo "BLOCKED: Project initialized but session not active. Run '$(_emit_user_command "context init")' first." >&2
        exit 2
    fi
    # True bootstrap — no .framework.yaml yet, allow
    echo "Note: Context not initialized. Run '$(_emit_user_command "context init")' for task tracking." >&2
    exit 0
fi

# Read current task AND session stamp from focus.yaml.
# T-1858: emit one value per line and read with two separate reads.
# Earlier `print(f'{task} {session}')` + `read -r CURRENT_TASK FOCUS_SESSION`
# collapsed empty task + non-empty session into CURRENT_TASK under default IFS,
# producing misleading "Task <SESSION-ID> is not active" errors.
{ read -r CURRENT_TASK; read -r FOCUS_SESSION; } < <(python3 -c "
import yaml, sys
try:
    with open('$FOCUS_FILE') as f:
        data = yaml.safe_load(f)
    if not data:
        print('')
        print('')
    else:
        task = data.get('current_task', '') or ''
        if task == 'null': task = ''
        session = data.get('focus_session', '') or ''
        print(task)
        print(session)
except:
    print('')
    print('')
" 2>/dev/null)

# Read current session ID for comparison
CURRENT_SESSION=""
SESSION_FILE="$PROJECT_ROOT/.context/working/session.yaml"
if [ -f "$SESSION_FILE" ]; then
    CURRENT_SESSION=$({ grep "^session_id:" "$SESSION_FILE" 2>/dev/null || true; } | head -1 | awk '{print $2}')
fi

# T-2054: post-completion commit deadlock. `--status work-completed` nulls
# focus.yaml current_task AND moves the task active/→completed/, so it can no
# longer be re-focused (G-013 requires the focused task in active/), yet its own
# completion file-move + episodic must still be committed (P-009 commit cadence).
# When focus is null, allow `git commit` so that checkpoint can land. Committing
# persists work already produced under the Write/Edit task gate — it is not new
# work — and the commit-msg hook still enforces P-002 (refuses a message lacking
# T-XXX). `--no-verify`/`-n` is excluded: it would skip that hook, so it falls
# through to the block below (a Tier-2 emergency needing explicit authorisation).
# This lives here, NOT in is_bash_safe_command, on purpose: when focus is NON-null
# git commit must still reach the focus-drift gate (T-1730) — a context-free
# allowlist entry would short-circuit that. `git add` (task-agnostic, no drift)
# stays in is_bash_safe_command.
#
# T-638: the match used to be a raw-string `=~ git[[:space:]]+commit` over the
# WHOLE command. It therefore admitted every clause of `git commit -m "..."; X`,
# admitted a `| tee` the write check above had already flagged (that check falls
# through rather than exiting, so it reached here anyway), and admitted an
# arbitrary unknown binary whose QUOTED ARGUMENT merely contained the words. The
# predicate now judges each clause of the quote-stripped command; the paragraph
# above is the argument for why that, and not "contains a commit", is the rule.
# Fails CLOSED if the library did not load — this exemption runs with no task, so
# an absent predicate must block, never allow.
if [ -z "$CURRENT_TASK" ] && [ "$TOOL_NAME" = "Bash" ] && [ -n "$BASH_CMD" ]; then
    if type _sc_is_commit_only_command &>/dev/null && \
       _sc_is_commit_only_command "$BASH_CMD" && \
       ! [[ "$BASH_CMD" =~ (^|[[:space:]])(--no-verify|-n)([[:space:]]|$) ]]; then
        echo "NOTE: no active task — allowing 'git commit' to checkpoint completed work (T-2054). commit-msg hook still enforces T-XXX." >&2
        exit 0
    fi
fi

# T-392: a deferred safe command settles here when focus is NULL. Drift is defined as
# "target ≠ focus", so with no focus there is no drift to detect and nothing downstream
# can have an opinion — the safe-list verdict stands.
#
# This guard is not cosmetic. Without it the deferral re-created exactly the T-390
# deadlock it was built on top of: `fw note`, `fw context add-*`, `fw handover` and even
# `git status` were blocked under null focus, because the deferred exit sits below this
# block. Caught by the T-390 deadlock controls in tools/_t392-safelist-shadow-gate.py,
# which is why that AC named the verbs instead of trusting an adjacent measurement.
if [ -z "$CURRENT_TASK" ] && [ -n "${_deferred_safe_exit:-}" ]; then
    exit 0
fi

if [ -z "$CURRENT_TASK" ]; then
    echo "" >&2
    echo "BLOCKED: No active task. Framework rule: nothing gets done without a task." >&2
    echo "" >&2
    echo "To unblock:" >&2
    echo "  1. Create a task:  $(_fw_cmd) task create --name '...' --type build --start" >&2
    echo "  2. Set focus:      $(_fw_cmd) context focus T-XXX" >&2
    echo "" >&2
    echo "Attempting to modify: $FILE_PATH" >&2
    echo "Policy: P-002 (Structural Enforcement Over Agent Discipline)" >&2
    exit 2
fi

# --- Session stamp validation (T-560) ---
# If focus was set in a PREVIOUS session, block and advise.
# This prevents stale focus from granting a free pass to new sessions.
# T-392: skipped for a deferred safe command. Stale focus is a reason to refuse WORK,
# not a reason to refuse `ls`; before the deferral those commands had already exited.
# Threading the flag here keeps the safe-list contract intact while still letting the
# command fall through to the drift gate below, which is the whole point of deferring.
if [ -z "${_deferred_safe_exit:-}" ] && \
   [ -n "$CURRENT_SESSION" ] && [ -n "$FOCUS_SESSION" ] && [ "$FOCUS_SESSION" != "$CURRENT_SESSION" ]; then
    # Look up task name for advisory
    STALE_TASK_NAME=""
    STALE_FILE=$(find_task_file "$CURRENT_TASK" active 2>/dev/null)
    if [ -n "$STALE_FILE" ]; then
        STALE_TASK_NAME=$({ grep "^name:" "$STALE_FILE" 2>/dev/null || true; } | head -1 | sed 's/name:[[:space:]]*//' | tr -d '"')
    fi

    echo "" >&2
    echo "══════════════════════════════════════════════════════════" >&2
    echo "  STALE FOCUS — Task From Previous Session" >&2
    echo "══════════════════════════════════════════════════════════" >&2
    echo "" >&2
    echo "  Previous task: $CURRENT_TASK" >&2
    [ -n "$STALE_TASK_NAME" ] && echo "  Name:          $STALE_TASK_NAME" >&2
    echo "  Set in session: $FOCUS_SESSION" >&2
    echo "  Current session: $CURRENT_SESSION" >&2
    echo "" >&2
    echo "  Focus was set in a previous session. To continue this task:" >&2
    echo "    $(_fw_cmd) work-on $CURRENT_TASK" >&2
    echo "" >&2
    echo "  To start different work:" >&2
    echo "    $(_fw_cmd) work-on 'New task name' --type build" >&2
    echo "" >&2
    echo "  Attempting to modify: $FILE_PATH" >&2
    echo "  Policy: T-560 (Session-Stamped Focus Enforcement)" >&2
    echo "══════════════════════════════════════════════════════════" >&2
    echo "" >&2
    exit 2
fi

# --- Agent-control detection (T-1739) -------------------------------------
# Multi-signal helper: returns true if any indicator suggests we're under
# agent (Claude Code, etc.) control. Witnessed T-1738 commit: CLAUDECODE was
# unset in the actual PreToolUse env even though the parent shell had it.
# Single-signal CLAUDECODE check would silently degrade the drift gate.
#
# Signals (in preference order — most reliable first):
#   1. CLAUDECODE=1            — Claude Code's documented contract
#   2. AI_AGENT non-empty      — broader agent-runtime convention
# We deliberately do NOT use stdin-shape (TOOL_NAME extracted) as a signal
# because tests/dev environments legitimately pipe JSON to the script and
# would degrade to blocking. If both env vars get stripped by the host
# runtime, the advisory log entry surfaces it via .gate-bypass-log.yaml.
_under_agent_control() {
    [ "${CLAUDECODE:-}" = "1" ] && return 0
    [ -n "${AI_AGENT:-}" ] && return 0
    return 1
}

# --- Focus-target drift detection (T-1730, closes G3 from T-1729 meta-RCA) ---
# When a Bash command targets a specific task that differs from the focused task,
# block under agent control with --switch-focus override (logged).
# Only inspects fw task update / fw context add-* --task / git commit -m "T-X: ...".
# Does NOT gate fw work-on / fw context focus / fw inception decide / fw task review|show
# (those are intentional state transitions or read-only).
if [ "$TOOL_NAME" = "Bash" ] && [ -n "$BASH_CMD" ] && [ -n "$CURRENT_TASK" ]; then
    TARGET_TASK=""
    # Bash built-in regex (no subprocess fork — keeps hook fast).
    #
    # T-607: the path anchor is ([^[:space:]]*/)? — any directory prefix — NOT (bin/)?.
    # CLAUDE.md mandates `cd /opt/... && .agentic-framework/bin/fw ...`, where the char
    # before `bin/fw` is `/`, and the old alternation had no branch for it. Measured:
    # bare `fw task update T-N` exited 2 with FOCUS-DRIFT while the SAME command written
    # with the mandated path prefix exited 0, silent. The gate was blind to the only form
    # the project tells people to use. Pattern 3 was unaffected because it anchors on the
    # commit message, not on fw — which is why the gate looked alive: every drift block
    # anyone actually saw was pattern 3.
    #
    # The trailing `/` inside the group is load-bearing: it keeps `myfw task update` from
    # matching. A guard that fires on the wrong command trains people to bypass it.
    #
    # T-392 (landed): the safe-command early-return at the top of this file used to exit 0
    # before this block ran, so pattern 2 was unreachable regardless of this anchor. That
    # exit is now deferred to just below this gate, and pattern 2 fires. The comment is
    # kept rather than deleted because the two defects shared one symptom and only the
    # control that separated them showed there were two.
    # T-639: the three patterns moved into _sc_drift_target (lib/safe-commands.sh),
    # because each read task ids out of QUOTED arguments and so treated a command
    # that merely mentioned a task as an action on it. The predicate keeps patterns
    # 1 and 2 on the quote-stripped command (their id is a bare argument) while
    # pattern 3 reads the raw -m value (its id is legitimately quoted) and anchors
    # `T-NNN:` at the START of that value. Rationale in full at the definition.
    # `type` guard, not decoration: the library is sourced with `|| true`, so an
    # unguarded call would emit "command not found" into the hook's stderr on every
    # Bash invocation if it ever failed to load.
    if type _sc_drift_target &>/dev/null && _sc_drift_target "$BASH_CMD"; then
        TARGET_TASK="$_SC_DRIFT_TARGET"
    fi

    # If a target was identified and differs from focused task: drift
    if [ -n "$TARGET_TASK" ] && [ "$TARGET_TASK" != "$CURRENT_TASK" ]; then
        # T-1890: two bypass mechanisms.
        # (a) --switch-focus flag in BASH_CMD — works for fw commands whose
        #     downstream parsers accept the no-op token (update-task.sh,
        #     agents/context/lib/{learning,pattern,decision}.sh).
        # (b) FW_SWITCH_FOCUS=1 env-var prefix — works universally including
        #     `git commit ... T-X: ...` (git rejects unknown flags so the
        #     flag mechanism fundamentally can't cover that pattern).
        _bypass_mechanism=""
        if [[ "$BASH_CMD" =~ (^|[[:space:]])--switch-focus([[:space:]]|=|$) ]]; then
            _bypass_mechanism="--switch-focus"
        elif [[ "$BASH_CMD" =~ (^|[[:space:]])FW_SWITCH_FOCUS=1([[:space:]]|$) ]]; then
            _bypass_mechanism="FW_SWITCH_FOCUS=1"
        fi
        if [ -n "$_bypass_mechanism" ]; then
            BYPASS_LOG="$PROJECT_ROOT/.context/working/.gate-bypass-log.yaml"
            mkdir -p "$(dirname "$BYPASS_LOG")"
            # T-1861: escape embedded single quotes per YAML single-quoted-scalar rule.
            _t1861_esc_task="${CURRENT_TASK//\'/\'\'}"
            _t1861_esc_target="${TARGET_TASK//\'/\'\'}"
            {
                echo "- timestamp: '$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
                echo "  task: '$_t1861_esc_task'"
                echo "  flag: '$_bypass_mechanism'"
                echo "  caller: 'check-active-task focus-drift'"
                echo "  target: '$_t1861_esc_target'"
                echo "  command: '$(echo "$BASH_CMD" | head -c 200 | tr -d "'")'"
            } >> "$BYPASS_LOG" 2>/dev/null || true
            echo "NOTE: focus-drift override ($_bypass_mechanism) — target $TARGET_TASK ≠ focus $CURRENT_TASK. Logged." >&2
        elif _under_agent_control; then
            echo "" >&2
            echo "══════════════════════════════════════════════════════════" >&2
            echo "  FOCUS-DRIFT — Action targets a different task" >&2
            echo "══════════════════════════════════════════════════════════" >&2
            echo "" >&2
            echo "  Current focus: $CURRENT_TASK" >&2
            echo "  Action target: $TARGET_TASK" >&2
            echo "" >&2
            echo "  Framework rule: actions on a task should run with focus on" >&2
            echo "  that task. To proceed, either:" >&2
            echo "" >&2
            # T-386: remedy 1 is unreachable when the target is COMPLETED. T-381
            # scoped `fw context focus` to active/ (the gate reads focus back with
            # `find_task_file "$CURRENT_TASK" active`, so focusing a completed id
            # produced a writable-but-unusable state). The drift target is completed
            # in the COMMON case — a follow-up `git commit -m "T-XXX: ..."` naming a
            # task that just closed — so without this branch the gate's own first
            # recommendation is a command the same subsystem will refuse.
            # Scoped exactly like the writer now is; an id that resolves in neither
            # directory falls through to the normal wording rather than asserting
            # something about a task nobody can find.
            # PROJECT_ROOT, not TASKS_DIR: this hook never sets TASKS_DIR, and a
            # guard on an unset variable would have made the whole branch a silent
            # no-op — the fix would have "shipped" while the message never changed.
            # Line 469 below is the in-file precedent for "$PROJECT_ROOT"/.tasks/…
            _t386_completed=""
            if [ -n "${PROJECT_ROOT:-}" ]; then
                for _t386_f in "$PROJECT_ROOT"/.tasks/completed/"$TARGET_TASK"-*.md; do
                    [ -e "$_t386_f" ] && _t386_completed=1 && break
                done
            fi
            if [ -n "$_t386_completed" ]; then
                echo "    1. NOT AVAILABLE — $TARGET_TASK is completed, and" >&2
                echo "       '$(_fw_cmd) context focus' accepts active tasks only (T-381)." >&2
                echo "       Use option 2 or 3 below. This is the normal path for a" >&2
                echo "       follow-up commit on a task that has already closed." >&2
            else
                echo "    1. Switch focus first:" >&2
                echo "       $(_fw_cmd) context focus $TARGET_TASK" >&2
            fi
            echo "" >&2
            echo "    2. Append --switch-focus to a fw command (logged Tier 2)." >&2
            echo "       Works for: fw task update, fw context add-*." >&2
            echo "" >&2
            echo "    3. Prefix FW_SWITCH_FOCUS=1 to any command (logged Tier 2)." >&2
            echo "       Works universally including git commit (where git rejects" >&2
            echo "       unknown flags). Use this when option 2 isn't accepted." >&2
            echo "" >&2
            echo "  Attempting to run: $(echo "$BASH_CMD" | head -c 120)" >&2
            echo "  Policy: T-1730 (Focus-Target Drift Gate, closes G3 from T-1729)" >&2
            echo "  Bypass-mechanism contract: T-1890 (flag + env-var dual path)" >&2
            echo "══════════════════════════════════════════════════════════" >&2
            echo "" >&2
            exit 2
        else
            # No agent-control signal — advisory only (test/dev shell)
            echo "NOTE: focus-drift detected: target $TARGET_TASK ≠ focus $CURRENT_TASK. (Not blocking — no agent-control signal: CLAUDECODE/AI_AGENT/TOOL_NAME all empty.)" >&2
        fi
    fi
fi

# --- T-392: the deferred safe-command exit ---------------------------------
# A safe-list command has now passed the focus-drift gate above and is allowed.
# This is the site the early `exit 0` moved to; everything between there and here
# is either a no-op for Bash (FILE_PATH-based checks) or explicitly guarded on
# this flag. Placing it AFTER the gate is the entire fix: the gate was never weak
# for pattern 2, it was unreachable, and unreachable reads as healthy.
if [ -n "${_deferred_safe_exit:-}" ]; then
    exit 0
fi

# Verify task is actually active (not completed/archived) — G-013
ACTIVE_FILE=$(find_task_file "$CURRENT_TASK" active)
if [ -z "$ACTIVE_FILE" ]; then
    echo "" >&2
    echo "BLOCKED: Task $CURRENT_TASK is not active (may be completed or missing)." >&2
    echo "" >&2
    echo "To unblock:" >&2
    echo "  $(_fw_cmd) work-on T-XXX   (resume an active task)" >&2
    echo "  $(_fw_cmd) work-on 'name'  (create a new task)" >&2
    echo "" >&2
    echo "Attempting to modify: $FILE_PATH" >&2
    echo "Policy: P-002 (Structural Enforcement Over Agent Discipline)" >&2
    exit 2
fi

# --- Status validation (T-354) ---
# Task file exists in active/ but may be captured (not started) or work-completed
# (partial-complete). Only started-work and issues are workable statuses.
TASK_STATUS=$({ grep "^status:" "$ACTIVE_FILE" 2>/dev/null || true; } | head -1 | sed 's/status:[[:space:]]*//')
case "$TASK_STATUS" in
    started-work|issues)
        # Workable statuses — allow
        ;;
    captured)
        echo "" >&2
        echo "BLOCKED: Task $CURRENT_TASK has status 'captured' (work not started)." >&2
        echo "" >&2
        echo "To unblock:" >&2
        echo "  $(_fw_cmd) work-on $CURRENT_TASK   (sets status to started-work)" >&2
        echo "" >&2
        echo "Attempting to modify: $FILE_PATH" >&2
        echo "Policy: P-002 (Task must be started before modifying files)" >&2
        exit 2
        ;;
    work-completed)
        echo "" >&2
        echo "BLOCKED: Task $CURRENT_TASK has status 'work-completed'." >&2
        echo "" >&2
        echo "To unblock:" >&2
        echo "  $(_fw_cmd) work-on T-XXX   (resume another task)" >&2
        echo "  $(_fw_cmd) work-on 'name'  (create a new task)" >&2
        echo "" >&2
        echo "Attempting to modify: $FILE_PATH" >&2
        echo "Policy: P-002 (Cannot modify files under a completed task)" >&2
        exit 2
        ;;
    "")
        # Legacy task without status field — warn but allow
        echo "NOTE: Task $CURRENT_TASK has no status field in task file." >&2
        ;;
esac

# --- Onboarding gate (T-535) ---
# If incomplete onboarding tasks exist, only allow work on onboarding tasks.
# Detection: tasks with tags containing "onboarding" in .tasks/active/.
# Fast path: .context/working/.onboarding-complete marker means all done.
ONBOARDING_MARKER="$PROJECT_ROOT/.context/working/.onboarding-complete"
if [ ! -f "$ONBOARDING_MARKER" ]; then
    # Check if any active tasks have onboarding tag and are not completed
    INCOMPLETE_ONBOARDING=""
    for tf in "$PROJECT_ROOT"/.tasks/active/T-*.md; do
        [ -f "$tf" ] || continue
        if head -20 "$tf" | grep -q '^tags:.*onboarding' 2>/dev/null; then
            tf_status=$({ grep "^status:" "$tf" 2>/dev/null || true; } | head -1 | sed 's/status:[[:space:]]*//')
            if [ "$tf_status" != "work-completed" ]; then
                tf_id=$({ grep "^id:" "$tf" 2>/dev/null || true; } | head -1 | sed 's/id:[[:space:]]*//')
                tf_name=$({ grep "^name:" "$tf" 2>/dev/null || true; } | head -1 | sed 's/name:[[:space:]]*//' | tr -d '"')
                INCOMPLETE_ONBOARDING="${INCOMPLETE_ONBOARDING}  ${tf_id}: ${tf_name} (${tf_status})\n"
            fi
        fi
    done

    if [ -n "$INCOMPLETE_ONBOARDING" ]; then
        # Check if current task is an onboarding task
        CURRENT_IS_ONBOARDING=false
        if [ -n "$ACTIVE_FILE" ] && head -20 "$ACTIVE_FILE" | grep -q '^tags:.*onboarding' 2>/dev/null; then
            CURRENT_IS_ONBOARDING=true
        fi

        if [ "$CURRENT_IS_ONBOARDING" = false ]; then
            echo "" >&2
            echo "BLOCKED: Onboarding tasks incomplete. Complete setup before starting other work." >&2
            echo "" >&2
            echo "Remaining onboarding tasks:" >&2
            echo -e "$INCOMPLETE_ONBOARDING" >&2
            echo "To work on onboarding:" >&2
            echo "  $(_fw_cmd) work-on T-001" >&2
            echo "" >&2
            echo "To skip onboarding (not recommended):" >&2
            echo "  $(_fw_cmd) onboarding skip" >&2
            echo "" >&2
            echo "Attempting to modify: $FILE_PATH" >&2
            echo "Policy: T-532 (Onboarding Enforcement Gate)" >&2
            exit 2
        fi
    else
        # All onboarding tasks done (or none exist) — write marker for fast path
        mkdir -p "$(dirname "$ONBOARDING_MARKER")"
        echo "completed: $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$ONBOARDING_MARKER"
    fi
fi

# --- Inception awareness ---
# If the active task is inception type with no decision, warn (don't block)
# ACTIVE_FILE already resolved above
if [ -n "$ACTIVE_FILE" ] && grep -q "^workflow_type: inception" "$ACTIVE_FILE" 2>/dev/null; then
    if ! grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$ACTIVE_FILE" 2>/dev/null; then
        echo "NOTE: Active task $CURRENT_TASK is inception (no decision yet)." >&2
        echo "  Ensure you are doing exploration, not building." >&2
    fi
fi

# --- Inception Open Questions readiness gate (T-2194, G-067) ---
# Filing-time mirror of G-020 for inceptions: if the active inception has a
# ## Open Questions section but ZERO filed `- **IW-N:**` entries, source-file
# Write/Edit is blocked. The task file itself is `.tasks/*` exempt above, so
# the agent can still add questions to unblock. Grandfather: inceptions with
# no Open Questions section at all pass through (older inceptions pre-T-2190).
# Bypass: FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1 (logged Tier-2).
if [ -n "$ACTIVE_FILE" ] && grep -q "^workflow_type: inception" "$ACTIVE_FILE" 2>/dev/null; then
    # Only check if the section exists at all (grandfather older inceptions)
    if grep -q "^## Open Questions" "$ACTIVE_FILE" 2>/dev/null; then
        # Extract Open Questions section content (between header and next ## heading)
        OQ_SECTION=$(awk '/^## Open Questions/{f=1; next} /^## /{f=0} f' "$ACTIVE_FILE" 2>/dev/null)
        # Strip HTML comments so the template guidance does not count.
        # T-2554: minimal match to first '-->' — tolerates '>' inside the comment.
        OQ_STRIPPED=$(echo "$OQ_SECTION" | sed -E 's/<!--([^-]|-[^-]|--[^>])*-->//g' | sed '/<!--/,/-->/d')
        # Count real IW-N entries
        HAS_IW=$(echo "$OQ_STRIPPED" | grep -cE '^\s*-\s*\*\*IW-[0-9]+:' 2>/dev/null || true)
        if [ "${HAS_IW:-0}" -eq 0 ]; then
            if [ "${FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT:-0}" = "1" ]; then
                # Bypass — log Tier-2
                LOG_DIR="$PROJECT_ROOT/.context/working"
                mkdir -p "$LOG_DIR" 2>/dev/null || true
                LOG_FILE="$LOG_DIR/.gate-bypass-log.yaml"
                _ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                {
                    echo "- timestamp: '$_ts'"
                    echo "  task: '$CURRENT_TASK'"
                    echo "  flag: 'FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT'"
                    echo "  caller: 'check-active-task:inception-open-questions'"
                    echo "  file: '$FILE_PATH'"
                } >> "$LOG_FILE" 2>/dev/null || true
                echo "NOTE: Inception $CURRENT_TASK has no filed Open Questions; write allowed via FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1 — logged." >&2
            else
                echo "" >&2
                echo "BLOCKED: Inception $CURRENT_TASK has '## Open Questions' but zero filed questions." >&2
                echo "" >&2
                echo "Filing-time mirror of G-020 — inception build-readiness." >&2
                echo "Inception work cannot edit source files until at least one Open Question is declared." >&2
                echo "" >&2
                echo "To unblock:" >&2
                # T-629: name the surface. Remedies 1 and 2 are both task-file edits, and
                # `.tasks/*` IS exempt — via a FILE_PATH test that a Bash call cannot
                # satisfy, because it carries no file path. Stated bare, they read as
                # available from the shell; measured, every shell form is refused. Same
                # correction as G-020's remedy 1 (T-628), same reason, 25 lines apart.
                echo "  1. Edit $CURRENT_TASK with the Edit/Write tool and add at least one entry under '## Open Questions':" >&2
                echo "       - **IW-1: <question text>**" >&2
                echo "         confidence: 0-3" >&2
                echo "         disposition: answered|deferred|dissolved   # filled later" >&2
                echo "         rationale: <one-line evidence>              # filled later" >&2
                echo "" >&2
                echo "  2. Or remove the '## Open Questions' section entirely, also with the Edit/Write tool (grandfathered)." >&2
                echo "     (shell edits — sed -i, heredoc, redirect — are refused here: no FILE_PATH, so the .tasks/ exemption cannot apply)" >&2
                echo "" >&2
                echo "  3. Override (logged Tier 2):  FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1 <command>" >&2
                echo "" >&2
                # T-629: FILE_PATH is empty for every Bash call, so this line used to read
                # "Attempting to modify: " with nothing after it — a blank exactly where
                # the reader looks for the cause.
                if [ -n "$FILE_PATH" ]; then
                    echo "Attempting to modify: $FILE_PATH" >&2
                else
                    echo "Attempting to run (Bash): ${BASH_CMD:-<unknown>}" >&2
                fi
                echo "Policy: T-2194 / G-067 (Inception Open Questions readiness gate)" >&2
                echo "See: 050-Inceptions.md §Disposition Gate, CLAUDE.md §Inception Discipline" >&2
                exit 2
            fi
        fi
    fi
fi

# --- Build readiness gate (G-020, T-471) ---
# Build/refactor/test tasks must have real ACs before modifying source files.
# Placeholder ACs ([First criterion]) indicate the task was created from template
# but never scoped. This prevents building without acceptance criteria.
# Inception tasks have their own gate above; skip them here.
if [ -n "$ACTIVE_FILE" ]; then
    WORKFLOW_TYPE=$({ grep "^workflow_type:" "$ACTIVE_FILE" 2>/dev/null || true; } | head -1 | sed 's/workflow_type:[[:space:]]*//')
    case "$WORKFLOW_TYPE" in
        build|refactor|test|decommission)
            AC_SECTION=$(sed -n '/^## Acceptance Criteria/,/^## [^A]/p' "$ACTIVE_FILE" 2>/dev/null | sed '$d')
            HAS_PLACEHOLDER=$(echo "$AC_SECTION" | grep -ciE '\[(First|Second|Third|Fourth|Fifth) criterion\]' 2>/dev/null || true)
            REAL_AC_COUNT=$(echo "$AC_SECTION" | grep -cE '^\s*-\s*\[[ x]\]' 2>/dev/null || true)
            if [ "${HAS_PLACEHOLDER:-0}" -gt 0 ] || [ "${REAL_AC_COUNT:-0}" -eq 0 ]; then
                # T-628 — THE ESCAPE THIS GATE PRINTS MUST BE RUNNABLE FROM THE STATE IT PRINTS IT IN.
                #
                # Reported by 999-AEF (rail @775, their T-3216), reproduced by 577-CashWeb
                # (@776) and then here from inside the blocked state. Both printed remedies
                # are actions on `.tasks/`, and `.tasks/*` IS exempt — for Write/Edit, where
                # this hook has a FILE_PATH to test the exemption against. A Bash command has
                # no single file path, so the exemption cannot be evaluated on one of the two
                # surfaces this gate restricts, and every shell form of both remedies fell
                # through to the block. The gate then reprinted the command it had just refused.
                #
                # This is the SAME reasoning T-2052 already applied to the no-active-task gate
                # ~560 lines above: "they ESTABLISH the active task, so gating them on one is a
                # deadlock; the block message below even lists them as the unblock path." That
                # fix was never generalised to the sibling gates in this file. It is generalised
                # to this one now; the remaining sibling (G-067, inception open-questions) is
                # left alone deliberately — its remedy 1 is a task-file edit with no `fw` verb
                # to allowlist, so it needs the wording fix below, not an exemption.
                #
                # BOUNDED ON PURPOSE. Only the conversion of the CURRENTLY FOCUSED task is
                # admitted. `--type` on any other id stays blocked, so this cannot become a
                # route to retype an arbitrary task from inside a block. Write patterns are
                # re-tested rather than assumed absent: `… --type inception > /etc/x` is the
                # remedy plus a payload, and it is the payload that matters.
                if [ "$TOOL_NAME" = "Bash" ] && [ -n "${BASH_CMD:-}" ] \
                   && [[ "$BASH_CMD" =~ (^|[[:space:]]|/)fw[[:space:]]+task[[:space:]]+update[[:space:]]+"$CURRENT_TASK"[[:space:]]+--type[[:space:]] ]] \
                   && ! { type has_bash_write_pattern &>/dev/null && has_bash_write_pattern "$BASH_CMD"; }; then
                    echo "NOTE: G-020 is firing for $CURRENT_TASK; allowing its own prescribed conversion (T-628)." >&2
                    exit 0
                fi
                echo "" >&2
                echo "BLOCKED: Task $CURRENT_TASK is a $WORKFLOW_TYPE task with placeholder/missing ACs." >&2
                echo "" >&2
                echo "Build tasks require real acceptance criteria before editing source files." >&2
                echo "This prevents unscoped building. (G-020: Scope-Aware Task Gate)" >&2
                echo "" >&2
                echo "To unblock:" >&2
                # Surface-accurate wording (T-628). Remedy 1 was previously stated as a bare
                # "edit the task file", which reads as available from any surface. It is not:
                # for Bash there is no FILE_PATH, so the `.tasks/*` exemption cannot fire and
                # every shell form of the edit is refused. Saying so costs one clause and
                # saves an agent from concluding the gate is simply broken.
                echo "  1. Edit the task file with the Edit/Write tool: replace [First criterion] with real ACs" >&2
                echo "     (shell edits — sed -i, heredoc, redirect — are refused here: no FILE_PATH, so the .tasks/ exemption cannot apply)" >&2
                echo "  2. Or change to inception (allowed from this state, T-628):" >&2
                echo "     $(_fw_cmd) task update $CURRENT_TASK --type inception" >&2
                echo "" >&2
                # T-628: name the actual restricted call. FILE_PATH is empty for every Bash
                # invocation, so this line used to read "Attempting to modify: " with nothing
                # after it — a blank where the reader looks for the cause.
                if [ -n "$FILE_PATH" ]; then
                    echo "Attempting to modify: $FILE_PATH" >&2
                else
                    echo "Attempting to run (Bash): ${BASH_CMD:-<unknown>}" >&2
                fi
                echo "Policy: G-020 (Pickup message governance bypass prevention)" >&2
                exit 2
            fi
            ;;
    esac
fi

# --- Fabric awareness advisory (T-244) ---
# If the file is a registered fabric component with dependents, show a note.
# Advisory only — never blocks. Runs only for non-exempt paths.
if [ -n "$FILE_PATH" ] && [ -d "$FRAMEWORK_ROOT/.fabric/components" ]; then
    # Resolve relative path
    REL_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
    # Quick count: how many other cards reference this file?
    DEP_COUNT=$(python3 -c "
import os, glob, re
root = '$PROJECT_ROOT'
rel = '$REL_PATH'
cards_dir = os.path.join(root, '.fabric', 'components')
# Find this file's card to get its id/name
comp_id = comp_name = ''
for card in glob.glob(os.path.join(cards_dir, '*.yaml')):
    with open(card) as f:
        text = f.read()
    if f'location: {rel}' in text or f'id: {rel}' in text:
        for line in text.split('\n'):
            if line.startswith('id: '): comp_id = line[4:].strip()
            if line.startswith('name: '): comp_name = line[6:].strip()
        break
if not comp_id:
    print(0)
else:
    # Count cards that reference this component
    count = 0
    patterns = [comp_id, comp_name, rel]
    for card in glob.glob(os.path.join(cards_dir, '*.yaml')):
        with open(card) as f:
            text = f.read()
        if f'id: {comp_id}' in text:
            continue  # skip self
        if any(f'target: {p}' in text or f'target: \"{p}\"' in text for p in patterns if p):
            count += 1
    print(count)
" 2>/dev/null || echo 0)
    if [ "$DEP_COUNT" -gt 0 ]; then
        echo "FABRIC: $REL_PATH has $DEP_COUNT downstream dependent(s). Consider: $(_fw_cmd) fabric blast-radius after commit." >&2
    fi
fi

# Active task exists — allow
exit 0
