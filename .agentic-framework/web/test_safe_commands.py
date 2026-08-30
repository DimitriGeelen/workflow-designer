"""True-positive / false-positive corpus for the Bash task-gate command classifier.

This file is the remedy PL-025 prescribed on 2026-07-10 and that nothing applied
for 30 days:

    "When a heuristic reasons about raw characters instead of shell semantics,
     pin the true-positive/false-positive boundary with a test corpus (genuine
     writes must stay caught, benign forms must pass) so over-broad matches
     surface before they block real commands."

Two properties are pinned here, and they pull in opposite directions:

  * BENIGN_READS must NOT be classified as writes. Every entry is a command that
    reads. If one of these starts failing, the gate has begun blocking real work
    — which is invisible in normal use, because the misclassification only
    changes an outcome when focus is null (the state compaction creates).

  * GENUINE_WRITES must STILL be classified as writes. This is the half that
    proves a fix repaired the check rather than removed it. A "fix" that widens
    the benign set by narrowing the predicate to nothing would pass the first
    list and fail this one.

Why a corpus and not inspection: the defect this file exists to prevent is
precisely one that reading the regex does not reveal. `[^>]>[^>]|>>` looks
correct until you feed it `2>/dev/null`.
"""

import pathlib
import subprocess

import pytest

LIB = (
    pathlib.Path(__file__).resolve().parent.parent
    / "agents"
    / "context"
    / "lib"
    / "safe-commands.sh"
)


def _call(func, cmd):
    """Run one predicate from safe-commands.sh against cmd; return its truth value.

    The command is passed as $1, never interpolated into the script text — the
    corpus is full of quotes and redirect operators, and interpolating it would
    make the harness itself the thing under test.
    """
    script = f'source "{LIB}"; if {func} "$1"; then exit 0; fi; exit 1'
    return subprocess.run(["bash", "-c", script, "_", cmd]).returncode == 0


def is_write(cmd):
    return _call("has_bash_write_pattern", cmd)


def is_safe(cmd):
    return _call("is_bash_safe_command", cmd)


def gate_allows(cmd):
    """Mirror check-active-task.sh:92-97 ordering.

    The write-pattern check runs FIRST and its verdict overrides the allowlist —
    being `grep` or `cat` cannot save a command judged to be a write. That
    ordering is why a false write verdict is not a cosmetic problem.
    """
    return (not is_write(cmd)) and is_safe(cmd)


# --------------------------------------------------------------------------
# The three commands that were actually blocked during the 2026-08-09 resume,
# reproduced verbatim. These are the regression anchors: if any of them starts
# failing again, this exact incident has recurred.
# --------------------------------------------------------------------------
INCIDENT_COMMANDS = [
    # stderr-suppression after `echo` — hit the DRIFTED copy in the echo/printf
    # branch, which lacked the fd exclusions its sibling had.
    'echo "=== BUDGET ==="; cat .context/working/.budget-status 2>/dev/null',
    # a redirect operator inside a QUOTED grep pattern — data, not structure.
    'grep -n "modify\\|redirect\\|>>\\|target" script.sh',
    # a comparison operator inside a python3 -c program.
    "python3 -c \"print([t for t in topics if t['count'] >= 50])\"",
]

BENIGN_READS = INCIDENT_COMMANDS + [
    "cat .context/working/.budget-status 2>/dev/null",
    "ls -la 2>/dev/null",
    "git status --short 2>/dev/null",
    'find . -name "*.sh" 2>/dev/null',
    "grep -rn pattern . 2>/dev/null",
    # fd duplication and closing: no file is involved at all
    "make 2>&1",
    "cmd >&2",
    "cmd 2>&-",
    # /dev/null is a discard sink — a redirect onto it writes nothing (PL-025)
    "echo hi > /dev/null",
    "cmd 2>/dev/null",
    "cmd &> /dev/null",
    'curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/',
    # operators as literal data
    'echo "a > b"',
    "echo 'x >> y'",
    'grep -c "^ D .context/audits/" status.txt',
]

GENUINE_WRITES = [
    "echo hi > out.txt",
    "echo hi >> out.txt",
    "cat a > b",
    "python3 generate.py > result.json",
    "cmd 2> errors.log",
    "cmd &> combined.log",
    "cmd 1> stdout.log",
    "echo x >/etc/hosts",
    'sed -i "s/a/b/" file.txt',
    "tee output.txt",
    "cat <<EOF",
    "rm -f target",
]


@pytest.mark.parametrize("cmd", BENIGN_READS)
def test_benign_reads_are_not_writes(cmd):
    assert not is_write(cmd), f"read-only command classified as a write: {cmd!r}"


@pytest.mark.parametrize("cmd", GENUINE_WRITES)
def test_genuine_writes_are_still_caught(cmd):
    """TEETH. A predicate narrowed into uselessness passes the benign half."""
    assert is_write(cmd), f"genuine write NOT caught: {cmd!r}"


@pytest.mark.parametrize("cmd", INCIDENT_COMMANDS)
def test_incident_commands_reach_the_allowlist_and_pass(cmd):
    """End-to-end at predicate level: allowed with no active task.

    Not the same assertion as test_benign_reads_are_not_writes. That one proves
    the write verdict is gone; this one proves the command then actually reaches
    and satisfies the allowlist — i.e. the gate lets it run.
    """
    assert gate_allows(cmd), f"still blocked with null focus: {cmd!r}"


def test_quoted_operator_and_real_redirect_in_one_command():
    """The discriminating case: both forms present at once.

    A predicate that simply ignored quotes would pass; one that simply ignored
    redirects would too. Only a quote-aware scan gets this right.
    """
    assert is_write('grep -n ">>" file.sh > results.txt')
    assert not is_write('grep -n ">>" file.sh 2>/dev/null')


def test_escaped_redirect_is_data_not_structure():
    assert not is_write("echo \\> not-a-redirect")


def test_destructive_verbs_are_judged_conservatively():
    """Documents a DELIBERATE asymmetry, so it cannot drift silently.

    Quote-stripping is applied to redirects only. For destructive verbs the two
    failure directions are not equally bad: a false positive costs "you need an
    active task", a false negative would let `sh -c "rm -rf x"` past. So verbs
    keep scanning the raw string, and the known cost is that a quoted mention of
    a destructive verb still reads as a write.
    """
    assert is_write('sh -c "rm -rf /tmp/x"')  # the coverage this asymmetry buys
    assert is_write('grep -n "rm" notes.txt')  # the price it charges


# --------------------------------------------------------------------------
# T-405: base-command extraction. Two witnesses of one defect — the extractor
# assumed "the command is the first word", which is false for an assignment
# carrying a command substitution and false for anything multi-line.
# --------------------------------------------------------------------------

RESUME_STEP5 = (
    'WURL=$(cat .context/working/watchtower.url 2>/dev/null '
    '|| echo "http://localhost:3000"); curl -sf "$WURL/" > /dev/null && echo running'
)


def test_resume_step5_is_allowed():
    """The command the /resume skill documents for post-compaction recovery.

    It was blocked by TWO independent defects: the redirect predicate (T-404)
    and base extraction (T-405). Compaction nulls focus, so the framework's own
    recovery command was unrunnable in the exact state compaction creates. This
    asserts the deadlock is closed — the reason both tasks exist.
    """
    assert is_safe(RESUME_STEP5)
    assert not is_write(RESUME_STEP5)
    assert gate_allows(RESUME_STEP5)


def test_env_prefix_contract_still_holds():
    """T-1908's promise must survive the fix that narrows the stripper.

    The stripper exists so `FW_SWITCH_FOCUS=1 fw work-on T-XXX` — the command
    the focus-drift block message itself recommends — is recognised. Narrowing
    it to exclude command substitutions must not cost that.
    """
    assert is_safe("FW_SWITCH_FOCUS=1 fw work-on T-123")
    assert is_safe("FOO=bar BAZ=qux git status")


@pytest.mark.parametrize(
    "cmd,expected",
    [
        # multi-line, every line read-only
        ("grep foo bar\ncat baz", True),
        # multi-line where a later line is NOT read-only: must stay blocked.
        # The naive fix (take the first line's first word) would allow this.
        ("grep foo bar\nmake install", False),
        # compound on one line, judged per segment
        ("cd /opt && bin/fw task list", True),
        ("git status --short | grep -c D", True),
        ("cat f | make", False),
        # TIGHTENING: previously base was `cd`, which matched the allowlist
        # wholesale and made the whole compound "safe" as far as this predicate
        # was concerned. Now each segment is judged.
        ("cd /x && rm -rf y", False),
        # a separator inside quotes is data, not a separator
        ("grep 'a;b' f", True),
        # nothing runnable is not vacuously safe
        ("", False),
        ("   \n  ", False),
    ],
)
def test_segments_are_judged_individually(cmd, expected):
    assert is_safe(cmd) is expected, f"{cmd!r} expected safe={expected}"


# --------------------------------------------------------------------------
# T-632: nesting. The stripper handled quotes; nothing handled `)`.
#
# The redirect walk captured its target with a class that did not stop at a close
# paren, so inside a command substitution `2>/dev/null)` was a write onto a file
# named `/dev/null)` and `2>&1)` was a write onto `&1)`. Both exclusions missed by
# exactly one character.
#
# WHY THIS FILE STAYED GREEN FOR IT, which is the finding worth keeping. RESUME_STEP5
# above pins this exact command — and pins the variant that writes
# `2>/dev/null || echo ...`, where the `||` splits the segment BEFORE the paren. That
# copy never contains the failing adjacency. This corpus was assembled from the three
# commands blocked in the 2026-08-09 incident; it pinned those instances faithfully and
# never tested the class around them. Every fixture below is INVENTED rather than
# harvested, for that reason.
# --------------------------------------------------------------------------

NESTED_BENIGN = [
    # the form actually refused, on a session that had written nothing
    "WURL=$(cat .context/working/watchtower.url 2>/dev/null)",
    # the fd-duplication sibling: same off-by-one, different exclusion missed
    "x=$(make 2>&1)",
    "out=$(cmd 2>&- )",
    # a subshell is not a command substitution but has the same terminator
    "(cat f 2>/dev/null)",
]


@pytest.mark.parametrize("cmd", NESTED_BENIGN)
def test_close_paren_terminates_a_redirect_target(cmd):
    assert not is_write(cmd), f"read inside a substitution read as a write: {cmd!r}"


@pytest.mark.parametrize(
    "cmd",
    [
        "y=$(generate > result.json)",
        "out=$(cmd 2> errors.log)",
        "(echo hi > out.txt)",
    ],
)
def test_writes_inside_a_substitution_are_still_writes(cmd):
    """TEETH for the paren fix specifically.

    Stopping the target at `)` must not stop the walk from SEEING a redirect that
    happens to sit inside a substitution. A fix that simply bailed out on nesting
    would pass every benign case above and fail here.
    """
    assert is_write(cmd), f"genuine write inside a substitution NOT caught: {cmd!r}"


# --------------------------------------------------------------------------
# T-632 (b): read-only text tools were absent from the allowlist entirely.
# Not misclassified as writes — never classified. Because T-405 judges every
# segment, one such stage condemned a whole pipeline.
# --------------------------------------------------------------------------

READ_ONLY_TEXT_TOOLS = [
    "sed -n '1,20p' file.sh",
    "cat file.sh | sed -n '1,20p'",
    "sort -u names.txt",
    "cut -d: -f1 /etc/passwd",
    "tr -d '\\r' < file",
    "diff a.txt b.txt",
    "sha256sum dist/artifact.tar",
    "git log --oneline -5 | tac",
    "jq '.level' .context/working/.budget-status",
]


@pytest.mark.parametrize("cmd", READ_ONLY_TEXT_TOOLS)
def test_read_only_text_tools_reach_the_allowlist(cmd):
    assert gate_allows(cmd), f"pure read still blocked with null focus: {cmd!r}"


@pytest.mark.parametrize(
    "cmd",
    [
        'sed -i "s/a/b/" file.txt',
        "sed 's/a/b/w captured.txt' file.txt",  # the `w` flag writes too
        "sort -o sorted.txt names.txt",
        "sort --output=sorted.txt names.txt",
    ],
)
def test_write_capable_forms_of_admitted_verbs_stay_blocked(cmd):
    """The guard that makes admitting sed and sort defensible.

    sed's write syntax lives INSIDE the quoted program, where the stripper has
    already deleted it — so the raw-string check in has_bash_write_pattern is the
    only thing standing behind the allowlist entry, and the hook's ordering
    (write check first, verdict overrides the allowlist) is what makes it bind.
    """
    assert is_write(cmd), f"write-capable form not caught: {cmd!r}"
    assert not gate_allows(cmd), f"write-capable form reached the allowlist: {cmd!r}"


@pytest.mark.parametrize("cmd", ['awk \'{print > "out"}\' f', "uniq input.txt output.txt"])
def test_deliberate_exclusions_stay_excluded(cmd):
    """Documents two omissions as decisions, so a later widening trips here.

    awk is a language with unrestricted `print > file` and `system()`, both living
    inside the quoted program the stripper removes — there is no honest check to
    make. uniq's SECOND positional operand is an output file, and quoted operands
    collapse to nothing under the stripper, so operand counting cannot see it.
    `sort -u` covers the same need and is guarded.
    """
    assert not gate_allows(cmd), f"a write-capable verb was admitted: {cmd!r}"


def test_base_extraction_does_not_fork():
    """Perf contract: this predicate runs on EVERY Bash tool call.

    The awk+sed pipeline cost two forks per invocation. Pure parameter expansion
    costs none. Asserted structurally so it cannot quietly regress.
    """
    code = "\n".join(
        line
        for line in LIB.read_text().splitlines()
        if not line.lstrip().startswith("#")
    )
    assert "awk '{print $1}'" not in code


def test_no_second_copy_of_the_redirect_predicate():
    """Level C guard: one redirect implementation, not two.

    The original defect was not the regex — it was that there were TWO regexes
    for one question and only one of them was ever hardened. This fails if a
    second copy reappears.
    """
    # Comment lines are excluded deliberately: the fix's own comments quote the
    # retired regex verbatim, on purpose, so the next reader knows what was wrong
    # and why. Only executable lines can reintroduce the defect.
    code = "\n".join(
        line
        for line in LIB.read_text().splitlines()
        if not line.lstrip().startswith("#")
    )
    assert "[^>]>[^>]" not in code, "the drifted redirect regex is back"
    assert code.count("_sc_strip_quoted()") == 1


# --------------------------------------------------------------------------
# T-636: the conservative verb scan above meets an argument it must not judge.
#
# `test_destructive_verbs_are_judged_conservatively` documents the asymmetry and
# the price it charges: a quoted mention of a destructive verb reads as a write.
# That price is paid by whoever writes the command, and it is cheap — until the
# command is `fw note`, whose entire argument is prose, and whose prose in this
# project is overwhelmingly ABOUT shell behaviour.
#
# The observed failure: an observation about a runner that `rm -f`s a shared path
# could not be filed, and was refused with "No active task" — the one message
# guaranteed to send the reader to the remedy T-390 added the note exemption to
# avoid. These two blocks pin both sides of the resulting boundary.
# --------------------------------------------------------------------------

PROSE_VERBS_ON_THE_SAFE_LIST = [
    'fw note "the runner greps a shared path and rm -f s it"',
    'fw note "tee writes a second copy"',
    "fw context add-learning \"a census that rm's its own fixture is not idempotent\"",
    'fw context add-pattern failure "rmdir on a non-empty dir"',
    'fw context add-decision "chose tee over a redirect"',
    'fw task create --name "rmdir leaves the parent behind"',
    "bin/fw note \"path-qualified fw still counts\"",
    ".agentic-framework/bin/fw note \"and a deep path with rm in the text\"",
]


@pytest.mark.parametrize("cmd", PROSE_VERBS_ON_THE_SAFE_LIST)
def test_prose_arguments_do_not_veto_their_own_verb(cmd):
    """The framework must be able to record sentences about destructive commands."""
    assert gate_allows(cmd), f"a stored-prose verb was vetoed by its own text: {cmd!r}"


def test_git_commit_message_is_prose_too():
    """`fw git commit` is NOT on the no-task allowlist — the hook admits it by a
    separate branch (T-2054, checkpointing completed work). So the corpus can only
    assert the half that lives in this library: its message must not read as a write.
    Asserting gate_allows here would encode the hook's branch in the wrong file.
    """
    assert not is_write('fw git commit -m "drop the rm -rf call"')


@pytest.mark.parametrize(
    "cmd",
    [
        # Outside the quotes: the exemption scans the STRIPPED string, it does not
        # skip the scan, so a second clause is judged exactly as before.
        'fw note "harmless" && rm -rf /tmp/x',
        'fw note "harmless"; tee /tmp/x',
        # A command substitution IS a route from the argument back to the shell,
        # which is the execution case the asymmetry is actually about.
        'fw note "$(rm -rf /tmp/x)"',
        "fw note \"`rm -rf /tmp/x`\"",
        # Near-misses on the verb list. The set is closed by construction and
        # matched on whole tokens, not prefixes.
        'fw notes-something-else "rm -rf"',
        'fw noteworthy "rm -rf"',
        'fw task update T-1 --status "rm -rf"',
        'fw context add-thing "rm -rf"',
    ],
)
def test_the_prose_exemption_does_not_widen_the_gate(cmd):
    assert is_write(cmd), f"the exemption let a real write through: {cmd!r}"


def test_the_prose_verb_helper_does_not_fork():
    """Same perf contract as test_base_extraction_does_not_fork, for the same
    reason: this helper is called from has_bash_write_pattern, so it runs on every
    Bash tool call. The first draft used three awks and the corpus caught it.
    """
    code = LIB.read_text()
    start = code.index("_sc_is_framework_prose_verb() {")
    body = code[start : code.index("\n}", start)]
    executable = "\n".join(
        line for line in body.splitlines() if not line.lstrip().startswith("#")
    )
    for forking in ("awk ", "sed ", "$(echo", "| cut"):
        assert forking not in executable, f"{forking!r} forks a process per Bash call"


# --------------------------------------------------------------------------
# T-638 — the T-2054 commit exemption admits a command with NO ACTIVE TASK, so
# it is the one predicate here whose false-green is a governance bypass rather
# than an inconvenience. It used to ask whether the command CONTAINED
# `git commit`, unanchored, on the unstripped string.
#
# `commit_only` is the predicate the hook now calls. The end-to-end proof (the
# real hook vs a mutant carrying the old regex) lives in
# tools/_t638-commit-exemption-is-clause-scoped.sh; what is pinned here is the
# predicate's own contract, in the corpus that runs on every change to this lib.
# --------------------------------------------------------------------------


def commit_only(cmd):
    return _call("_sc_is_commit_only_command", cmd)


@pytest.mark.parametrize(
    "cmd",
    [
        # The bare form the exemption exists for.
        'git commit -m "T-1: y"',
        # The project's documented copy-pasteable shape.
        'cd /opt/832-Workflow-designer && git commit -m "T-1: y"',
        # The real post-completion form: `git add` is safe-listed precisely so
        # this composes. A hand-rolled second allowlist would have missed it.
        'git add -A && git commit -m "T-1: y"',
        'git commit -m "T-1: y" && git push',
        # A separator INSIDE the message is message text. This is why the split
        # runs on the quote-stripped command and not the raw one.
        'git commit -m "T-1: msg with ; a semicolon"',
        'git commit -m "T-1: fix a && b"',
    ],
)
def test_real_commits_keep_the_exemption(cmd):
    assert commit_only(cmd), f"a legitimate post-completion form lost the exemption: {cmd!r}"


@pytest.mark.parametrize(
    "cmd",
    [
        # The hole: every clause of a compound command rode in on the first one.
        'git commit -m "T-1: y"; touch /tmp/t638-marker',
        'git commit -m "T-1: y" && touch /tmp/t638-marker',
        # Flagged as a write upstream, then admitted here — the hook's write
        # check falls through rather than exiting, so this branch was its override.
        'git commit -m "T-1: y" | tee /tmp/t638-marker',
        'git commit -m "T-1: y" > /tmp/t638-marker',
        # A QUOTED ARGUMENT that merely says the words. Nothing is committed.
        'someunknownbinary --flag "please git commit this"',
        'echo "remember to git commit" && touch /tmp/t638-marker',
        # Substitution is opaque to a clause check, so it never takes the
        # exemption — same call T-636 made for the prose verbs.
        'git commit -m "$(cat /etc/hostname)"',
        "git commit -m \"`cat /etc/hostname`\"",
        # Not a commit at all.
        "git push",
        "git add -A",
    ],
)
def test_mentions_and_compounds_do_not_get_the_exemption(cmd):
    assert not commit_only(cmd), f"admitted with no active task: {cmd!r}"


def test_a_safe_listed_clause_alongside_the_commit_is_admitted_on_purpose():
    """`git commit … || curl …` IS admitted, and that is the composition rule
    working rather than a hole.

    The predicate's contract is "every clause would be admissible on its own with
    no active task, and at least one is the commit". `curl` is on the safe list,
    so `curl …` alone already passes this gate; pairing it with a commit admits
    nothing new. Writing this down because the natural reading of the block list
    above is that any second clause is suspect, and a future reader "fixing" this
    would break `git add && git commit` by the same stroke.

    Whether `curl` BELONGS on the safe list is a separate question with a real
    answer — `curl -o f` and `wget -O f` write a file with no shell redirect,
    which is exactly the admission rule the list states for itself and applies to
    `awk` and `uniq`. Filed separately; one bug, one task. It is not this
    predicate's defect and must not be fixed by widening this one.
    """
    assert commit_only('git commit -m "T-1: y" || curl http://example.com')
    assert is_safe("curl http://example.com"), (
        "premise of this test: curl is independently safe-listed"
    )


def drift_target(cmd):
    """Return the task _sc_drift_target identifies, or '' for none."""
    script = f'source "{LIB}"; _sc_drift_target "$1"; printf "%s" "$_SC_DRIFT_TARGET"'
    return subprocess.run(
        ["bash", "-c", script, "_", cmd], capture_output=True, text=True
    ).stdout.strip()


@pytest.mark.parametrize(
    "cmd,expected",
    [
        # Genuine targets — the gate's reason to exist.
        ("fw task update T-1 --status issues", "T-1"),
        ("/opt/p/.agentic-framework/bin/fw task update T-42 --status work-completed", "T-42"),
        ('fw context add-learning "x" --task T-7', "T-7"),
        ('git commit -m "T-9: real commit"', "T-9"),
        ("git commit -m 'T-9: single quoted'", "T-9"),
        # T-639: mentions. The command acts on nothing.
        ('echo "the form is: git commit -m \\"T-1: msg\\""', ""),
        ('echo "next run fw task update T-1 --status issues"', ""),
        ('bash tools/probe.sh " git commit -m \\"T-1: fixture\\""', ""),
        ('grep -c " fw task update T-1" tools/t.sh', ""),
        # The id must PREFIX the message. A task named in the body is a reference,
        # not a target — commit-msg enforces the prefix, so that is the definition
        # the rest of the framework already uses.
        ('git commit -m "T-9: supersedes the approach in T-1: see notes"', "T-9"),
        # Not a commit invocation at all, so the -m value is irrelevant.
        ('echo "git commit -m \\"T-1: x\\"" > /dev/null', ""),
    ],
)
def test_drift_target_reads_the_target_not_the_mention(cmd, expected):
    assert drift_target(cmd) == expected, f"wrong drift target for {cmd!r}"


def test_the_drift_predicate_does_not_fork():
    """Third helper on the PreToolUse path, same contract as the other two."""
    code = LIB.read_text()
    start = code.index("_sc_drift_target() {")
    body = code[start : code.index("\n}", start)]
    executable = "\n".join(
        line for line in body.splitlines() if not line.lstrip().startswith("#")
    )
    for forking in ("awk ", "sed ", "$(echo", "| cut", "python3", "grep "):
        assert forking not in executable, f"{forking!r} forks a process per Bash call"


def test_the_commit_predicate_does_not_fork():
    """Same perf contract as the two above — it runs on the PreToolUse path."""
    code = LIB.read_text()
    start = code.index("_sc_is_commit_only_command() {")
    body = code[start : code.index("\n}", start)]
    executable = "\n".join(
        line for line in body.splitlines() if not line.lstrip().startswith("#")
    )
    for forking in ("awk ", "sed ", "$(echo", "| cut", "python3"):
        assert forking not in executable, f"{forking!r} forks a process per Bash call"


def test_the_hook_fails_closed_if_the_predicate_is_missing():
    """The exemption runs with no active task, so an absent predicate must block.

    `source … || true` in the hook means a library that fails to load leaves the
    function undefined; without the `type` guard the `if` would then be a syntax
    -level truth test on the remaining conjuncts rather than a refusal.
    """
    hook = (LIB.parent.parent / "check-active-task.sh").read_text()
    assert "type _sc_is_commit_only_command &>/dev/null" in hook, (
        "the hook must guard the predicate call, and the guard must precede it"
    )
    guard = hook.index("type _sc_is_commit_only_command")
    call = hook.index('_sc_is_commit_only_command "$BASH_CMD"')
    assert guard < call, "the existence guard must run before the call"
