#!/usr/bin/env bash
# runme-launcher.sh — the operator's one command, as ONE reviewed launcher (832 T-1055, from the
# T-1054 decision, operator 2026-10-05: option 3).
#
# The operator always types:   bash /opt/832-Workflow-designer/runme.sh   (runme.sh execs this)
#
# WHY: until T-1055 the agent hand-wrote runme.sh per job, re-implementing preflight, y/N prompts,
# logging and signals each time, in the one file the operator runs without reading. An external
# panel (consult t1054-runme-path, 5/5) and a real incident (a second agent copy rewrote runme.sh
# while the operator had been told a different job was waiting, T-1052) showed the safeguards were
# in the wrong place. Now they live HERE, once, tested (tests/test_t1055_runme_launcher.py), and the
# agent writes only a job: data, never safety code.
#
# A JOB is .context/runme/<NNN>-<name>/job.sh. It only DEFINES things (refused otherwise):
#     JOB_TITLE="Upgrade AEF to 1.8.2"      JOB_TASK="T-1049"
#     JOB_WHY="one or more lines the operator reads before anything runs"
#     preflight() { check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'; }
#     steps()     { step "Run the upgrade" 'run_upgrade'; step "Commit it" 'git commit ...'; }
#     steps()     { ...; step_outward "Push the tag" 'git push origin "$TAG"'; }   # acts outside the repo
#     run_upgrade() { ... }               # helper functions are fine; they run only inside a step
# Scaffold one with:  bash tools/runme-new.sh <name>
#
# THE SAFEGUARDS (all here, none in the job):
#   --dry-run [name]  the agent's rehearsal: loads the job, runs every check, prints the plan, then
#                     (T-1286) REHEARSES the steps: clones the committed HEAD into .context/rehearse/<job>/repo,
#                     copies in this repo's .git/hooks and the job dir, and runs the checks and then every `step`
#                     there (cwd = clone, PROJECT_ROOT/CONTEXT_DIR/TASKS_DIR unset), so a gate that refuses a step
#                     refuses it here, before the operator sees the job. A `step_outward` (push, tag push, /etc,
#                     model or reviewer calls, host services) is listed, never run. The clone is removed, the real
#                     repo is asserted unchanged (HEAD, refs, index, working tree, hooks). Only when all of that
#                     passes: records the job's sha256 in dryrun.ok and makes job.sh read-only.
#   real run          lists pending jobs; when several, the operator picks one or a BATCH in their own order
#                     (T-1227: arrow keys + space on a terminal, or typed: 3,1,2 / x = all), shows name + sha + dry-run
#                     time, REFUSES a job with no dry-run or changed since it, re-runs the checks,
#                     asks y/N (from the terminal only, typeahead discarded) before EVERY step,
#                     logs to the job dir, signals the agent (runme-signal.sh: events + topic, so
#                     tools/runme-watch.sh wakes it), and writes `done`. A done job never runs again.
#   retired           (T-1112) a `retired` file in the job dir (its text = the reason) takes a superseded
#                     job out of the queue without claiming it completed: never offered, never run.
#   menu / --list     (T-1112) one line per job: name, title, state (ready / CHANGED since dry-run /
#                     NOT REHEARSED) and last outcome (never run / completed / STOPPED: <reason>, when).
#
#   bash runme.sh [--dry-run [name]] [--list [--all]]
#   exit 0 = done / nothing to do; 1 = stopped or refused (the reason is printed and logged)
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REAL_JOBS="$PROJ/.context/runme"
JOBS="${RUNME_JOBS_DIR:-$REAL_JOBS}"
TTY=/dev/tty
if [ -n "${RUNME_TTY:-}" ]; then
    # Answers from a file exist for the test only. On the real job directory they would let a
    # script answer the operator's prompts, which is exactly what this launcher exists to prevent.
    # realpath -m: compare the paths even when the job dir does not exist yet (a cd-based check
    # passed silently on a fresh project — found by the test, leg 11).
    [ "$(realpath -m "$JOBS")" != "$(realpath -m "$REAL_JOBS")" ] || { echo "REFUSED: RUNME_TTY is for tests only, never on $REAL_JOBS"; exit 1; }
    TTY=$RUNME_TTY
fi
# T-1286: the repo a dry-run rehearses against. Another repo (a fixture with its own hooks) is for tests only.
REPO=$PROJ
if [ -n "${RUNME_REPO:-}" ]; then
    [ "$(realpath -m "$JOBS")" != "$(realpath -m "$REAL_JOBS")" ] || { echo "REFUSED: RUNME_REPO is for tests only, never on $REAL_JOBS"; exit 1; }
    REPO=$(realpath -m "$RUNME_REPO")
fi
REHEARSE_ROOT="$PROJ/.context/rehearse"

say()  { printf '%s\n' "$*"; }
fail() { say "STOPPED: $*"; exit 1; }

# ---------------------------------------------------------------- job loading
CHECK_T=(); CHECK_C=(); STEP_T=(); STEP_C=(); STEP_O=(); declare -A FN_BODY=()

job_sha() { sha256sum "$1/job.sh" | cut -c1-64; }

load_job() {  # load_job <dir>  — refuses anything but a definitions-only job
    local d=$1 f=$1/job.sh probe
    [ -f "$f" ] || fail "no job.sh in $d"
    bash -n "$f" 2>/dev/null || fail "$(basename "$d")/job.sh does not parse (bash -n)"
    # Load-time side effects: source it with NO usable PATH. A job that only defines things loads
    # silently; one that runs an external command at load time reports "command not found".
    probe=$(env -i PATH=/nonexistent HOME=/nonexistent "$BASH" --norc --noprofile -c \
        'check(){ :; }; step(){ :; }; step_outward(){ :; }; source "$1"' _ "$f" 2>&1)
    if grep -q 'command not found\|No such file' <<<"$probe"; then
        fail "$(basename "$d")/job.sh runs a command when it is loaded; a job may only define JOB_* variables and functions ($(head -1 <<<"$probe"))"
    fi
    # T-1231 (AEF T-4470 review, finding 1): the job is NEVER sourced in this shell. Sourced here, a job could
    # define confirm() { return 0; } (or ask, fail, say ...) and every y/N below would pass unasked. A child bash
    # sources it and only DECLARES: it prints the title, task, why and each registered check and step as
    # NUL-separated records, which this shell reads as data. Whatever the job defines dies with that child.
    JOB_FILE=$f
    JOB_TITLE=""; JOB_TASK=""; JOB_WHY=""
    CHECK_T=(); CHECK_C=(); STEP_T=(); STEP_C=(); STEP_O=(); FN_BODY=()
    local kind a b has_steps=0
    while IFS= read -r -d '' kind; do
        case "$kind" in
            T) IFS= read -r -d '' JOB_TITLE ;;
            K) IFS= read -r -d '' JOB_TASK ;;
            W) IFS= read -r -d '' JOB_WHY ;;
            N) has_steps=1 ;;
            C) IFS= read -r -d '' a; IFS= read -r -d '' b; CHECK_T+=("$a"); CHECK_C+=("$b") ;;
            S|O) IFS= read -r -d '' a; IFS= read -r -d '' b; STEP_T+=("$a"); STEP_C+=("$b")
                 [ "$kind" = O ] && STEP_O+=(1) || STEP_O+=(0) ;;
            F) IFS= read -r -d '' a; IFS= read -r -d '' b; FN_BODY[$a]=$b ;;
        esac
    done < <("$BASH" --norc --noprofile -c '
        exec 4>&1 1>/dev/null      # records go to fd 4 only, so nothing the job prints can forge one
        check() { builtin printf "C\0%s\0%s\0" "$1" "$2" >&4; }
        step()  { builtin printf "S\0%s\0%s\0" "$1" "$2" >&4; }
        step_outward() { builtin printf "O\0%s\0%s\0" "$1" "$2" >&4; }   # T-1286: a step that acts outside the repo
        __pre=" $(compgen -A function | tr "\n" " ") "
        source "$1" || exit 97
        for __f in $(compgen -A function); do   # T-1234: the body of every function the JOB defines
            case "$__pre" in *" $__f "*) continue ;; esac
            builtin printf "F\0%s\0%s\0" "$__f" "$(declare -f "$__f")" >&4
        done
        builtin printf "T\0%s\0K\0%s\0W\0%s\0" "${JOB_TITLE:-}" "${JOB_TASK:-}" "${JOB_WHY:-}" >&4
        declare -F steps >/dev/null || exit 0
        builtin printf "N\0" >&4
        declare -F preflight >/dev/null && preflight
        steps' _ "$f" </dev/null 3<&- 2>/dev/null)
    [ -n "$JOB_TITLE" ] || fail "$(basename "$d")/job.sh sets no JOB_TITLE"
    [ "$has_steps" = 1 ] || fail "$(basename "$d")/job.sh defines no steps()"
    [ "${#STEP_T[@]}" -gt 0 ] || fail "$(basename "$d")/job.sh steps() registers no step"
}

job_shell() {  # job_shell <command>: runs one check or step in a child bash that sources the job (so its helpers
    # work), never in this shell, and with the answers fd (3) closed, so a step cannot read the operator's answers
    "$BASH" --norc --noprofile -c 'check() { :; }; step() { :; }; step_outward() { :; }; source "$1" || exit 97; eval "$2"' _ "$JOB_FILE" "$1" 3<&-
}

step_code() {  # step_code <command>: T-1234 (AEF T-4470 finding 4): print the body of every job function the command
    # reaches, transitively, each once, so the operator confirms the code that runs, not only a helper's name
    local todo=("$1") seen=" " text w
    while [ "${#todo[@]}" -gt 0 ]; do
        text=${todo[0]}; todo=("${todo[@]:1}")
        for w in $(printf '%s\n' "$text" | tr -c 'A-Za-z0-9_' ' '); do
            [ -n "${FN_BODY[$w]+x}" ] || continue
            case "$seen" in *" $w "*) continue ;; esac
            seen="$seen$w "
            printf '%s\n' "${FN_BODY[$w]}" | sed 's/^/        | /'
            todo+=("${FN_BODY[$w]}")
        done
    done
}

run_checks() {  # every check runs; any failure fails the whole preflight
    local i bad=0
    for i in "${!CHECK_T[@]}"; do
        if (cd "$PROJ" && job_shell "${CHECK_C[$i]}") >/dev/null 2>&1; then
            say "ok    ${CHECK_T[$i]}"
        else
            say "FAIL  ${CHECK_T[$i]}"; bad=1
        fi
    done
    [ "${#CHECK_T[@]}" -gt 0 ] || say "(this job declares no preflight checks)"
    return $bad
}

show_plan() {
    local i
    say "Job:   $(basename "$1")   ${JOB_TASK:+($JOB_TASK)}"
    say "What:  $JOB_TITLE"
    [ -n "${JOB_WHY:-}" ] && sed 's/^/       /' <<<"$JOB_WHY"
    say "Steps (each asks y/N first):"
    for i in "${!STEP_T[@]}"; do say "  $((i + 1)). ${STEP_T[$i]}$([ "${STEP_O[$i]}" = 1 ] && printf ' (outward)')"; done
}

# ---------------------------------------------------------------- rehearsal (T-1286)
# The dry-run used to run only the checks, so a gate that refuses a STEP (commit gates, inception decide, sovereignty,
# foreign-delete) was first met by the operator: 7 of 22 retired jobs died that way (docs/reports/T-1285-quality-engine.md,
# spike 1). Now the steps run first in a throwaway clone of HEAD with this repo's hooks, and the real repo is asserted
# untouched afterwards.
REHEARSE_DIR=""; REHEARSE_PID=""; REHEARSE_GUARDED=0

repo_state() {  # one labelled line per part of the real repo a rehearsal must leave alone; the porcelain lines last
    local hooks
    hooks=$(cd "$REPO" && cd "$(git rev-parse --git-path hooks)" 2>/dev/null && pwd)
    printf 'HEAD           %s\n' "$(git -C "$REPO" rev-parse -q --verify HEAD)"
    printf 'refs           %s\n' "$(git -C "$REPO" for-each-ref | sha256sum | cut -c1-64)"
    printf 'index          %s\n' "$(git -C "$REPO" ls-files --stage | sha256sum | cut -c1-64)"
    git -C "$REPO" diff --cached --quiet; printf 'staged         rc=%s\n' "$?"
    printf 'hooks          %s\n' "$( (cd "$hooks" 2>/dev/null && find . -type f -print0 | sort -z | xargs -0r sha256sum) | sha256sum | cut -c1-64)"
    # T-1298: the repo's own config (remotes, push urls), and the project's when it is another repo: a git command whose
    # clone had vanished walked up from .context/rehearse/ into the project's repo and rewrote its push url unseen.
    git -C "$REPO" config --local --list 2>/dev/null | sed 's/^/config         /'
    [ "$(realpath "$PROJ")" = "$(realpath "$REPO")" ] || git -C "$PROJ" config --local --list 2>/dev/null | sed 's/^/project config /'
    git -C "$REPO" status --porcelain | sed 's/^/status         /'
    # the bytes of every tracked file that differs from HEAD, one line each, so a mismatch names the file
    (cd "$REPO" && git diff HEAD --name-only -z | xargs -0r sha256sum 2>&1) | sed 's/^/edited         /'
}

rehearse_cleanup() {  # stop a step still running (its whole process group) and remove the clone
    if [ -n "${REHEARSE_PID:-}" ]; then
        kill -TERM -- "-$REHEARSE_PID" 2>/dev/null; wait "$REHEARSE_PID" 2>/dev/null; REHEARSE_PID=""
    fi
    case "${REHEARSE_DIR:-}" in
        "$REHEARSE_ROOT"/?*)
            [ -e "$REHEARSE_DIR" ] || return 0
            rm -rf "$REHEARSE_DIR" 2>/dev/null || { chmod -R u+w "$REHEARSE_DIR" 2>/dev/null; rm -rf "$REHEARSE_DIR"; }
            [ ! -e "$REHEARSE_DIR" ] || say "WARNING: could not remove $REHEARSE_DIR" ;;
    esac
}

# The guard: in a private mount namespace the project and the real repo are read-only and only the clone is writable,
# so a step that reaches the real repo (an absolute path, a tool that resolves the real root) fails HERE, by
# construction. Measured on 2026-10-24: other sessions change this tree every few seconds (hook counters, their own
# edits), so a before/after compare alone cannot tell their writes from the rehearsal's. Needs unshare + root; without
# it the compare is the only guard and any change fails the dry-run. RUNME_REHEARSE_NO_GUARD=1: tests only.
rehearse_guard() {
    [ "${RUNME_REHEARSE_NO_GUARD:-}" = 1 ] && [ "$(realpath -m "$JOBS")" != "$(realpath -m "$REAL_JOBS")" ] && return 1
    unshare --mount --propagation private true 2>/dev/null
}

rehearse_run() {  # rehearse_run <clone> <job.sh in it> <command> <output file>: one check or step, cwd at the clone, the
    # project pointers unset, no stdin, no fd 3, in its own process group so an interrupt stops it whole. Backgrounded and
    # waited for, so INT/TERM reach the trap at once instead of after the step.
    # T-1298: GIT_CEILING_DIRECTORIES stops git's repo discovery at the clone, so a step whose clone lost its .git fails
    # instead of finding the project's repo above it.
    local inner='cd "$C" && exec setsid env -u PROJECT_ROOT -u CONTEXT_DIR -u TASKS_DIR GIT_CEILING_DIRECTORIES="$(dirname "$C")" "$BASH" --norc --noprofile -c \
        '"'"'check() { :; }; step() { :; }; step_outward() { :; }; source "$1" || exit 97; eval "$2"'"'"' _ "$J" "$X"'
    if [ "$REHEARSE_GUARDED" = 1 ]; then
        # T-1288: a TMPDIR inside the project (the core suite tier's short .context/st) is scratch, not the project:
        # it stays writable like the clone, or every step that makes a temp file there fails under the guard.
        inner='for r in "$P" "$R"; do mount --bind "$r" "$r" && mount -o remount,bind,ro "$r" || exit 98; done
        mount --bind "$C" "$C" && mount -o remount,bind,rw "$C" || exit 98
        case "$T" in "$P"/?*) [ -d "$T" ] && { mount --bind "$T" "$T" && mount -o remount,bind,rw "$T" || exit 98; } ;; esac
        '"$inner"
        ( cd "$1" && C=$1 J=$2 X=$3 P=$PROJ R=$REPO T=$(realpath -m "${TMPDIR:-/tmp}") exec unshare --mount --propagation private "$BASH" --norc --noprofile -c "$inner" ) \
            </dev/null >"$4" 2>&1 3<&- 9<&- &
    else
        ( C=$1 J=$2 X=$3 exec "$BASH" --norc --noprofile -c "$inner" ) </dev/null >"$4" 2>&1 3<&- 9<&- &
    fi
    REHEARSE_PID=$!
    wait "$REHEARSE_PID"; local rc=$?
    REHEARSE_PID=""
    return $rc
}

rehearse() {  # rehearse <job dir>: 0 when the checks and every non-outward step pass in the clone and the real repo is unchanged
    # T-1298: the clone's place is .context/rehearse/<job name>, shared by every launcher on this project (two suite runs
    # rehearse the same fixture names), and each rehearsal starts by removing what is there. A lock per name (fd 9,
    # closed for the steps) serialises them, so one never removes or writes through another's clone.
    local job rc
    job=$(basename "$1")
    REHEARSE_DIR=""   # the EXIT trap removes REHEARSE_DIR: never one this process does not hold the lock for
    mkdir -p "$REHEARSE_ROOT" || { say "FAIL  cannot create $REHEARSE_ROOT"; return 1; }
    exec 9>"$REHEARSE_ROOT/.lock-$job" || { say "FAIL  cannot open the rehearsal lock for $job"; return 1; }
    if ! flock -w 900 9; then
        exec 9>&-
        say "FAIL  another rehearsal of $job has held ${REHEARSE_ROOT#"$PROJ"/}/$job for 15 minutes; not rehearsed"
        return 1
    fi
    rehearse_locked "$1"; rc=$?
    rehearse_cleanup; REHEARSE_DIR=""
    exec 9>&-
    return $rc
}

rehearse_locked() {
    local d=$1 job rel rd rr clone cjob hooks url out before after i n rc bad=0
    job=$(basename "$d")
    REHEARSE_DIR="$REHEARSE_ROOT/$job"; clone="$REHEARSE_DIR/repo"; out="$REHEARSE_DIR/step.out"
    rehearse_cleanup                                     # a clone left by a killed run
    mkdir -p "$REHEARSE_DIR" || { say "FAIL  cannot create $REHEARSE_DIR"; return 1; }
    before=$(repo_state)
    REHEARSE_GUARDED=0; rehearse_guard && REHEARSE_GUARDED=1
    say "Rehearsal: the steps run in a clone of HEAD $(git -C "$REPO" rev-parse --short HEAD) with this repo's hooks (${clone#"$PROJ"/});" \
        "$([ "$REHEARSE_GUARDED" = 1 ] && echo "the real repo is read-only to them" || echo "NO read-only guard on this host: the before/after compare decides")"
    git clone --quiet --no-hardlinks "$REPO" "$clone" 2>"$out" || { say "FAIL  git clone"; sed 's/^/  | /' "$out"; rehearse_cleanup; return 1; }
    # T-1298: every write to the clone names its git dir: `git -C "$clone"` on a clone without .git would find the repo
    # ABOVE it (the project's: the clone lives inside it) and write there.
    if [ "$(git --git-dir="$clone/.git" rev-parse --absolute-git-dir 2>/dev/null)" != "$(realpath -m "$clone/.git")" ]; then
        say "FAIL  the clone at ${clone#"$PROJ"/} is not a repo of its own; nothing written, not rehearsed"; rehearse_cleanup; return 1
    fi
    hooks=$(cd "$REPO" && cd "$(git rev-parse --git-path hooks)" 2>/dev/null && pwd)
    [ -n "$hooks" ] && cp -pR "$hooks/." "$clone/.git/hooks/"
    # A push in a rehearsal must never land anywhere: the clone's origin would be the real repo (a tag pushed there is
    # a real tag). Fetch keeps the real origin, so a check that reads it sees what the operator's run will see.
    if url=$(git -C "$REPO" remote get-url origin 2>/dev/null); then
        git --git-dir="$clone/.git" remote set-url origin "$url" || { say "FAIL  cannot set the clone's origin"; rehearse_cleanup; return 1; }
    fi
    git --git-dir="$clone/.git" remote set-url --push origin /dev/null/rehearsal-refuses-every-push--declare-it-step_outward \
        || { say "FAIL  cannot make the clone refuse pushes; not rehearsed"; rehearse_cleanup; return 1; }
    rd=$(realpath "$d"); rr=$(realpath "$REPO")
    case "$rd/" in "$rr"/*) rel=${rd#"$rr"/} ;; *) rel=".context/runme/$job" ;; esac
    rm -rf "${clone:?}/$rel"; mkdir -p "$clone/$(dirname "$rel")"; cp -pR "$d" "$clone/$rel"
    git -C "$clone" ls-files --error-unmatch "$rel/job.sh" >/dev/null 2>&1 || printf '/%s/\n' "$rel" >> "$clone/.git/info/exclude"
    cjob="$clone/$rel/job.sh"
    for i in "${!CHECK_T[@]}"; do
        if rehearse_run "$clone" "$cjob" "${CHECK_C[$i]}" "$out"; then
            say "ok    check   ${CHECK_T[$i]}"
        else
            say "FAIL  check   ${CHECK_T[$i]} — fails in the clone (it passes here: does it need something uncommitted?)"
            sed 's/^/  | /' "$out"; bad=1; break
        fi
    done
    n=${#STEP_T[@]}
    for i in "${!STEP_T[@]}"; do
        [ "$bad" = 0 ] || break
        if [ "${STEP_O[$i]}" = 1 ]; then
            say "skip  step $((i + 1))/$n: ${STEP_T[$i]} — not rehearsed: acts outside the repo"; continue
        fi
        if rehearse_run "$clone" "$cjob" "${STEP_C[$i]}" "$out"; then
            say "ok    step $((i + 1))/$n: ${STEP_T[$i]}"
        else
            rc=$?
            say "FAIL  step $((i + 1))/$n: ${STEP_T[$i]} (rc=$rc); later steps not rehearsed"
            say "  runs: ${STEP_C[$i]}"
            sed 's/^/  | /' "$out"; bad=1
        fi
    done
    rehearse_cleanup; REHEARSE_DIR=""
    after=$(repo_state)
    if [ "$before" = "$after" ]; then
        say "ok    real repo unchanged: HEAD, refs, index, working tree, .git/hooks"
    elif [ "$REHEARSE_GUARDED" = 1 ]; then
        say "WARN  the real repo changed during the rehearsal, NOT by it (it saw the repo read-only): another session. Before (-) / after (+):"
        diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | command grep '^[<>]' | sed 's/^</  -/; s/^>/  +/'
    else
        say "FAIL  THE REHEARSAL CHANGED THE REAL REPO ($REPO); it must touch only its clone. Before (-) / after (+):"
        diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | command grep '^[<>]' | sed 's/^</  -/; s/^>/  +/'
        say "  (a step reached outside the clone, e.g. by an absolute path; or another session changed the repo meanwhile:"
        say "   this host has no mount-namespace guard, so the two cannot be told apart)"
        bad=1
    fi
    return $bad
}

pending() {  # job dirs with a job.sh and no done or retired marker, in number order
    local d
    for d in "$JOBS"/*/; do
        d=${d%/}
        [ -f "$d/job.sh" ] && [ ! -f "$d/done" ] && [ ! -f "$d/retired" ] && echo "$d"
    done 2>/dev/null | sort
}

# T-1112: what the operator needs to choose well, read WITHOUT running the job (sed, never source).
job_state() {
    local d=$1
    [ -f "$d/dryrun.ok" ] || { echo "NOT REHEARSED"; return; }
    [ "$(sed -n 's/^sha=//p' "$d/dryrun.ok")" = "$(job_sha "$d")" ] && echo "ready" || echo "CHANGED since dry-run"
}
job_title() { sed -n 's/^JOB_TITLE="\(.*\)"$/\1/p' "$1/job.sh" | head -1; }
last_outcome() {  # never run | completed <when> | STOPPED <when>: <reason>
    local d=$1 log ts when line why
    log=$(ls -1 "$d"/run-*.log 2>/dev/null | sort | tail -1)
    [ -n "$log" ] || { echo "never run"; return; }
    ts=${log##*/run-}; ts=${ts%.log}
    when="${ts:4:2}-${ts:6:2} ${ts:9:2}:${ts:11:2}"
    if grep -q '^DONE: ' "$log"; then echo "completed $when"; return; fi
    line=$(grep '^STOPPED: ' "$log" | tail -1); line=${line#STOPPED: }
    # a failed step prints its own reason on the line above (after the y/N prompt)
    why=$(grep -B1 '^STOPPED: ' "$log" | tail -2 | head -1 | sed 's/^Run step [0-9]*\/[0-9]*? \[y\/N\] //')
    case "$line" in step*failed*) [ -n "$why" ] && line="$line — $why" ;; esac
    echo "STOPPED $when: ${line:-no outcome recorded (run interrupted?)}"
}
job_line() { local d=$1 t; t=$(job_title "$d"); echo "$(basename "$d")${t:+ — $t}  [$(job_state "$d"); last: $(last_outcome "$d")]"; }

# ---------------------------------------------------------------- terminal answers
open_tty() { exec 3<"$TTY" || fail "cannot read answers from $TTY (run this in a terminal)"; }
ask() {  # ask <prompt> -> REPLY ; discards typeahead from a real terminal first
    local _junk
    if [ "$TTY" = /dev/tty ]; then
        while read -r -t 0.05 -n 10000 _junk <&3 2>/dev/null; do :; done
    fi
    printf '%s ' "$1"
    REPLY=""; read -r REPLY <&3 || REPLY=""
    [ "$TTY" = /dev/tty ] || say "$REPLY"   # echo test answers into the log
}
confirm() { ask "$1 [y/N]"; [ "$REPLY" = y ] || [ "$REPLY" = Y ]; }

# T-1227 (operator 2026-10-20): choose a batch with the arrow keys; T-1230 made it robust after the operator found it
# flaky. Up/down (or k/j) moves; space adds the highlighted job to the end of the order or takes it out; a digit 1-9
# puts it at that place (the others move along); 0 or Backspace takes it out; a = all in listed order; Enter runs the
# order (the highlighted job alone when nothing is chosen); t = type numbers instead; q or Esc stops. Every key
# repaints the whole menu, each line cut to the terminal width (T-1230: wrapped lines broke the in-place redraw),
# and arrows are read in both encodings, ESC [ A and ESC O A. Sets chosen=(); returns 2 for "type", 1 for stop.
use_picker() {
    case "${RUNME_PICKER:-}" in
        0) return 1 ;;
        1) return 0 ;;   # tests: keys fed as bytes through RUNME_TTY
    esac
    [ "$TTY" = /dev/tty ] && [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]
}
pick_jobs() {
    local n=${#todo[@]} cur=0 i k rest pos cols lines=() order=() new _junk real=0 rc
    [ "$TTY" = /dev/tty ] && real=1
    cols=${RUNME_COLS:-}
    [ -n "$cols" ] || cols=$(stty size <&3 2>/dev/null | awk '{print $2}')
    [ "${cols:-0}" -ge 40 ] 2>/dev/null || cols=100
    for i in "${!todo[@]}"; do
        lines+=("$(basename "${todo[$i]}")  [$(job_state "${todo[$i]}"); last: $(last_outcome "${todo[$i]}")]  $(job_title "${todo[$i]}")")
    done
    if [ "$real" = 1 ]; then
        while read -r -t 0.05 -n 10000 _junk <&3 2>/dev/null; do :; done
        printf '\033[?25l'
        trap 'printf "\033[?25h\n"; exit 130' INT
    fi
    draw() {
        local row
        [ "$real" = 1 ] && printf '\033[H\033[J'
        say "Pending jobs - choose the batch and its order:"
        say "  up/down move    space add/remove    1-9 put it at that place    0 remove"
        say "  a all           Enter run           t type numbers instead      q stop"
        say
        for i in "${!todo[@]}"; do
            pos=" "
            for k in "${!order[@]}"; do [ "${order[$k]}" = "$i" ] && pos=$((k + 1)); done
            [ "$i" = "$cur" ] && row="> " || row="  "
            row=$(printf '%s[%s] %d. %s' "$row" "$pos" "$((i + 1))" "${lines[$i]}")
            say "${row:0:$((cols - 1))}"
        done
        say
        if [ "${#order[@]}" -gt 0 ]; then
            say "Batch, in this order: $(for i in "${order[@]}"; do printf '%d ' "$((i + 1))"; done)"
        else
            say "Batch: nothing chosen yet (Enter runs the highlighted job alone)"
        fi
    }
    put_at() {  # put_at <place, 0 = remove> : the highlighted job leaves the order, then goes in at that place
        new=(); for i in "${order[@]}"; do [ "$i" = "$cur" ] || new+=("$i"); done
        if [ "$1" -gt 0 ]; then
            k=$(( $1 - 1 )); [ "$k" -gt "${#new[@]}" ] && k=${#new[@]}
            new=("${new[@]:0:$k}" "$cur" "${new[@]:$k}")
        fi
        order=("${new[@]}")
    }
    picker_done() { [ "$real" = 1 ] && { printf '\033[?25h'; trap - INT; }; return "$1"; }
    draw
    while :; do
        IFS= read -rsn1 -d '' k <&3 || { picker_done 1; return; }
        if [ "$k" = $'\033' ]; then
            rest=""; IFS= read -rsn2 -t 0.3 -d '' rest <&3
            case "$rest" in
                '[A'|'OA') k=up ;;
                '[B'|'OB') k=down ;;
                '') picker_done 1; return ;;   # Esc alone
                *) continue ;;                 # other keys (left/right, F-keys): ignored
            esac
        fi
        case "$k" in
            up|k)   [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
            down|j) [ "$cur" -lt $((n - 1)) ] && cur=$((cur + 1)) ;;
            ' ')    pos=0; for i in "${order[@]}"; do [ "$i" = "$cur" ] && pos=1; done
                    if [ "$pos" = 1 ]; then put_at 0; else put_at $(( ${#order[@]} + 1 )); fi ;;
            [1-9])  put_at "$k" ;;
            0|$'\177'|$'\b') put_at 0 ;;
            a|A)    order=(); for i in "${!todo[@]}"; do order+=("$i"); done ;;
            $'\n'|$'\r')
                    [ "${#order[@]}" -gt 0 ] || order=("$cur")
                    chosen=(); for i in "${order[@]}"; do chosen+=("${todo[$i]}"); done
                    say "Chosen, in this order: $(for i in "${order[@]}"; do printf '%d ' "$((i + 1))"; done)"
                    picker_done 0; return ;;
            t|T)    picker_done 2; return ;;
            q|Q)    picker_done 1; return ;;
            *)      continue ;;
        esac
        draw
    done
}

# T-1227: the typed form. "x" (or all) runs every pending job in this order; "3,1,2" (or "3 1 2", "3, 1") runs exactly
# those, in the order typed; one number runs that job alone. Each job still asks y/N per step.
type_jobs() {
    local i p sel seen picks
    say "Pending jobs:"
    for i in "${!todo[@]}"; do say "  $((i + 1)). $(job_line "${todo[$i]}")"; done
    ask "Which job? [1-${#todo[@]}; several in your order, e.g. 3,1,2; x = all in this order; anything else = stop]"
    sel=$(tr 'A-Z' 'a-z' <<<"$REPLY" | sed -E 's/[[:space:];,]+/,/g; s/^,+//; s/,+$//')
    chosen=()
    if [ "$sel" = x ] || [ "$sel" = all ] || [ "$sel" = '*' ]; then
        chosen=("${todo[@]}")
    elif [[ "$sel" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        IFS=, read -ra picks <<<"$sel"
        seen=" "
        for p in "${picks[@]}"; do
            p=$((10#$p))
            { [ "$p" -ge 1 ] && [ "$p" -le "${#todo[@]}" ]; } || fail "there is no job $p in the list; nothing run"
            case "$seen" in *" $p "*) fail "job $p was chosen twice; nothing run" ;; esac
            seen="$seen$p "; chosen+=("${todo[$((p - 1))]}")
        done
    else
        fail "no job chosen; nothing run"
    fi
}

# ---------------------------------------------------------------- modes
mode=run; name=""
case "${1:-}" in
    --dry-run) mode=dry; name=${2:-} ;;
    --list)    mode=list; [ "${2:-}" = --all ] && mode=listall ;;
    "")        ;;
    -h|--help) sed -n '2,44p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)         fail "unknown argument: $1 (use --dry-run [name], --list [--all], or nothing)" ;;
esac

if [ "$mode" = list ]; then
    found=0
    while read -r d; do
        [ -n "$d" ] || continue; found=1
        say "$(job_line "$d")"
    done < <(pending)
    [ "$found" = 1 ] || say "no pending jobs"
    exit 0
fi
if [ "$mode" = listall ]; then   # every job, with done / retired named
    for d in $(ls -d "$JOBS"/*/ 2>/dev/null | sort); do
        d=${d%/}; [ -f "$d/job.sh" ] || continue
        if [ -f "$d/retired" ]; then say "$(basename "$d")  [RETIRED: $(head -1 "$d/retired")]"
        elif [ -f "$d/done" ]; then say "$(basename "$d")  [done]"
        else say "$(job_line "$d")"; fi
    done
    exit 0
fi

if [ "$mode" = dry ]; then
    mapfile -t todo < <(if [ -n "$name" ]; then ls -d "$JOBS"/*"$name"* 2>/dev/null; else pending; fi)
    [ "${#todo[@]}" -gt 0 ] || { say "dry-run: no pending job${name:+ matching '$name'}"; exit 0; }
    rc=0
    # T-1273: the EXIT trap removes the clone; INT/TERM/HUP EXIT (never return and resume the loop), which fires it.
    trap rehearse_cleanup EXIT
    trap 'exit 130' INT; trap 'exit 143' TERM; trap 'exit 129' HUP
    for d in "${todo[@]}"; do
        say "== DRY RUN $(basename "$d")"
        load_job "$d"
        show_plan "$d"
        if ! run_checks; then
            rm -f "$d/dryrun.ok"; rc=1
            say "dry-run FAILED: preflight did not pass; no dryrun.ok written."
            continue
        fi
        sha=$(job_sha "$d")
        if ! rehearse "$d"; then
            rm -f "$d/dryrun.ok"; rc=1
            say "dry-run FAILED: the rehearsal did not pass (above); no dryrun.ok written."
            continue
        fi
        [ "$(job_sha "$d")" = "$sha" ] || fail "$(basename "$d")/job.sh changed during its own rehearsal; no dryrun.ok written"
        chmod u+w "$d" 2>/dev/null
        printf 'sha=%s\nat=%s\n' "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$d/dryrun.ok"
        chmod a-w "$d/job.sh"
        say "dry-run passed: steps rehearsed in a clone (removed), job.sh sha ${sha:0:12} recorded, job.sh now read-only. Nothing ran here."
    done
    exit $rc
fi

# ---- real run
mapfile -t todo < <(pending)
[ "${#todo[@]}" -gt 0 ] || { say "Nothing to run: no pending job in $JOBS."; exit 0; }
open_tty
chosen=()
if [ "${#todo[@]}" -eq 1 ]; then
    chosen=("${todo[0]}")
else
    # The arrow-key picker on a real terminal (T-1227); typed numbers otherwise, or when the operator presses t.
    prc=2
    if use_picker; then pick_jobs; prc=$?; [ "$prc" = 1 ] && fail "no job chosen; nothing run"; fi
    [ "$prc" = 2 ] && type_jobs
fi

# T-1227: a batch is refused BEFORE anything runs when any chosen job is not rehearsed or changed since its dry run,
# so it can never stop half way for a reason that was knowable at the start.
if [ "${#chosen[@]}" -gt 1 ]; then
    bad=""
    for d in "${chosen[@]}"; do
        if [ ! -f "$d/dryrun.ok" ]; then bad="$bad $(basename "$d") (not rehearsed);"
        elif [ "$(sed -n 's/^sha=//p' "$d/dryrun.ok")" != "$(job_sha "$d")" ]; then bad="$bad $(basename "$d") (CHANGED since its dry-run);"; fi
    done
    if [ -n "$bad" ]; then
        . "$PROJ/tools/runme-signal.sh"; runme_signal STOPPED "batch refused:$bad"
        fail "batch refused before anything ran:$bad the agent must dry-run those jobs again."
    fi
    say "Batch of ${#chosen[@]}, in this order: $(for d in "${chosen[@]}"; do printf '%s ' "$(basename "$d")"; done)"
    say "Each job still asks y/N before every step; the batch stops at the first job that does not complete."
fi

run_one() {  # run_one <job dir> — one job, end to end; runs in a subshell so its own stop/exit ends only it
    local d=$1 sha dsha dat i n
    RUNME_RUN_ID="runme-$(date +%Y%m%dT%H%M%S)-$BASHPID"   # one id per job, also inside a batch
    # Log and signal BEFORE the refusals below, so a refused run still wakes the agent (STOPPED event).
    sha=$(job_sha "$d")
    TS=$(date +%Y%m%dT%H%M%S)
    LOG="$d/run-$TS.log"
    chmod u+w "$d" 2>/dev/null
    touch "$LOG" 2>/dev/null || fail "cannot write $LOG"
    exec > >(tee -a "$LOG") 2>&1
    . "$PROJ/tools/runme-signal.sh"
    runme_signal_init "$(basename "$d") [sha ${sha:0:12}]" "$LOG"

    [ -f "$d/dryrun.ok" ] || fail "$(basename "$d") has not been rehearsed (no dryrun.ok). Nothing run. The agent runs: bash runme.sh --dry-run $(basename "$d")"
    dsha=$(sed -n 's/^sha=//p' "$d/dryrun.ok"); dat=$(sed -n 's/^at=//p' "$d/dryrun.ok")
    [ "$sha" = "$dsha" ] || fail "$(basename "$d")/job.sh CHANGED since its dry-run (now ${sha:0:12}, rehearsed ${dsha:0:12}). Nothing run; the agent must dry-run it again."
    load_job "$d"
    # T-1204: steps sign with 832's own TermLink key (T-1203). A job can restart a daemon that then inherits this
    # shell's env: job 048's fw upgrade restarted the sidecar receiver on 2026-10-18 from a terminal without the
    # variable, and mail went out under the shared host key again. Exported only when the key file EXISTS: termlink
    # MINTS a key at a missing TERMLINK_IDENTITY_FILE path (T-1151), so a lost key unsets it instead.
    RUNME_KEY="${RUNME_IDENTITY_KEY:-$PROJ/.context/secrets/termlink-identity.key}"   # override: tests only
    if [ -f "$RUNME_KEY" ]; then export TERMLINK_IDENTITY_FILE="$RUNME_KEY"; else unset TERMLINK_IDENTITY_FILE; fi
    # T-1203: termlink >= 0.12.786 (010 T-3467) refuses to mint ANY key under this, the host key included; an
    # existing key loads as before. Set whatever the key file says, so no step can create an identity by accident.
    export TERMLINK_IDENTITY_NO_CREATE=1
    say "runme  $(basename "$d")   sha ${sha:0:12}   rehearsed $dat   log: $LOG"
    show_plan "$d"
    say
    run_checks || fail "preflight failed (state changed since the dry-run?); nothing run"
    n=${#STEP_T[@]}
    for i in "${!STEP_T[@]}"; do
        say
        say "Step $((i + 1))/$n: ${STEP_T[$i]}"
        say "  runs: ${STEP_C[$i]}"
        step_code "${STEP_C[$i]}"
        confirm "Run step $((i + 1))/$n?" || fail "not confirmed at step $((i + 1))/$n; steps before it ran, nothing after"
        runme_signal step "$((i + 1))/$n ${STEP_T[$i]}"
        (cd "$PROJ" && job_shell "${STEP_C[$i]}") || fail "step $((i + 1))/$n failed (rc=$?); later steps not run"
        say "ok    step $((i + 1))/$n"
    done
    chmod u+w "$d" 2>/dev/null
    printf 'at=%s\nsha=%s\nlog=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$sha" "$(basename "$LOG")" > "$d/done"
    say
    say "DONE: $(basename "$d") — all $n step(s) ran. rc=0  (log: $LOG)"
}

completed=(); rc=0; stopped=""
for d in "${chosen[@]}"; do
    ( run_one "$d" ); rc=$?
    if [ "$rc" -ne 0 ]; then stopped=$(basename "$d"); break; fi
    completed+=("$(basename "$d")")
done
if [ "${#chosen[@]}" -gt 1 ]; then
    sleep 0.2   # let the last job's log tee flush before the summary
    say
    say "BATCH: ${#completed[@]} of ${#chosen[@]} completed${completed[*]:+ (${completed[*]})}${stopped:+; STOPPED at $stopped, the rest not started}."
fi
exit $rc
