#!/usr/bin/env python3
"""_t352-member-scan.py — T-352 AC2: enumerate the MEMBERS, not the count.

Four populations, and keeping them apart IS the deliverable:

  ALL       every verification line the gate would run, across active/ and completed/.
  SHAPED    those with a top-level `;`, hence structurally judged on their last command
            alone. AN UPPER BOUND, NOT A FINDING. Most pin a zero-failure token and are
            perfectly safe. Reporting SHAPED as the defect count is the overclaim AEF
            warned about at RAIL-403 (theirs ran 4x).
  RUN       the subset actually executed, under both the gate's construct and the remedy.
  PROVEN    RUN lines that PASS today and FAIL under the remedy. Nothing is inferred:
            a member is a member because two runs happened and disagreed.
  LATENT    RUN lines where both constructs AGREE. These are NOT proven safe. They carry
            the same structure; they simply are not failing in the first command today.
            A corpus zero cannot distinguish "the predicates agree" from "nothing made
            the separating input" — the whole population is one upstream breakage away
            from becoming members, and that is the number the operator needs, because it
            is the one that grows silently.

SHAPED minus RUN is a HOLE IN THE DENOMINATOR, not a caveat, and it is reported as such
with the reason. The reason is a deliberate refusal: bulk-executing arbitrary verification
lines from 341 task files is the exact shape that deleted this repository during T-350 (a
harness ran a recursive delete it believed it had stubbed). Lines are executed only when
every token clears a conservative allowlist.

The parser has a SELF-TEST that must pass before any scanning happens. Its first version
incremented depth on `$` and again on the following `(`, so `$(...)` never returned to
depth 0 and every top-level `;` after a command substitution was invisible — it returned
26 where the truth is an order of magnitude higher. A confident undercount reads exactly
like a careful one, so the parser now has to prove it separates both ways before it is
allowed to produce a number.
"""
import os
import re
import signal
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GATE = os.path.join(ROOT, ".agentic-framework/agents/task-create/update-task.sh")


def has_top_level_semicolon(line):
    """True if `line` contains a `;` outside quotes and outside any (…) nesting.

    Written as a parser, not `grep ';'`: a bare grep also matches `sed 's/a;b/c/'` and
    `find … \\;`, which are single commands — the over-broad-matcher error that
    manufactured 21 phantom findings on T-348.
    """
    sq = dq = False
    depth = 0
    esc = False
    for ch in line:
        if esc:
            esc = False
            continue
        if ch == "\\":
            esc = True
            continue
        if sq:
            if ch == "'":
                sq = False
            continue
        if dq:
            if ch == '"':
                dq = False
            elif ch == "(":
                depth += 1
            elif ch == ")" and depth:
                depth -= 1
            continue
        if ch == '"':
            dq = True
        elif ch == "'":
            sq = True
        elif ch == "(":
            # No `$` lookahead: a bare `(` is the only opener that matters in unquoted
            # context, and it already covers `$(`, `(subshell)` and `<(…)`.
            depth += 1
        elif ch == ")":
            if depth:
                depth -= 1
        elif ch == ";" and depth == 0:
            return True
    return False


# ── Parser self-test ───────────────────────────────────────────────────────────────────
# Both directions. A test with only positives passes for a parser that answers True to
# everything, which is the mirror of the bug that actually occurred.
SELFTEST = [
    (True,  'out=$(fw audit 2>&1); echo "$out" | grep -q "Fail: 0"'),
    (True,  'a; b'),
    (True,  'out=$(python3 -c "import x; print(x)"); echo "$out" | grep -q y'),
    (True,  'n=$(ls | wc -l); [ "$n" -eq 3 ]'),
    (False, 'sed -i "s/a;b/c/" file'),
    (False, "find . -name '*.tmp' -exec rm {} \\;"),
    (False, 'grep -q "foo;bar" src/x.html'),
    (False, 'python3 -c "import sys; sys.exit(0)"'),
    (False, 'test -f docs/x.md'),
]


CLASSIFY_SELFTEST = [
    ("ZERO-TOKEN",     'out=$(x 2>&1); echo "$out" | grep -q "0 failed"'),
    ("ZERO-TOKEN",     'out=$(x 2>&1); echo "$out" | grep -q "Fail: 0"'),
    ("SUBSTRING-RISK", 'out=$(x 2>&1); echo "$out" | grep -q "VALID"'),
    ("SUBSTRING-RISK", 'out=$(x 2>&1); echo "$out" | grep -q "OK"'),
    ("OTHER",          'out=$(x 2>&1); echo "$out" | grep -q "showProjectPreview"'),
    ("NO-PATTERN",     'a=$(x); [ -n "$a" ]'),
]


def classify_selftest():
    bad = [(w, l, classify(l)[0]) for w, l in CLASSIFY_SELFTEST if classify(l)[0] != w]
    if bad:
        for w, l, got in bad:
            sys.stderr.write("CLASSIFY SELFTEST FAIL: wanted %s got %s for: %s\n" % (w, got, l))
        sys.stderr.write("The static classifier does not separate its known cases; its "
                         "partition would be unsound, so nothing is reported.\n")
        sys.exit(1)
    print("classifier self-test: %d/%d" % (len(CLASSIFY_SELFTEST), len(CLASSIFY_SELFTEST)))


def selftest():
    bad = [(want, s) for want, s in SELFTEST if has_top_level_semicolon(s) != want]
    if bad:
        for want, s in bad:
            sys.stderr.write("SELFTEST FAIL: expected %s for: %s\n" % (want, s))
        sys.stderr.write(
            "The top-level-semicolon parser does not separate the known cases. Every count "
            "below would be unsound, so nothing is reported.\n")
        sys.exit(1)
    print("parser self-test: %d/%d (both directions)" % (len(SELFTEST), len(SELFTEST)))


# ── Extraction: the gate's own sed range ───────────────────────────────────────────────
# update-task.sh:975 verbatim. That idiom has a known defect — when `## Verification` is a
# file's LAST section the range runs to EOF and `sed '$d'` deletes the final command (AEF's
# RAIL-397 finding). Reproducing it is deliberate: a scan with a WIDER scope than the gate
# would report lines the gate never runs.
def verification_lines(path):
    out = subprocess.run(
        ["sed", "-n", "/^## Verification/,/^## /p", path],
        capture_output=True, text=True).stdout.splitlines()
    if out:
        out = out[:-1]
    keep = []
    for line in out:
        s = line.strip()
        if not s or s.startswith("#") or s.startswith("## "):
            continue
        keep.append(s)
    return keep


# ── Safety filter ──────────────────────────────────────────────────────────────────────
# Refusal is the default. A line is executed only if NO token matches anything that can
# mutate state, reach the network, or start a process that outlives the run.
FORBIDDEN = re.compile(
    r"(^|[\s;|&(`])("
    r"rm|rmdir|mv|cp|install|dd|truncate|tee|mkdir|touch|chmod|chown|ln|"
    r"git|gh|curl|wget|nc|ssh|scp|rsync|"
    r"npm|npx|node|yarn|pnpm|pip|pip3|cargo|go|dotnet|mvn|make|"
    r"kill|pkill|killall|nohup|systemctl|service|docker|"
    r"fw|serve-gallery\.sh|python3?\s+-m\s+http\.server"
    r")([\s;|&)`]|$)")
REDIRECT = re.compile(r"(?<![0-9<>])>{1,2}(?!&)")


def is_safe(line):
    if FORBIDDEN.search(line):
        return False, "invokes a state-changing or network command"
    for m in REDIRECT.finditer(line):
        tail = line[m.end():].strip().split()
        if tail and tail[0].startswith("/dev/null"):
            continue
        return False, "redirects to a file"
    if ".agentic-framework/bin" in line:
        return False, "invokes framework tooling"
    return True, ""



# ── Static classification of the final clause ─────────────────────────────────────────
# Decidable, no execution, and it is what AC2 asks for directly: separate the lines that
# pin a zero-failure token (safe by construction — a failing run does not print "0 failed")
# from the lines whose pattern could match their own command's FAILURE output.
#
# The sharpest sub-class is SUBSTRING-RISK: a pattern that is a proper substring of a token
# meaning the opposite. `grep -q "VALID"` matches `INVALID`; `grep -q "OK"` matches `NOT OK`.
# This is the class that produced the live false green, and it is decidable from the text.
ZERO_FAILURE = re.compile(
    r"(0 fail|0 error|0 warn|fail(ure)?s?:?\s*0|error(s)?:?\s*0|, 0 |no (errors|failures))", re.I)
# The first version of this rule generated negations by prefixing ("IN" + pat) and asked
# whether pat was a substring of the result. That is ALWAYS true — prefixing never removes
# the original — so every pattern scored SUBSTRING-RISK and the class discriminated nothing.
# Its own self-test caught it. Replaced with an EXPLICIT vocabulary of verdict words whose
# denial contains them. A vocabulary UNDER-approximates: it can miss a pattern nobody listed,
# but it cannot invent one. For a findings list that is the correct direction to err — the
# T-348 lesson, where an over-broad matcher manufactured 21 findings before finding any.
DENIABLE = {
    "VALID": "INVALID", "OK": "NOT OK", "CORRECT": "INCORRECT",
    "COMPLETE": "INCOMPLETE", "CONSISTENT": "INCONSISTENT", "ACTIVE": "INACTIVE",
    "FOUND": "NOT FOUND", "SUPPORTED": "UNSUPPORTED", "AVAILABLE": "UNAVAILABLE",
    "CHANGED": "UNCHANGED", "RESOLVED": "UNRESOLVED", "USED": "UNUSED",
    "MATCH": "NO MATCH", "PRESENT": "NOT PRESENT", "REGISTERED": "UNREGISTERED",
}


def final_pattern(line):
    """The pattern of the last grep/test clause on the line, or None."""
    m = None
    for m in re.finditer(r"""grep\s+(?:-\w+\s+)*["']([^"']+)["']""", line):
        pass
    if m:
        return m.group(1)
    m = None
    for m in re.finditer(r"""test\s+"?\$\w+"?\s*=\s*["']?([^"'\s]+)""", line):
        pass
    return m.group(1) if m else None


def classify(line):
    pat = final_pattern(line)
    if pat is None:
        return "NO-PATTERN", "final clause is not a grep/test comparison"
    if ZERO_FAILURE.search(pat):
        return "ZERO-TOKEN", "pins a zero-failure token (%r) — NOT a finding" % pat
    up = pat.strip().upper()
    for word, denial in DENIABLE.items():
        if up == word and word in denial.replace(" ", "") + denial:
            return "SUBSTRING-RISK", (
                "pattern %r also matches %r — the grep cannot distinguish the claim from "
                "its denial" % (pat, denial))
    return "OTHER", "pattern %r — needs execution to classify" % pat


# ── Gate constructs, extracted rather than copied (same rule as the probe) ─────────────
def gate_condition():
    hits = [l for l in open(GATE).read().splitlines() if re.match(r"^\s*if .*\$cmd", l)]
    if len(hits) != 1:
        sys.stderr.write("EXTRACT_ERROR: found %d gate lines, expected 1\n" % len(hits))
        sys.exit(1)
    line = hits[0].strip()
    line = re.sub(r"^if\s+", "", line)
    line = re.sub(r";\s*then$", "", line)
    return line


def run_under(cond, cmd, timeout=8):
    """Run one verification line under `cond`. Returns 'PASS' | 'FAIL' | 'TIMEOUT' | 'BROKEN'.

    Uses an explicit process GROUP, not subprocess.run(timeout=…). The first version used
    the latter and both leaked and deadlocked: on timeout, subprocess.run kills only the
    direct child, then blocks in communicate() waiting for stdout EOF — which the surviving
    grandchild subshell still holds open. Runner processes accumulated for minutes past
    their timeout and the scan never finished.

    Same defect class as T-351: a stop path that assumes the thing it is stopping cooperates.
    start_new_session puts the runner in its own group so killpg reaches the whole tree, and
    the pipe is closed before the wait so nothing can hold it open.
    """
    script = "\n".join([
        "#!/usr/bin/env bash",
        "set -euo pipefail",                # update-task.sh:14, verbatim
        '_close_locks_cmd=""',
        "PROJECT_ROOT=%s" % subprocess.list2cmdline([ROOT]),
        'cmd="$CMD_UNDER_TEST"',
        "if %s; then echo GATE_PASS; else echo GATE_FAIL; fi" % cond,
    ])
    env = dict(os.environ, CMD_UNDER_TEST=cmd)
    p = subprocess.Popen(["bash", "-c", script], stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, text=True, env=env, cwd=ROOT,
                         start_new_session=True)
    try:
        out, _ = p.communicate(timeout=timeout)
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
        try:
            if p.stdout:
                p.stdout.close()
        except Exception:
            pass
        return "TIMEOUT"
    tail = (out or "").strip().splitlines()
    if not tail:
        return "BROKEN"
    return {"GATE_PASS": "PASS", "GATE_FAIL": "FAIL"}.get(tail[-1], "BROKEN")


def main():
    selftest()
    classify_selftest()
    cond_a = gate_condition()
    cond_c = cond_a.replace('eval "$cmd"',
                            'bash -c \'set -eo pipefail; eval "$1"\' _ "$cmd"')
    if cond_c == cond_a:
        sys.stderr.write("EXTRACT_ERROR: could not derive the remedy form from the gate line\n")
        sys.exit(1)

    files = []
    for sub in ("active", "completed"):
        d = os.path.join(ROOT, ".tasks", sub)
        if os.path.isdir(d):
            files += [os.path.join(d, f) for f in sorted(os.listdir(d)) if f.endswith(".md")]

    all_lines, shaped = [], []
    for path in files:
        tid = re.match(r"(T-\d+)", os.path.basename(path))
        tid = tid.group(1) if tid else "?"
        for line in verification_lines(path):
            all_lines.append((tid, line))
            if has_top_level_semicolon(line):
                shaped.append((tid, line))

    classes = {}
    for tid, line in shaped:
        k, why = classify(line)
        classes.setdefault(k, []).append((tid, line, why))

    # Wall-clock budget. Whatever it cuts off is reported as unrun, never as clean.
    budget_s = float(os.environ.get("T352_BUDGET_S", "600"))
    started = time.monotonic()

    # Identical command strings recur across tasks (164 unique among 243 safe lines).
    # They are deterministic checks in a fixed tree, so the verdict is a function of the
    # string — memoise it. This is not an approximation: it is the same command.
    cache = {}
    proven, latent, skipped, anomalies, unrun = [], [], [], [], []
    for i, (tid, line) in enumerate(shaped):
        safe, why = is_safe(line)
        if not safe:
            skipped.append((tid, line, why))
            continue
        if time.monotonic() - started > budget_s:
            unrun.append((tid, line, "wall-clock budget exhausted"))
            continue
        if line in cache:
            a, c = cache[line]
        else:
            print("  [%d/%d] %s %s" % (i + 1, len(shaped), tid, line[:70]), flush=True)
            a = run_under(cond_a, line)
        # Only run the remedy form when the gate currently PASSES. A line already failing
        # cannot be a member — it is not producing a false green — and skipping it halves
        # the wall clock without changing any verdict.
            c = run_under(cond_c, line) if a == "PASS" else "n/a"
            cache[line] = (a, c)
        if a == "PASS" and c == "FAIL":
            proven.append((tid, line))
        elif a in ("TIMEOUT", "BROKEN") or c in ("TIMEOUT", "BROKEN"):
            anomalies.append((tid, line, a, c))
        else:
            latent.append((tid, line, a, c))

    print("")
    print("static partition of the %d SHAPED lines (no execution, decidable):" % len(shaped))
    for k in ("SUBSTRING-RISK", "ZERO-TOKEN", "OTHER", "NO-PATTERN"):
        print("   %-15s %d" % (k, len(classes.get(k, []))))
    print("")
    print("ALL     = %d   every verification line the gate would run" % len(all_lines))
    print("SHAPED  = %d   top-level ';' — UPPER BOUND, NOT A FINDING" % len(shaped))
    print("RUN     = %d   executed under both constructs" % (len(proven) + len(latent) + len(anomalies)))
    print("PROVEN  = %d   PASS today, FAIL under the remedy — THIS IS THE FINDING" % len(proven))
    print("LATENT  = %d   both constructs agree — NOT proven safe, just not failing today" % len(latent))
    print("SKIPPED = %d   refused by the safety filter — a hole, not a caveat" % len(skipped))
    print("UNRUN   = %d   wall-clock budget exhausted — also a hole" % len(unrun))
    print("ANOMALY = %d   timed out or produced no verdict" % len(anomalies))
    print("")
    for tid, line in proven:
        print("  PROVEN  %-8s %s" % (tid, line[:150]))
    for tid, line, a, c in anomalies:
        print("  ANOMALY %-8s A=%s C=%s  %s" % (tid, a, c, line[:120]))

    report = os.path.join(ROOT, "docs/reports/T-352-member-scan.md")
    os.makedirs(os.path.dirname(report), exist_ok=True)
    with open(report, "w") as fh:
        fh.write("# T-352 AC2 — member scan\n\n")
        fh.write("Generated by `tools/_t352-member-scan.py`. Populations, not counts:\n\n")
        fh.write("| population | n | meaning |\n|---|---:|---|\n")
        fh.write("| ALL | %d | every verification line the gate would run (active + completed) |\n" % len(all_lines))
        fh.write("| SHAPED | %d | top-level `;` — **upper bound, not a finding** |\n" % len(shaped))
        fh.write("| RUN | %d | executed under both the gate's construct and the remedy |\n" % (len(proven) + len(latent) + len(anomalies)))
        fh.write("| **PROVEN** | **%d** | **PASS today, FAIL under the remedy — this is the finding** |\n" % len(proven))
        fh.write("| LATENT | %d | both constructs agree — **not proven safe**, merely not failing today |\n" % len(latent))
        fh.write("| SKIPPED | %d | refused by the safety filter — a hole in the denominator |\n" % len(skipped))
        fh.write("| ANOMALY | %d | timed out or produced no verdict |\n" % len(anomalies))
        fh.write("| UNRUN | %d | wall-clock budget exhausted before reaching these |\n" % len(unrun))
        fh.write("\n## Static partition of the SHAPED lines (decidable, no execution)\n\n")
        fh.write("| class | n | meaning |\n|---|---:|---|\n")
        fh.write("| **SUBSTRING-RISK** | %d | final pattern also matches its own denial (the `VALID`/`INVALID` class) — **this is the finding shape** |\n" % len(classes.get("SUBSTRING-RISK", [])))
        fh.write("| ZERO-TOKEN | %d | pins a zero-failure token — **explicitly NOT findings** |\n" % len(classes.get("ZERO-TOKEN", [])))
        fh.write("| OTHER | %d | pattern needs execution to classify |\n" % len(classes.get("OTHER", [])))
        fh.write("| NO-PATTERN | %d | final clause is not a grep/test comparison |\n" % len(classes.get("NO-PATTERN", [])))
        fh.write("\n### SUBSTRING-RISK members\n\n")
        for tid, line, why in classes.get("SUBSTRING-RISK", []):
            fh.write("- **%s** — %s\n  `%s`\n" % (tid, why, line))
        if not classes.get("SUBSTRING-RISK"):
            fh.write("_none_\n")
        fh.write("\n## PROVEN members\n\n")
        if proven:
            for tid, line in proven:
                fh.write("- **%s** — `%s`\n" % (tid, line))
        else:
            fh.write("_none_\n")
        fh.write("\n## ANOMALY\n\n")
        for tid, line, a, c in anomalies or []:
            fh.write("- **%s** (A=%s, C=%s) — `%s`\n" % (tid, a, c, line))
        if not anomalies:
            fh.write("_none_\n")
        fh.write("\n## LATENT — ran, both constructs agreed\n\n")
        fh.write("These are **not clean**. Each carries the `a; b` structure; the first command\n"
                 "simply succeeds today. If it ever starts failing, the line keeps reporting PASS\n"
                 "and nothing announces the change. Agreement here measures the corpus, not the rule.\n\n")
        for tid, line, a, c in latent:
            fh.write("- %s (%s/%s) — `%s`\n" % (tid, a, c, line))
        fh.write("\n## SKIPPED — not measured, and why\n\n")
        fh.write("Bulk-executing arbitrary verification lines is the shape that deleted this\n"
                 "repository during T-350. Refusal is the default; these were never run, so\n"
                 "their status is **unknown**, not **clean**.\n\n")
        for tid, line, why in skipped:
            fh.write("- %s (%s) — `%s`\n" % (tid, why, line))
        fh.write("\n## UNRUN — budget exhausted, status unknown\n\n")
        for tid, line, why in unrun or []:
            fh.write("- %s — `%s`\n" % (tid, line))
        if not unrun:
            fh.write("_none — the budget covered every safe line_\n")
    print("report: docs/reports/T-352-member-scan.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
