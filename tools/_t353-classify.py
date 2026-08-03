#!/usr/bin/env python3
"""T-353 AC2 — classify each DIVERGENT verification line by MEASUREMENT.

The DIVERGENT bucket from T-352 ("passes under the current gate, fails under the
remedy") aggregates two causes pointing opposite ways:

  * a CORRECT failure-path test  — the first command exits non-zero BY DESIGN and
    the assertion is about that designed failure.  The remedy breaks it, and that
    break is a regression, not a fix.
  * a GENUINE false green        — the first command failed for a reason nobody
    intended (missing file, traceback, usage error) and the assertion matched
    anyway, or the assertion pattern matches its own denial.

Reading the lines separates them.  Reading is also how you talk yourself into a
conclusion, so this classifies by running the head command and inspecting what
came back.

THE INSTRUMENT MUST DISCRIMINATE.  Three controls run first and must land in
three DIFFERENT buckets; if any two collide, the classifier is inert and the
script exits non-zero before emitting a single verdict about a real line.
(T-352 shipped a classifier whose every answer was the same answer.)

Members are EXTRACTED from the scan report, never retyped: a retyped corpus stops
tracking the subject the moment the subject changes.
"""

import os
import re
import signal
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORT = os.path.join(ROOT, "docs", "reports", "T-352-member-scan.md")

# ── Output shapes that mean "this command did not get far enough to have an
#    opinion".  A pattern matched against one of these is matched against noise.
#    The last three are taken from validate-workflow.py's OWN output on a missing
#    file (`ERROR [E-LOAD] <path>: file not found`) rather than invented — the
#    generic "No such file or directory" never appears, so a vocabulary built by
#    imagining error text missed the one tool this corpus actually calls.
ERROR_MARKERS = [
    "Traceback (most recent call last)",
    "No such file or directory",
    "command not found",
    "usage:",
    "Usage:",
    "SyntaxError",
    "ModuleNotFoundError",
    "IsADirectoryError",
    "Permission denied",
    "cannot open",
    "E-LOAD",
    "file not found",
    "E-XML-PARSE",
]

# ── Verdict words whose negation CONTAINS them, so `grep -q WORD` matches the
#    denial too.  Explicit vocabulary, not a generated rule: it under-approximates
#    (can miss one nobody listed, cannot invent one).  T-352 shipped a generated
#    rule that flagged everything.
SELF_DENYING = {
    "VALID": "INVALID",
    "OK": "NOT OK",
    "CORRECT": "INCORRECT",
    "COMPLETE": "INCOMPLETE",
    "CONSISTENT": "INCONSISTENT",
    "ACTIVE": "INACTIVE",
    "FOUND": "NOT FOUND",
    "SUPPORTED": "UNSUPPORTED",
    "AVAILABLE": "UNAVAILABLE",
    "RESOLVED": "UNRESOLVED",
    "MATCH": "NO MATCH",
    "PRESENT": "NOT PRESENT",
}

FORBIDDEN = re.compile(
    r"\b(rm|mv|cp|git|curl|wget|npm|pip|kill|pkill|chmod|chown|dd|mkfs|"
    r"shutdown|reboot|systemctl|fw|truncate|tee)\b"
)


def split_head_tail(line):
    """Split a line at its LAST top-level `;`.

    Quote- and paren-aware.  A bare `(` is the only opener that matters in
    unquoted context and it already covers `$(`, `(subshell)` and `<(…)` — the
    T-352 parser incremented on `$` AND on the following `(`, so `$(…)` never
    returned to depth 0 and every top-level `;` after a command substitution was
    invisible.  That bug read as a careful correction (332 -> 26).
    """
    sq = dq = False
    depth = 0
    cuts = []
    i = 0
    while i < len(line):
        ch = line[i]
        if sq:
            if ch == "'":
                sq = False
        elif dq:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                dq = False
        elif ch == "\\":
            i += 2
            continue
        elif ch == "'":
            sq = True
        elif ch == '"':
            dq = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            if depth:
                depth -= 1
        elif ch == ";" and depth == 0:
            cuts.append(i)
        i += 1
    if not cuts:
        return line.strip(), ""
    return line[: cuts[-1]].strip(), line[cuts[-1] + 1 :].strip()


def capture_var(line):
    """Name of the variable the line captures output into, if it does.

    The head of every member is an ASSIGNMENT (`out=$(cmd 2>&1)`), so its own
    stdout is empty by construction — the output went into the variable.  An
    earlier revision of this file ran the head and inspected its stdout, which is
    why all three controls collapsed into "pattern absent".  Reading the variable
    is the only way to see what the assertion was actually matched against.
    """
    m = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)=\$\(", line)
    return m.group(1) if m else None


def assertion_patterns(tail):
    """Patterns the tail asserts.  Under-approximates by design."""
    pats = []
    for m in re.finditer(r"grep\s+(?:-\w+\s+)*(-q|-c)\s+(\"([^\"]*)\"|'([^']*)')", tail):
        pats.append(m.group(3) if m.group(3) is not None else m.group(4))
    return pats


def pattern_matches(pat, text):
    """Ask GREP whether the pattern matches, instead of reimplementing grep.

    These are grep BREs, not literals: `\\[E-XML-AUTHORITY\\]` matches the text
    `[E-XML-AUTHORITY]`.  A Python `pat in text` test says no — and three real,
    correct lines were reported as ASSERTION-UNMET on that basis before this
    used the subject's own matcher.
    """
    p = subprocess.run(
        ["grep", "-q", "--", pat],
        input=text,
        text=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return p.returncode == 0


def run(script, timeout=45):
    """Run in its own process group and kill the GROUP on timeout.

    subprocess.run(timeout=) kills only the direct child, then blocks in
    communicate() on a stdout EOF the surviving grandchild subshell still holds
    open — it leaked runners for minutes in T-352 and never returned.
    """
    env = dict(os.environ)
    env.pop("TASKS_DIR", None)
    env.pop("CONTEXT_DIR", None)
    env.pop("_FW_PATHS_LOADED", None)
    p = subprocess.Popen(
        ["bash", "-c", script],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        env=env,
        cwd=ROOT,
        start_new_session=True,
    )
    try:
        out, _ = p.communicate(timeout=timeout)
        return p.returncode, out
    except subprocess.TimeoutExpired:
        for sig in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(os.getpgid(p.pid), sig)
            except (ProcessLookupError, PermissionError):
                break
            try:
                p.wait(timeout=3)
                break
            except subprocess.TimeoutExpired:
                continue
        return None, "<TIMEOUT>"


SENTINEL = "T353_FAILED_AT:"


def which_command_diverges(line):
    """Run the line under the REMEDY construct and report the command that fails.

    This measures divergence directly instead of guessing which command the gate
    discards.  `$BASH_COMMAND` inside an ERR trap names the failing command, so
    the answer is the subject's own report rather than my parse of it.
    """
    script = (
        "set -eo pipefail\n"
        "trap 'echo \"%s $BASH_COMMAND\" >&2' ERR\n" % SENTINEL
    ) + line + "\n"
    rc, out = run(script)
    if rc is None:
        return None, "<TIMEOUT>"
    failed_at = None
    for ln in out.splitlines():
        if ln.startswith(SENTINEL):
            failed_at = ln[len(SENTINEL) :].strip()
            break
    return rc, failed_at


def captured_output(line):
    """What the assertion was matched against — the value of the capture variable."""
    var = capture_var(line)
    if not var:
        return None
    rc, out = run(line + '\nprintf "%%s" "${%s}"' % var)
    return out if rc is not None else None


def classify(line):
    """Return (verdict, detail).  Verdicts are mutually exclusive by construction."""
    if FORBIDDEN.search(line):
        return "SKIPPED", "matches the safety filter; not executed"

    _head, tail = split_head_tail(line)
    if not tail:
        return "NOT-SHAPED", "no top-level ';' — the gate's construct cannot mis-judge it"

    rc, failed_at = which_command_diverges(line)
    if rc is None:
        return "ANOMALY", "line timed out under the remedy construct"
    if rc == 0:
        return "NOT-DIVERGENT", "line passes under the remedy too — nothing to convert"

    out = captured_output(line)
    if out is None:
        return (
            "FAILURE-PATH-CORRECT",
            "diverges at %r; no capture variable to inspect, so the assertion could "
            "not be re-checked against its input" % failed_at,
        )

    pats = assertion_patterns(tail)

    # Checked FIRST: a pattern matching its own denial is a false green even when
    # the command exits zero, so exit status cannot rule it out.
    for p in pats:
        for word, denial in SELF_DENYING.items():
            if p.strip() == word and denial in out:
                return (
                    "FALSE-GREEN-SUBSTRING",
                    "asserts %r; the output contains its denial %r, which %r matches "
                    "as a substring — the assertion is true of a document that FAILED"
                    % (p, denial, p),
                )

    err = next((m for m in ERROR_MARKERS if m in out), None)
    # A line may assert the load/parse failure ON PURPOSE.  If the assertion
    # names the marker, the diagnostic IS the result under test and the line is a
    # deliberate failure-path test, not a pattern matched against noise.
    deliberate = err is not None and any(
        err in p or p in err for p in pats if p.strip()
    )
    if err and not deliberate:
        return (
            "FALSE-GREEN-ERROROUT",
            "diverges at %r, and the output carries %r — the assertion is matched "
            "against a diagnostic, not against a result the command meant to produce"
            % (failed_at, err),
        )

    if pats and not any(pattern_matches(p, out) for p in pats):
        return (
            "ASSERTION-UNMET",
            "diverges at %r and none of %r appear in the captured output"
            % (failed_at, pats),
        )

    return (
        "FAILURE-PATH-CORRECT",
        "diverges at %r, which produced a normal report, and the assertion %r is "
        "true of it — the non-zero exit IS the condition under test"
        % (failed_at, pats or "<no literal pattern>"),
    )


# ── CONTROLS.  Three fabricated lines that MUST land in three different buckets.
#    Two colliding means the classifier cannot tell the causes apart, which is
#    precisely the defect this task exists to resolve.
CONTROLS = [
    (
        "pos/substring",
        'out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); echo "$out" | grep -q "VALID"',
        "FALSE-GREEN-SUBSTRING",
    ),
    (
        "pos/errorout",
        'out=$(python3 tools/validate-workflow.py /nonexistent/t353-no-such-file.bpmn 2>&1); echo "$out" | grep -q "t353-no-such-file"',
        "FALSE-GREEN-ERROROUT",
    ),
    (
        "neg/correct",
        'out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); echo "$out" | grep -q "E-XML-NODE-TYPE"',
        "FAILURE-PATH-CORRECT",
    ),
    # Proves ASSERTION-UNMET is still REACHABLE after the matcher was switched to
    # real grep.  Without it, a bucket that can never fill and a bucket that
    # legitimately came up empty are indistinguishable — and the switch was made
    # precisely because that bucket had been filling wrongly.
    (
        "neg/unmet",
        'out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); echo "$out" | grep -q "ZZZ-T353-NEVER-APPEARS"',
        "ASSERTION-UNMET",
    ),
]


def run_controls():
    print("== CONTROLS (must occupy %d distinct buckets) ==" % len(CONTROLS))
    seen = {}
    ok = True
    for name, line, expected in CONTROLS:
        verdict, detail = classify(line)
        mark = "ok " if verdict == expected else "FAIL"
        if verdict != expected:
            ok = False
        print("  [%s] %-16s expected %-24s got %s" % (mark, name, expected, verdict))
        if verdict in seen:
            print(
                "  [FAIL] control collision: %r and %r both classify %s"
                % (seen[verdict], name, verdict)
            )
            ok = False
        seen[verdict] = name
    if len(seen) < len(CONTROLS):
        print(
            "  [FAIL] controls occupy %d distinct buckets, need %d"
            % (len(seen), len(CONTROLS))
        )
        ok = False
    if not ok:
        print("\nCONTROLS FAILED — the classifier does not discriminate. No verdicts emitted.")
        sys.exit(1)
    print("  controls: %d/%d, %d distinct buckets\n" % (len(CONTROLS), len(CONTROLS), len(seen)))


def extract_members():
    """Pull the DIVERGENT members out of the scan report rather than retyping them."""
    if not os.path.exists(REPORT):
        print("EXTRACT_ERROR: %s not found" % REPORT)
        sys.exit(1)
    text = open(REPORT).read()
    m = re.search(r"^## PROVEN members$(.*?)^## ", text, re.M | re.S)
    if not m:
        print("EXTRACT_ERROR: could not locate the '## PROVEN members' section")
        sys.exit(1)
    members = []
    for line in m.group(1).splitlines():
        mm = re.match(r"^-\s+\*\*(T-\d+)\*\*\s+—\s+`(.*)`\s*$", line)
        if mm:
            members.append((mm.group(1), mm.group(2)))
    if not members:
        print("EXTRACT_ERROR: section found but no members parsed")
        sys.exit(1)
    return members


def main():
    run_controls()
    members = extract_members()
    print("== DIVERGENT members: %d extracted from the scan report ==\n" % len(members))
    tally = {}
    for task, line in members:
        verdict, detail = classify(line)
        tally[verdict] = tally.get(verdict, 0) + 1
        print("%-24s %s" % (verdict, task))
        print("    line:   %s" % line)
        print("    reason: %s\n" % detail)
    print("== TALLY ==")
    for k in sorted(tally):
        print("  %-24s %d" % (k, tally[k]))
    print("\n  total %d" % len(members))


if __name__ == "__main__":
    main()
