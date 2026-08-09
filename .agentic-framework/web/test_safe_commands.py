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
