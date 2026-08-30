#!/bin/bash
# Safe-command allowlist for Bash task gate (T-650, T-630)
#
# is_bash_safe_command() returns 0 if the command is read-only/diagnostic
# and should be allowed without an active task.
#
# Design evidence: 7920 Bash invocations analyzed from real session data.
# Only 1.4% are file-writing operations. This allowlist catches the safe
# 98.6% for fast-path bypass.
#
# Categories (27 patterns):
#   1. Git read-only (8 patterns)
#   2. File reading (7 patterns)
#   3. Searching (4 patterns)
#   4. FW diagnostics (6 patterns)
#   5. System utilities (6 patterns)
#   6. Validation (2 patterns)

# T-405: a multi-line command is safe only if EVERY line is safe.
#
# The previous base extraction was `echo "$cmd" | awk '{print $1}'`, which on a
# multi-line command prints the first word of EVERY line — producing a
# multi-word "base" that matches no case arm. Multi-line reads were therefore
# blocked, by accident rather than by design.
#
# The tempting fix — take the first line's first word — would WIDEN the gate:
# `grep x` on line 1 would allowlist whatever line 2 does. Instead each line is
# judged on its own and all must pass. That fixes multi-line reads without
# admitting anything a single-line command could not already do.
is_bash_safe_command() {
    local cmd="$1"

    # T-1908: strip leading env-var prefixes (`KEY=val [KEY2=val2 ...] cmd args`).
    # Without this, the L-399 / T-1890 bypass-mechanism contract that promises
    # `FW_SWITCH_FOCUS=1 fw work-on T-XXX` works actually fails — the base
    # extraction returns `FW_SWITCH_FOCUS=1`, no case matches, the safe-command
    # path is skipped, and the downstream captured-status check blocks the very
    # command the focus-drift block message recommended. Strip one at a time.
    local sc_env_re='^[A-Za-z_][A-Za-z0-9_]*=([^[:space:]]*)[[:space:]]+(.*)$'
    while [[ "$cmd" =~ $sc_env_re ]]; do
        # T-405: `WURL=$(cat some/path 2>/dev/null)` is NOT an env-var prefix.
        # Its first space falls INSIDE the command substitution, so the regex
        # ends the "value" at `$(cat` and the next word — an ARGUMENT — becomes
        # the command name. `.context/working/watchtower.url` matches nothing in
        # the allowlist, so the command is blocked. This is the second mechanism
        # blocking the /resume skill's own Step 5 command; T-404 was the first.
        case "${BASH_REMATCH[1]}" in
            *'$('*|*'`'*|*'"'*|*"'"*) break ;;
        esac
        cmd="${BASH_REMATCH[2]}"
    done

    # Judge every SEGMENT; all must be safe. A command with no runnable segment
    # is NOT safe (fail closed) rather than vacuously safe.
    #
    # Segments are split out of the QUOTE-STRIPPED command, so a separator inside
    # a quoted argument — `grep 'a;b' f` — is not a separator. Splitting the raw
    # string would reintroduce, on the allowlist side, exactly the quotes-are-not-
    # structure defect T-404 fixed on the write-detection side.
    #
    # This also TIGHTENS the gate, deliberately: `cd /x && rm -rf y` previously
    # extracted base `cd`, matched the allowlist wholesale, and was safe as far as
    # this predicate was concerned — only the destructive-verb check stood behind
    # it. Now every segment is judged on its own.
    _sc_strip_quoted "$cmd"
    local segs="$_SC_STRIPPED"
    segs="${segs//&&/$'\n'}"
    segs="${segs//||/$'\n'}"     # before the single-pipe pass, or `||` splits twice
    segs="${segs//;/$'\n'}"
    segs="${segs//|/$'\n'}"

    local line seen=0
    while IFS= read -r line; do
        [ -n "${line//[[:space:]]/}" ] || continue   # skip blank/whitespace-only
        seen=1
        _sc_simple_is_safe "$line" || return 1
    done <<< "$segs"
    [ "$seen" -eq 1 ] || return 1
    return 0
}

# Judge ONE line. Everything below is the original allowlist, with base
# extraction changed from an awk+sed pipeline to pure parameter expansion —
# two fewer forks on a predicate that runs on every Bash tool call.
_sc_simple_is_safe() {
    local cmd="$1"

    # Extract the base command (first word, strip path).
    # For compound commands, the first word is still the primary command.
    local base="${cmd#"${cmd%%[![:space:]]*}"}"   # ltrim
    base="${base%%[[:space:]]*}"                  # first token

    # T-405: the command inside an assignment's command substitution IS the
    # command. `WURL=$(cat path)` runs `cat`; the token is not an env-var prefix
    # (the stripper above correctly refuses it, because its value contains an
    # unclosed `$(`) and it is not a command name either. Unwrap to the real one.
    case "$base" in
        *'=$('*) base="${base#*=\$\(}" ;;
        '$('*)   base="${base#\$\(}"   ;;
    esac
    base="${base##*/}"                            # strip leading path

    case "$base" in
        # Category 1: Git read-only
        git)
            local git_sub
            git_sub=$(echo "$cmd" | awk '{print $2}')
            case "$git_sub" in
                status|log|diff|show|branch|remote|describe|rev-parse|tag|stash|shortlog|blame|ls-files|ls-tree|cat-file|name-rev|reflog)
                    return 0
                    ;;
                # T-2054: `git add` is task-agnostic — it stages already-produced
                # content (the Write/Edit gate ensured that content was created
                # under a task) and carries no T-XXX reference, so it cannot drift.
                # Safe with no active task. `git commit` is deliberately NOT here:
                # it must reach the focus-drift gate (T-1730) in check-active-task.sh
                # when a focus exists, so its post-completion (null-focus) allow is
                # handled there instead — see the T-2054 block in check-active-task.sh.
                add)
                    return 0
                    ;;
                # T-2462: `git push` / `git fetch` are task-agnostic. Push only
                # PUBLISHES commits that already passed the commit-msg T-XXX gate
                # (P-002) — it creates no work artifact, mutates no working tree,
                # and is not inspected by the focus-drift detector (T-1730 only
                # looks at fw task update / fw context add / git commit -m T-X:).
                # Fetch is pure network read. Gating either on an active task adds
                # zero governance and manufactures a deadlock that fires whenever
                # focus is null: (1) post-completion — `--status work-completed`
                # nulls focus, but "never end a session with unpushed commits"
                # still requires the push (T-2054 exempted commit+add but stopped
                # before push — this closes that 3rd leg of the commit→push
                # pipeline, L-399 producer/consumer parity); (2) worktree sessions
                # where the Bash hook resolves PROJECT_ROOT to the main repo (null
                # focus). This does NOT weaken the pre-push hooks (self-vendor
                # drift, secret scan) — those run inside git, independently of this
                # active-task gate. `pull` is deliberately EXCLUDED: it merges into
                # the working tree (a write), so it stays gated.
                push|fetch)
                    return 0
                    ;;
            esac
            ;;

        # Category 2: File reading
        cat|head|tail|ls|wc|file|stat|realpath|readlink|basename|dirname|test|\[)
            return 0
            ;;

        # Category 2b: read-only text processing (T-632)
        #
        # These were not misclassified as writes — they were never classified at all.
        # Absent from every category, they fell through to "not in allowlist", and
        # because T-405 judges EVERY segment of a pipeline, one such stage condemned
        # the whole pipeline: `cat f | sed -n 1,20p` was refused while `cat f` passed.
        # That is a false RED, and a false red is the same defect as a false green —
        # it moves the gate's verdict away from the truth and teaches the reader to
        # route around it.
        #
        # ADMISSION RULE, applied per verb: admit only what cannot write a file
        # WITHOUT a shell redirect, because a shell redirect is already caught above.
        # Two verbs are deliberately NOT here, and the reasons are the interesting part:
        #
        #   awk   — a language with unrestricted `print > "file"` and `system()`. Its
        #           write syntax sits inside the quoted program, which the stripper
        #           removes before this predicate ever sees it. There is no honest
        #           check to make, so it stays gated.
        #   uniq  — its SECOND positional operand is an output file (`uniq in out`).
        #           Counting operands here is not reliable: the stripper deletes
        #           quoted content entirely, so `uniq "in" "out"` presents as
        #           operand-free. `sort -u` covers the same need and is guarded.
        #
        # `sed` IS admitted, but only because has_bash_write_pattern above was given a
        # matching raw-string check for `-i` and the `w` flag in the same change. The
        # ordering in check-active-task.sh:92-97 (write check first, verdict overrides
        # the allowlist) is what makes that guard load-bearing rather than advisory.
        cut|tr|nl|rev|comm|cmp|diff|tac|fold|paste|join|column|jq|xxd|od|strings|base64|cksum|md5sum|sha1sum|sha256sum|seq)
            return 0
            ;;
        sed)
            # Write forms are caught by has_bash_write_pattern, which runs first and
            # overrides this verdict. Delegating keeps ONE implementation of the
            # question, the way the echo/printf branch does (T-404's copy-drift lesson).
            if ! has_bash_write_pattern "$cmd"; then
                return 0
            fi
            ;;
        sort)
            # `sort -o out` / `--output=out` write without a shell redirect. The check
            # lives in has_bash_write_pattern, not here: "does this write a file" has
            # exactly one implementation, and a guard that lived only in the allowlist
            # would leave has_bash_write_pattern answering NO for a command that
            # demonstrably writes — wrong for every caller that asks it directly.
            if ! has_bash_write_pattern "$cmd"; then
                return 0
            fi
            ;;

        # Category 3: Searching
        grep|rg|find|which|where|type|command)
            return 0
            ;;

        # Category 4: FW diagnostics
        fw|bin/fw)
            local fw_sub
            fw_sub=$(echo "$cmd" | awk '{print $2}')
            case "$fw_sub" in
                doctor|metrics|audit|version|resume|help|status|fabric|gaps|promote)
                    return 0
                    ;;
                context)
                    local ctx_sub
                    ctx_sub=$(echo "$cmd" | awk '{print $3}')
                    case "$ctx_sub" in
                        status|focus|init)
                            return 0
                            ;;
                        # T-390: knowledge capture must survive the no-task state,
                        # because that state is CREATED by the event these verbs
                        # exist to record. `--status work-completed` nulls focus and
                        # moves the task to completed/, and the very next thing the
                        # framework asks for is a learning ("LEARNING PROMPT — no
                        # learning entry references T-XXX", printed BY update-task.sh
                        # at the moment its own gate has just made the command
                        # unrunnable). Same deadlock shape as T-2052 (task create)
                        # and T-2054 (git commit); third instance in this file.
                        #
                        # Safe on the same grounds as those two: these verbs write
                        # only under .context/, which is already an exempt path for
                        # Write/Edit, and they record knowledge ABOUT work already
                        # produced under the gate — they cannot author source. The
                        # --task T-XXX argument still attributes the entry, so
                        # traceability is unaffected.
                        add-learning|add-pattern|add-decision|generate-episodic)
                            return 0
                            ;;
                    esac
                    ;;
                # T-390: `fw note` is the lightweight observation inbox — the verb for
                # recording something you noticed but are not acting on now. Blocking
                # it with no active task is self-defeating in a specific way: the
                # framework could not record the observation that it cannot record
                # observations. Writes only to .context/inbox.yaml; its one escalating
                # sub-verb (`note promote`) creates a task, already exempt (T-2052).
                note)
                    return 0
                    ;;
                # T-390 / OBS-002: `fw handover` was blocked with no active task —
                # the state at the end of a session that just completed its last task,
                # which is exactly when a handover is MANDATORY (CLAUDE.md §Session End
                # Protocol). Writes to .context/handovers/ only.
                handover)
                    return 0
                    ;;
                task)
                    local task_sub
                    task_sub=$(echo "$cmd" | awk '{print $3}')
                    case "$task_sub" in
                        # T-2052: `create` is task-bootstrap (writes only to the
                        # exempt .tasks/ dir) — must be allowed with no active task,
                        # else the gate deadlocks its own "create a task" advice.
                        list|verify|review|create)
                            return 0
                            ;;
                    esac
                    ;;
                work-on|inception)
                    # work-on and inception commands are task bootstrap — always allowed
                    return 0
                    ;;
                upstream)
                    # T-2410 case 2: `fw upstream` has read-only sub-verbs
                    # (status, list, info) — exempt these from the active-task
                    # gate so consumers can inspect upstream pin state under
                    # any focus condition. Mutating sub-verbs (pin, set, sync)
                    # are NOT exempt; they fall through to the task check.
                    local ups_sub
                    ups_sub=$(echo "$cmd" | awk '{print $3}')
                    case "$ups_sub" in
                        status|list|info|show|help|--help|-h|--version|"")
                            return 0
                            ;;
                    esac
                    ;;
                hook)
                    # fw hook * — hooks calling hooks, always allowed
                    return 0
                    ;;
                integrate)
                    # T-2471: `fw integrate {check,classify}` are read-only; `fw
                    # integrate run` is the mutating merge-back verb. All three are
                    # task-agnostic meta-operations on git history: the merge
                    # commits run creates are --no-ff --no-edit (no T-XXX work
                    # artifact — the commit-msg hook already exempts MERGE_HEAD),
                    # and gating them on an active task manufactures a deadlock —
                    # integration runs from a worktree whose Bash-hook PROJECT_ROOT
                    # resolves to the main repo (null focus). This verb-scoped
                    # exemption is the EFFECTIVE focus-gate bypass; it deliberately
                    # does NOT use an FW_INTEGRATION_IN_PROGRESS env honor, which
                    # would reintroduce the T-2446 inherited-env poison class this
                    # arc exists to eliminate. Same category as git push/add/commit
                    # (T-2054/T-2462). run sets FW_INTEGRATION_IN_PROGRESS=1 only
                    # for the python subprocess's own internal git calls.
                    return 0
                    ;;
            esac
            ;;

        # Category 5: System utilities
        curl|wget|date|uname|ps|ss|id|whoami|hostname|env|printenv|df|du|free|uptime|lsb_release|nproc)
            return 0
            ;;

        # Category 6: Validation
        python3|python)
            # Only safe if it's a parse/check command (no file writes)
            if echo "$cmd" | grep -qE '^\s*(python3?)\s+-c\s'; then
                # Check for write indicators in the inline script
                if echo "$cmd" | grep -qE "(open\(.*, *['\"]w|\.write\(|shutil\.|os\.(rename|remove|unlink|makedirs|system))"; then
                    return 1
                fi
                return 0
            fi
            ;;
        bash|sh)
            # bash -n (syntax check only) is safe
            if echo "$cmd" | grep -qE '^\s*(ba)?sh\s+-n\b'; then
                return 0
            fi
            ;;

        # Special: echo without redirect is safe (diagnostic output)
        echo|printf)
            # T-404: ONE redirect predicate, two callers. This branch used to carry
            # its own copy — `[^>]>[^>]|>>` — which never received the fd/sink
            # exclusions its sibling in has_bash_write_pattern was given, so
            # `echo x; cat f 2>/dev/null` was classified as a file write. Classic
            # copy-drift: the copy that does not fire is the copy that rots
            # unnoticed (same finding as T-401's two budget gauges, same remedy).
            # Delegate instead of duplicating.
            if ! has_bash_write_pattern "$cmd"; then
                return 0
            fi
            ;;

        # Special: cd is always safe
        cd)
            return 0
            ;;

        # Special: npm/cargo/brew read operations
        npm|npx|cargo|brew)
            local pkg_sub
            pkg_sub=$(echo "$cmd" | awk '{print $2}')
            case "$pkg_sub" in
                list|ls|info|show|search|view|outdated|audit|help|version|--version|-v|-V)
                    return 0
                    ;;
            esac
            ;;
    esac

    # Not in allowlist — caller should check for active task
    return 1
}

# T-404 / PL-025: remove the CONTENT of quoted segments, leaving shell structure
# intact, so a redirect operator inside a quoted argument is not mistaken for a
# real redirect. `grep -n "a\|>>\|b" f` reads a file; it does not write one.
#
# Pure bash on purpose — no fork. This runs inside a PreToolUse hook on EVERY
# Bash tool call, so a `$(...)` subshell or a python3 startup here is paid
# thousands of times a session. Result is returned in the global _SC_STRIPPED
# rather than on stdout, for the same reason.
_sc_strip_quoted() {
    # `n` MUST be computed in its own statement. In `local s="$1" n=${#s}`, bash
    # expands every word BEFORE performing any assignment, so ${#s} would read
    # the not-yet-assigned s and yield 0 — the loop would never run, the stripped
    # result would be the empty string, and this predicate would silently report
    # "no writes" for every command. Caught by the genuine-writes half of the
    # corpus; invisible to the benign half, which an always-empty result passes.
    local s="$1"
    local out="" i=0 c q=""
    local n=${#s}
    while [ "$i" -lt "$n" ]; do
        c="${s:$i:1}"
        if [ -n "$q" ]; then
            # Inside quotes: emit nothing. The content is data, not structure.
            [ "$c" = "$q" ] && q=""
        elif [ "$c" = "'" ] || [ "$c" = '"' ]; then
            q="$c"
        elif [ "$c" = "\\" ]; then
            i=$((i + 1))   # escaped char is data too — skip both
        else
            out+="$c"
        fi
        i=$((i + 1))
    done
    _SC_STRIPPED="$out"
}

# T-636: does this command hand FREE PROSE to a framework verb that stores it?
#
# The set is closed by construction — it is the verbs the framework itself declares
# safe with no active task (`note`, `context add-*`, `task create`) plus `git commit`,
# whose message is the one other place an agent writes sentences. It is not an open
# class, so enumerating it does not run into the G-025/G-026 objection.
#
# Deliberately NOT generalised to "any `fw` verb": that would rest on the claim that no
# fw subcommand ever evaluates an argument, which nobody has measured. Naming the four
# costs a line each and rests on nothing.
# Pure parameter expansion, zero forks. This runs inside has_bash_write_pattern, which
# runs on EVERY Bash tool call, and web/test_safe_commands.py holds a perf contract
# against exactly this — the first draft here used three awks and the corpus failed it.
# The rejected draft is worth a line: it is the same lesson as the predicate it sits in,
# one level up. A helper written to answer a cheap question expensively is a cost paid by
# every command in the session, not by the four it is about.
_sc_is_framework_prose_verb() {
    local c="$1" tok1 tok2 tok3 rest
    rest="${c#"${c%%[![:space:]]*}"}"          # ltrim
    tok1="${rest%%[[:space:]]*}"
    case "$tok1" in
        fw|*/fw) ;;
        *) return 1 ;;
    esac
    rest="${rest#"$tok1"}"; rest="${rest#"${rest%%[![:space:]]*}"}"
    tok2="${rest%%[[:space:]]*}"
    rest="${rest#"$tok2"}"; rest="${rest#"${rest%%[![:space:]]*}"}"
    tok3="${rest%%[[:space:]]*}"
    case "$tok2" in
        note) return 0 ;;
        context)
            case "$tok3" in add-learning|add-pattern|add-decision) return 0 ;; esac
            ;;
        task)
            case "$tok3" in create) return 0 ;; esac
            ;;
        git)
            case "$tok3" in commit) return 0 ;; esac
            ;;
    esac
    return 1
}

# Check if a command contains file-write patterns
has_bash_write_pattern() {
    local cmd="$1"

    # --- Redirects: judged on shell structure, not raw characters (PL-025) ---
    # Walk every redirect in the quote-stripped command and look at its TARGET.
    # A redirect is only a write if it lands on a file:
    #   >f  >>f  1>f  2>f  &>f       → write
    #   >/dev/null  2>/dev/null  &>/dev/null → discard, writes nothing
    #   2>&1  >&2  2>&-              → fd duplication/close, no file involved
    # The previous single regex could not tell these apart: it fired on
    # `2>/dev/null` (via the drifted copy below) and on quoted `>>`.
    _sc_strip_quoted "$cmd"
    local rest="$_SC_STRIPPED" tgt
    # NB: the operator is written [>] and NOT \> on purpose. bash's =~ uses the
    # system ERE engine, where glibc gives \> the meaning "end of word" — so a
    # \>\>? group silently matches word boundaries and never sees a redirect at
    # all. Held as a variable because an unquoted $var is the one form bash
    # reliably treats as a regex rather than a literal.
    # T-632: `)` is a TERMINATOR of the target, not part of it. Without it the walk
    # reads `$(cat f 2>/dev/null)` as a redirect onto a file named `/dev/null)` — which
    # is not the string `/dev/null`, so the sink exclusion below misses and the whole
    # command is classified as a write. Same for `x=$(cmd 2>&1)`: the target reads `&1)`
    # and the fd-dup exclusion misses too. Both were live: `WURL=$(cat url 2>/dev/null)`
    # was refused by the active-task gate on a session that had written nothing.
    #
    # This is PL-025's own class — a character class standing in for shell structure —
    # recurring inside the branch T-404 added to fix PL-025. The stripper handles
    # quotes; nothing handled nesting. A `)` cannot be part of an unquoted redirect
    # target anyway (bash would take it as syntax), so stopping there costs nothing:
    # `> f)bar` still yields target `f` and is still a write.
    local sc_redirect_re='(&?[0-9]*)([>][>]?[|]?)[[:space:]]*([^[:space:];|)]*)(.*)$'
    while [[ "$rest" =~ $sc_redirect_re ]]; do
        tgt="${BASH_REMATCH[3]}"
        rest="${BASH_REMATCH[4]}"
        case "$tgt" in
            /dev/null)  ;;              # discard sink — not a source write
            '&'[0-9]|'&'-) ;;           # fd dup / fd close — no file
            '')         ;;              # nothing to redirect onto — ignore
            *) return 0 ;;              # a real target → genuine write
        esac
    done

    # T-636: the raw-string verb scans below are deliberately over-broad, on an
    # asymmetry argument spelled out in the block that follows: a false positive costs
    # only "you need an active task", a false negative lets `sh -c "rm -rf x"` past.
    #
    # THAT ARGUMENT IS ABOUT EXECUTION, and it inverts where the quoted argument is
    # prose the framework STORES rather than runs. `fw note`, `fw context add-*`,
    # `fw task create --name` and `fw git commit -m` all take free text, and in this
    # project that text is overwhelmingly ABOUT shell behaviour — so the "mild" false
    # positive is not mild. Measured at T-636: a single word vetoes all four. The
    # observation inbox refuses observations that mention `rm`, and refuses them with
    # "No active task", which sends the reader to create a task — the exact remedy
    # T-390 added the `note` allowlist (line ~240) to avoid. The framework could not
    # record the observation that it cannot record observations about `rm`.
    #
    # The exemption scans the STRIPPED string rather than skipping the scan, so a
    # destructive verb outside the quotes is still caught: `fw note "x" && rm -rf y`
    # still vetoes. And any command substitution disqualifies the exemption outright —
    # that IS a route from the argument back to the shell, so the execution asymmetry
    # applies again and the raw scan runs as before.
    if _sc_is_framework_prose_verb "$cmd" \
       && [[ "$cmd" != *'$('* ]] && [[ "$cmd" != *'`'* ]]; then
        cmd="$_SC_STRIPPED"
    fi

    # --- Destructive/writing VERBS: deliberately still judged on the RAW string ---
    # T-404 decision: quote-stripping is applied to redirects only. For verbs the
    # failure directions are not symmetric. A false positive here costs "you need an
    # active task" (mild). A false negative would let `sh -c "rm -rf x"` — where the
    # verb lives inside quotes — past the gate. Erring toward "is a write" is the
    # safe direction for destructive verbs, so these keep scanning $cmd, not
    # $_SC_STRIPPED. Consequence, accepted knowingly: `grep -n "rm" f` is still
    # classified as a write. That is the conservative side of the boundary.

    # sed writes files two ways, and only one of them was checked.
    #   sed -i ...            in-place edit
    #   sed 's/a/b/w out' f   the `w` flag; also the bare `w` command
    # T-632 added the second. It matters now because `sed` was admitted to the
    # read-only allowlist below, and sed's write syntax lives INSIDE the quoted
    # program — where the redirect walk above, which strips quoted content, cannot
    # see it. So this raw-string check is the only thing standing behind it.
    #
    # Deliberately over-broad, on the same asymmetry the block below documents: a
    # false positive costs "you need an active task", a false negative silently
    # authors a file with no task. `sed 's/x/ w /'` will read as a write. Accepted.
    if echo "$cmd" | grep -qE '\bsed\b.*(-i|--in-place)'; then
        return 0
    fi
    if echo "$cmd" | grep -qE "\bsed\b.*[^[:alnum:]]w[[:space:]]+[^[:space:]'\"]"; then
        return 0
    fi

    # sort writes without a shell redirect too (T-632). Same reason as sed: it is on
    # the read-only allowlist now, so this is the guard standing behind it.
    if echo "$cmd" | grep -qE '\bsort\b.*(^|[[:space:]])(-o([[:space:]]|$)|--output)'; then
        return 0
    fi

    # Destructive file operations (already caught by Tier 0 but belt-and-suspenders)
    if echo "$cmd" | grep -qE '\b(rm|rmdir)\b'; then
        return 0
    fi

    # Heredoc
    if echo "$cmd" | grep -qE '<<\s*['"'"'"]?EOF'; then
        return 0
    fi

    # tee (writes to file)
    if echo "$cmd" | grep -qE '\btee\b'; then
        return 0
    fi

    return 1
}

# T-638: is this command NOTHING BUT a git commit (plus safe-listed company)?
#
# The T-2054 exemption in check-active-task.sh admits a command with NO ACTIVE
# TASK, and its written justification is precise: committing "persists work
# already produced under the Write/Edit task gate — it is not new work." That is
# true of a command that IS a git commit. The branch asked whether the command
# CONTAINED one:
#
#     [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]
#
# A raw-string match, on the unstripped command, unanchored to any clause. So it
# admitted, measured against the live hook with focus null:
#
#   * `git commit -m "..." ; <anything>`  — every clause, past the gate
#   * `git commit -m "..." | tee f`       — a write the gate had already flagged
#   * `somebinary --flag "please git commit this"` — an ARBITRARY UNKNOWN BINARY,
#     admitted because a QUOTED ARGUMENT contained the words. Nothing was
#     committed; the sentence was enough.
#
# The last one is the family this project has now found six times in three days,
# in six different instruments: a character-level scan standing in for structure,
# so a command that MENTIONS an act is treated as the act. The remedy is the same
# every time — split the QUOTE-STRIPPED command into clauses and judge each one.
#
# Note the ordering bug this also closes. In check-active-task.sh the write-pattern
# check at line ~91 does not exit; it falls through. So a command whose second
# clause has_bash_write_pattern correctly identified as destructive still reached
# this branch and was handed `exit 0`. The gate saw the write and admitted it.
#
# ADMISSION RULE: every clause must already be allowed with no active task —
# `_sc_simple_is_safe`, which is where `cd`, `git add` and `git push` live — or be
# the git commit itself, and at least one clause must be that commit. Composing
# with the existing allowlist rather than enumerating a second one is deliberate:
# `git add -A && git commit -m "..."` is the documented post-completion form, and a
# hand-rolled list would have to rediscover it and would drift from the real one.
#
# Pure bash, no fork beyond what the callees already pay: PreToolUse path.
# T-639: which task does this command ACT ON? (empty = none)
#
# The focus-drift gate (T-1730) used three regexes over the RAW command, so each
# read task ids out of quoted arguments. Pattern 3 carried two over-matches at once:
# `git commit` anywhere (the T-638 defect verbatim) AND an entirely unanchored
# `(T-[0-9]+):`. A command that merely CONTAINED a task id became an action on it.
#
# Self-demonstrating consequence: a prober exercising the gate's own git-commit path
# is blocked by the gate, because its fixtures contain task ids. Reproduced live.
# During T-638 every fixture was written `T-x:` rather than `T-1:` to stay under the
# pattern — the gate was shaping test data to avoid itself, which is the exact
# failure the file's own comments warn about ("a guard that fires on the wrong
# command trains people to bypass it").
#
# THE ASYMMETRY, which is the whole design. Patterns 1 and 2 take the task id as a
# BARE ARGUMENT, so the quote-stripped command is the correct read and a quoted
# mention correctly disappears. Pattern 3's id lives INSIDE the quoted -m value —
# stripping would delete precisely what it must read. So P3 instead asks two
# structural questions: does some clause actually INVOKE git commit, and does the
# message value START with `T-NNN:`? That prefix is the canonical form commit-msg
# enforces and `fw git log --task` reads, so anchoring there is not a heuristic —
# it is the same definition the rest of the framework already uses.
#
# Result in the global _SC_DRIFT_TARGET; returns 0 when a target was identified.
_sc_drift_target() {
    local cmd="$1"
    _SC_DRIFT_TARGET=""

    _sc_strip_quoted "$cmd"
    local stripped="$_SC_STRIPPED"

    # Pattern 1: fw task update T-NNNN — bare argument, judged on the stripped string.
    if [[ "$stripped" =~ (^|[[:space:]])([^[:space:]]*/)?fw[[:space:]]+task[[:space:]]+update[[:space:]]+(T-[0-9]+) ]]; then
        _SC_DRIFT_TARGET="${BASH_REMATCH[3]}"
        return 0
    fi

    # Pattern 2: fw context add-* --task T-NNNN — also a bare argument.
    if [[ "$stripped" =~ (^|[[:space:]])([^[:space:]]*/)?fw[[:space:]]+context[[:space:]]+add- ]] && \
       [[ "$stripped" =~ --task[[:space:]=]+(T-[0-9]+) ]]; then
        _SC_DRIFT_TARGET="${BASH_REMATCH[1]}"
        return 0
    fi

    # Pattern 3, first half: does a clause actually INVOKE git commit? Asking
    # "does the string contain `git commit`" is what let a quoted fixture through.
    local segs="$stripped" line rest tok1 tok2 invokes_commit=0
    segs="${segs//&&/$'\n'}"
    segs="${segs//||/$'\n'}"
    segs="${segs//;/$'\n'}"
    segs="${segs//|/$'\n'}"
    while IFS= read -r line; do
        [ -n "${line//[[:space:]]/}" ] || continue
        rest="${line#"${line%%[![:space:]]*}"}"
        tok1="${rest%%[[:space:]]*}"
        rest="${rest#"$tok1"}"; rest="${rest#"${rest%%[![:space:]]*}"}"
        tok2="${rest%%[[:space:]]*}"
        if [ "${tok1##*/}" = "git" ] && [ "$tok2" = "commit" ]; then
            invokes_commit=1
            break
        fi
    done <<< "$segs"
    [ "$invokes_commit" -eq 1 ] || return 1

    # Pattern 3, second half: the id must PREFIX the message value. Read from the
    # raw command on purpose — this is the one id that is legitimately quoted.
    local msg=""
    if [[ "$cmd" =~ (^|[[:space:]])(-m|--message)[[:space:]]*=?[[:space:]]*\"([^\"]*)\" ]]; then
        msg="${BASH_REMATCH[3]}"
    elif [[ "$cmd" =~ (^|[[:space:]])(-m|--message)[[:space:]]*=?[[:space:]]*\'([^\']*)\' ]]; then
        msg="${BASH_REMATCH[3]}"
    elif [[ "$cmd" =~ (^|[[:space:]])(-m|--message)[[:space:]]+([^[:space:]]+) ]]; then
        msg="${BASH_REMATCH[3]}"
    fi
    if [[ "$msg" =~ ^(T-[0-9]+): ]]; then
        _SC_DRIFT_TARGET="${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

_sc_is_commit_only_command() {
    local cmd="$1"

    # Substitution is opaque to any clause check — `git commit -m "$(anything)"`
    # runs code this function cannot see. Refuse the exemption rather than reason
    # about it. Same call T-636 made for the prose verbs, for the same reason.
    case "$cmd" in
        *'$('*|*'`'*) return 1 ;;
    esac

    # Called BEFORE our own strip: has_bash_write_pattern sets _SC_STRIPPED too,
    # and would otherwise clobber ours between the strip and the split.
    has_bash_write_pattern "$cmd" && return 1

    _sc_strip_quoted "$cmd"
    local segs="$_SC_STRIPPED"
    segs="${segs//&&/$'\n'}"
    segs="${segs//||/$'\n'}"     # before the single-pipe pass, or `||` splits twice
    segs="${segs//;/$'\n'}"
    segs="${segs//|/$'\n'}"

    local line rest tok1 tok2 saw_commit=0
    while IFS= read -r line; do
        [ -n "${line//[[:space:]]/}" ] || continue
        rest="${line#"${line%%[![:space:]]*}"}"      # ltrim
        tok1="${rest%%[[:space:]]*}"
        rest="${rest#"$tok1"}"; rest="${rest#"${rest%%[![:space:]]*}"}"
        tok2="${rest%%[[:space:]]*}"
        case "${tok1##*/}" in
            git)
                if [ "$tok2" = "commit" ]; then
                    saw_commit=1
                    continue
                fi
                ;;
        esac
        _sc_simple_is_safe "$line" || return 1
    done <<< "$segs"

    [ "$saw_commit" -eq 1 ] || return 1
    return 0
}
