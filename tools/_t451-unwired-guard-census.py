#!/usr/bin/env python3
"""_t451-unwired-guard-census.py — how many tools/ instruments have no live caller.

A `## Verification` block is a ONE-SHOT COMPLETION GATE, not a standing guard.
P-011 executes a task's Verification block on the `--status work-completed`
transition and at no other time. So an instrument whose only call site is a task's
Verification block runs exactly once — at that task's completion — and never again.
Once the task moves to `.tasks/completed/`, the instrument is not merely unrun; it is
unrunnable by anything in the tree, while still reading as a wired guard to anyone
who greps for its name and finds a Verification line.

PL-148 (T-426) named this mechanism from three anecdotes and called one of them
"exiting 1 into a void". T-450 hit the fourth — `_norec-verify.py`, the operator's
approvals-queue guard, whose only caller was `.tasks/completed/T-236-*.md`. It last
ran on 2026-07-22 with the queue at 0 NO-REC; the queue is now 14, and nothing in the
tree was in a position to notice. Nobody had ever counted the class. This counts it.

WHAT IS AND IS NOT A FINDING
Not every one-shot is a defect. `*-teeth.sh` and `*-mutation-check.sh` are mutation
tests: they exist to prove a guard HAS teeth at the moment it is authored, and running
them once is the whole point. A standing guard is different — it asserts an invariant
that can regress tomorrow. This tool does NOT try to tell them apart per file, because
that distinction is intent, and guessing at intent produces the confident-but-unfounded
verdict T-440 was about. It splits by naming convention, reports both counts, and
leaves the judgement to a reader who can see which is which.

EXIT CODES
  0  every standing-guard instrument has a live caller
  1  at least one non-teeth instrument has no live caller
  2  a side could not be enumerated — nothing was measured, and this is NOT a pass

`--json` emits the gauge envelope `lib/gaps.py` reads for one-click gap closure, and
deliberately exits 0 for BOTH verdicts, putting READY/NOT_READY in the payload. The
gauge maps any non-zero exit to UNKNOWN, so exiting 1 on findings would make "measured,
and the answer is no" indistinguishable from "the gauge is broken" — collapsing the
abstention channel this census exists to keep open. Refusal still exits 2, which the
gauge reads as UNKNOWN, and that mapping is correct: a refusal IS a gauge that could
not measure.

DERIVED, NOT RESTATED (PL-158)
Both sides come from the tree: the population is `tools/*`, the live-caller set is the
REACHABILITY CLOSURE from roots that re-execute without a task completing. No count
appears as a literal in this file. A written-down denominator is wrong the next time
anyone adds a tool, and a guard that restates its own denominator is the defect one
level up.

CLOSURE, NOT A ONE-HOP UNION (T-493)
Liveness is computed from ROOT_SOURCES outward. `tools/*` is an edge, never a root: a
tool is live only if a non-tool source reaches it, directly or through other tools that
are themselves live. The earlier version unioned every tool-to-tool reference in one
pass, which made reachability transitive through DEAD nodes and let a cluster of dead
instruments vouch for each other. That is a scan that always answers — the class this
whole file exists to count, one level up, inside the counter.

LIMIT — state it, never imply coverage (PL-148's own prescribed remedy)
Reachability is decided by TEXTUAL reference, and that cuts BOTH ways. The limit used
to be stated in one direction only, which made the statement itself the same shape as
the defect it was warning about.

  FALSE POSITIVE (reported unwired, actually reachable)
    A caller that composes a tool's path at runtime, or invokes it through a variable,
    is invisible here. This census cannot close that direction from outside.

  FALSE NEGATIVE (reported live, actually unreachable)   <- T-493 stated, T-495 CLOSED
    Prose about a tool used to count as a call to it, in two lexically different forms:
    a `#` comment (46 of 115 tool-to-tool reference lines when T-493 measured) and a
    STRING LITERAL. T-495 removes both — see strip_prose() — so an edge now has to come
    from an executable position. What remains open is narrower and stated below.

  STILL OPEN after T-495, in the same dangerous direction
    * A shell HEREDOC body is executable text to the parser and prose to a reader.
      `cat <<'LIMITS' ... LIMITS` naming a tool still reads as an edge. Not attempted:
      heredoc tracking needs a shell parser, and a half-implemented one would be the
      guess-shaped instrument this census exists to count.
    * Markdown, YAML and JSON roots are read WHOLE. `strip_prose` returns an
      unrecognised extension unchanged rather than guessing at its comment syntax.
    * A shell string spanning multiple lines re-opens quote state per line.
"""
import ast
import glob
import io
import os
import re
import sys
import tokenize

TOOL_RE = re.compile(r'tools/([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))')
EXT = ('py', 'sh', 'mjs', 'js')

# ROOTS: every path that re-executes WITHOUT a task completing AND is not itself a tool.
# This list is the authority the "wired" verdict is measured against — adding a wiring
# mechanism to the project means adding it here, and a mechanism absent from this list
# reports its tools as unwired, which is the safe direction.
#
# T-493: `tools/*` USED TO BE IN THIS LIST and that was the defect. Liveness was then a
# one-hop union — any tool named inside any tool read as reachable — so a tool referenced
# only by a DEAD tool was reported wired. Reachability is not transitive through dead
# nodes. `tools/*` is now a traversal EDGE (see main()), walked only from tools already
# known live, never a root. Measured at the time of the fix: 71 tools live under the flat
# union, 49 under the closure, 22 of the difference vouched for only by dead tools —
# `_t400-schema-teeth.sh` was referenced by nine dead teeth scripts, so nine dead things
# made one dead thing look alive.
ROOT_SOURCES = (
    '.claude/settings.json',                      # PreToolUse/PostToolUse hooks
    '.context/cron/*',                            # scheduled
    'tests/**/*',                                 # the test suites
    '.agentic-framework/agents/**/*.sh',          # framework agent scripts
)

# The gap register is a root, but only in the ONE field the framework executes.
# `lib/gaps.py` docstring/run_closure_gauge: the gauge command is `closure_check_command:`
# and nothing else. This file used to be grepped WHOLE, so a tool named anywhere in a
# gap's narrative prose read as wired — and that is exactly how T-492 found
# `_t418-producer-attribution.py` looking reachable: its name sits in `.concerns[25]
# .context`, a 2,362-character paragraph DESCRIBING A MEASUREMENT IT ONCE PERFORMED.
# A record of a past measurement is not the capacity to measure.
#
# Same defect as AEF's `next_id()` grepping `OBS-[0-9]+` over an inbox's message bodies,
# reported to them at rail 607 — in our own file, one day later.
GAUGE_FILE = '.context/project/concerns.yaml'
GAUGE_FIELD = 'closure_check_command'

# Instruments that are one-shot BY DESIGN. Teeth prove a guard can fail at authoring
# time; a mutation-check proves a check notices a mutation. Both are complete once they
# have run. Held as a naming convention rather than a per-file judgement, and reported
# separately so a reader can see exactly what was excused and disagree with it.
ONE_SHOT_BY_DESIGN = ('-teeth.sh', '-teeth.py', '-mutation-check.sh',
                      '-probe.sh', '-probe.py', '-probe.mjs')


def refuse(msg):
    """Stop without a verdict. Exit 2, never 0, never 1 (T-430 abstention discipline)."""
    sys.stderr.write('REFUSING: ' + msg + '\nNothing was measured; this is not a pass.\n')
    raise SystemExit(2)


# ── T-495: an edge must come from an EXECUTABLE position ────────────────────────────
# Reachability is textual, so prose ABOUT a tool was indistinguishable from a call TO it.
# Two lexically different prose mechanisms produced the same false edge, and only one of
# them is a comment:
#
#   COMMENT     `# see tools/_t400-schema-teeth.sh` — 46 of 115 tool-to-tool reference
#               lines opened this way when T-493 measured them.
#   DOCSTRING   `_t420-rail-attribution-gate.py` names `tools/_t418-producer-attribution.py`
#               in its MODULE DOCSTRING as the detector it defers to. A string literal, so
#               a `#`-stripper does not touch it. T-495 was FILED prescribing exactly that
#               `#`-stripper; it would have closed the task, moved the count a third time,
#               and left the one edge the task existed for standing.
#
# The second mechanism also fires inside THIS FILE: the LIMIT paragraph below used to name
# `_t418` while explaining that prose creates false edges, and the census is live via the
# gap gauge — so the paragraph documenting the defect was an instance of it, vouching for
# the very instrument it was warning about.
#
# Python is therefore stripped EXACTLY, with `tokenize` for comments and `ast` for bare
# string-expression statements, not with a regex. A regex that "handles both" would be a
# guess about lexical structure — the same shape as the instrument this census counts.
# Strings that are ARGUMENTS survive: `subprocess.run(['python3', 'tools/x.py'])` is a real
# call and must stay an edge. Only a string that is an entire statement is prose.
#
# Blanking preserves offsets (spaces, never deletion) so the two passes compose without
# re-deriving positions.
PARSE_FALLBACKS = []


def _blank(lines, sl, sc, el, ec):
    """Overwrite [sl:sc, el:ec] with spaces. 1-indexed lines, 0-indexed columns."""
    for i in range(sl, el + 1):
        line = lines[i - 1]
        a = min(sc if i == sl else 0, len(line))
        b = min(ec if i == el else len(line), len(line))
        if b > a:
            lines[i - 1] = line[:a] + ' ' * (b - a) + line[b:]


def _strip_python(text, path):
    """Comments (tokenize) and bare string statements (ast) blanked out.

    Returns None when the source cannot be tokenized or parsed. The caller must NOT
    treat that as "no references": a file silently dropped from the graph removes
    edges for a reason that has nothing to do with wiring, which is the census's own
    failure mode one level up.
    """
    lines = text.splitlines()
    try:
        toks = list(tokenize.generate_tokens(io.StringIO(text).readline))
        tree = ast.parse(text)
    except (SyntaxError, IndentationError, ValueError, tokenize.TokenError):
        PARSE_FALLBACKS.append(path)
        return None
    for t in toks:
        if t.type == tokenize.COMMENT:
            _blank(lines, t.start[0], t.start[1], t.end[0], t.end[1])
    for node in ast.walk(tree):
        if (isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant)
                and isinstance(node.value.value, str)):
            _blank(lines, node.lineno, node.col_offset,
                   node.end_lineno, node.end_col_offset)
    return '\n'.join(lines)


def _strip_hash(text):
    """Shell/crontab `#` comments, quote-aware and word-aware.

    `#` opens a comment only at the start of a WORD, which is bash's actual rule. Without
    that, `${VAR#prefix}` and a URL fragment would truncate a line holding a real call.
    """
    out = []
    for line in text.splitlines():
        q = None
        res = []
        i = 0
        while i < len(line):
            ch = line[i]
            if q:
                if ch == '\\' and q == '"' and i + 1 < len(line):
                    res.append(ch)
                    res.append(line[i + 1])
                    i += 2
                    continue
                if ch == q:
                    q = None
                res.append(ch)
            elif ch in ('"', "'"):
                q = ch
                res.append(ch)
            elif ch == '#' and (i == 0 or line[i - 1].isspace()):
                break
            else:
                res.append(ch)
            i += 1
        out.append(''.join(res))
    return '\n'.join(out)


def _strip_cstyle(text):
    """`//` and `/* */` for js/mjs, quote-aware across ' " and backtick."""
    res = []
    i, n, q = 0, len(text), None
    while i < n:
        ch = text[i]
        if q:
            if ch == '\\' and i + 1 < n:
                res.append(ch)
                res.append(text[i + 1])
                i += 2
                continue
            if ch == q:
                q = None
            res.append(ch)
            i += 1
        elif ch in ('"', "'", '`'):
            q = ch
            res.append(ch)
            i += 1
        elif ch == '/' and i + 1 < n and text[i + 1] == '/':
            while i < n and text[i] != '\n':
                res.append(' ')
                i += 1
        elif ch == '/' and i + 1 < n and text[i + 1] == '*':
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            res.append(''.join(' ' if c != '\n' else '\n' for c in text[i:j]))
            i = j
        else:
            res.append(ch)
            i += 1
    return ''.join(res)


def strip_prose(path, text):
    """Non-executable text blanked, dispatched by extension.

    An unrecognised extension is returned WHOLE. That is the loose direction, chosen
    deliberately: this function's job is to remove edges, and removing them from a file
    type whose comment syntax has not been established would be guessing.
    """
    ext = os.path.splitext(path)[1].lower().lstrip('.')
    if ext == 'py':
        stripped = _strip_python(text, path)
        return text if stripped is None else stripped
    if ext in ('sh', 'bash', 'crontab'):
        return _strip_hash(text)
    if ext in ('js', 'mjs', 'cjs'):
        return _strip_cstyle(text)
    return text


# ── T-495, second half: a COMPOSED path is a call ───────────────────────────────────
# Stripping prose alone made this census materially WORSE, and the measurement is the
# argument: 10 of the 13 tools that stripping newly orphaned are CDP harnesses that run
# on every bridge-suite pass, invoked as
#
#     HARNESS = os.path.join(ROOT, "tools", "_t125-lane-compaction-cdp.mjs")
#
# TWO ERRORS OF OPPOSITE SIGN WERE CANCELLING. Prose counted as a call (the T-495
# false negative), and a composed path was invisible (the long-stated false positive).
# Each test module's docstring happened to name the harness it composes, so the wrong
# edge stood in for the missing one and the answer came out right. Fixing one side alone
# converts a silently-wrong verdict into a loudly-wrong one — ten live, running
# instruments reported dead — which is not an improvement in either direction that
# matters. That is why this is in the same commit and not a follow-up task.
#
# Resolved from the AST, so only literal components count: `os.path.join(x, 'tools', 'y')`
# and `x / 'tools' / 'y'` (pathlib). A component held in a VARIABLE stays invisible, and
# so does an f-string interpolation — both remain in the stated false-positive direction.
BASENAME_RE = re.compile(r'^([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))$')


def _consts(node):
    """Every string Constant anywhere under `node`."""
    return [n.value for n in ast.walk(node)
            if isinstance(n, ast.Constant) and isinstance(n.value, str)]


def _composed_refs(tree):
    """Tool basenames sitting in the same literal path expression as 'tools'."""
    found = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            parts = [a.value for a in node.args
                     if isinstance(a, ast.Constant) and isinstance(a.value, str)]
        elif isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div):
            parts = _consts(node)
        else:
            continue
        if 'tools' not in parts:
            continue
        for p in parts:
            m = BASENAME_RE.match(p)
            if m:
                found.add(m.group(1))
    return found


def read_refs(paths):
    found = set()
    for p in paths:
        if not os.path.isfile(p):
            continue
        try:
            text = open(p, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        if os.path.splitext(p)[1].lower() == '.py':
            stripped = _strip_python(text, p)
            if stripped is None:            # unparseable: counted, and read WHOLE
                found.update(TOOL_RE.findall(text))
                continue
            found.update(TOOL_RE.findall(stripped))
            try:
                found.update(_composed_refs(ast.parse(text)))
            except (SyntaxError, ValueError):   # unreachable: _strip_python parsed it
                pass
            continue
        found.update(TOOL_RE.findall(strip_prose(p, text)))
    return found


def gauge_refs():
    """Tools named in a gap's `closure_check_command:` — the only executed field.

    Refuses rather than degrading: if the register cannot be parsed we have not
    enumerated a root source, and silently continuing would move tools into the
    findings column for a reason that has nothing to do with their wiring. Louder is
    not the same as correct (T-430 abstention discipline).
    """
    if not os.path.isfile(GAUGE_FILE):
        return set()
    try:
        import yaml
    except ImportError:
        refuse('PyYAML is unavailable, so %s cannot be field-scoped to %s. Grepping it '
               'whole is the T-493 defect this function exists to fix.'
               % (GAUGE_FILE, GAUGE_FIELD))
    try:
        doc = yaml.safe_load(open(GAUGE_FILE, encoding='utf-8')) or {}
    except Exception as exc:                      # noqa: BLE001 - any parse failure
        refuse('%s did not parse (%s), so a root source could not be enumerated.'
               % (GAUGE_FILE, exc))
    found = set()
    for entry in (doc.get('concerns') or []) + (doc.get('gaps') or []):
        if not isinstance(entry, dict):
            continue
        cmd = entry.get(GAUGE_FIELD)
        if isinstance(cmd, str):
            found.update(TOOL_RE.findall(cmd))
    return found


def verification_refs(task_paths):
    """tool -> [task ids] for tools named in a task's ## Verification block."""
    out = {}
    for p in task_paths:
        s = open(p, encoding='utf-8', errors='replace').read()
        m = re.search(r'^## Verification\s*$(.*?)(?=^## |\Z)', s, re.M | re.S)
        if not m:
            continue
        body = '\n'.join(l for l in m.group(1).splitlines() if not l.strip().startswith('#'))
        tid = re.match(r'(T-\d+)', os.path.basename(p))
        for t in set(TOOL_RE.findall(body)):
            out.setdefault(t, []).append(tid.group(1) if tid else os.path.basename(p))
    return out


def main():
    root = os.environ.get('T451_ROOT')
    if root:
        os.chdir(root)

    if not os.path.isdir('tools'):
        refuse('no tools/ directory here, so there is no population to range over.')
    population = sorted(os.path.basename(p) for p in glob.glob('tools/*')
                        if os.path.isfile(p) and p.rsplit('.', 1)[-1] in EXT)
    if not population:
        refuse('tools/ holds no *.{%s}, so "0 unwired" would be a verdict about nothing.'
               % ','.join(EXT))
    for d in ('.tasks/active', '.tasks/completed'):
        if not os.path.isdir(d):
            refuse('%s is missing, so the caller set cannot be enumerated and every '
                   'instrument would read as unwired.' % d)

    # ROOTS first: reached by something that is not itself a tool.
    roots = set()
    for pattern in ROOT_SOURCES:
        roots |= read_refs(glob.glob(pattern, recursive=True))
    roots |= gauge_refs()
    # A name that resolves to no file on disk is not a caller of anything here.
    roots &= set(population)

    # Then CLOSE over tool->tool edges, walking only from tools already known live.
    # This is the T-493 fix. The edge set is the same data the old code unioned in one
    # step; the difference is entirely in the direction of travel. A dead tool's
    # references are never traversed, so dead tools can no longer vouch for each other.
    edges = {t: (read_refs(['tools/' + t]) & set(population)) - {t} for t in population}
    live = set(roots)
    frontier = set(roots)
    while frontier:
        nxt = set()
        for t in frontier:
            nxt |= edges.get(t, set())
        nxt -= live
        live |= nxt
        frontier = nxt

    done = verification_refs(sorted(glob.glob('.tasks/completed/*.md')))
    active = verification_refs(sorted(glob.glob('.tasks/active/*.md')))

    # An ACTIVE task's Verification block is a pending one-shot, not a standing caller:
    # it runs once, when that task completes, and then joins the dead set. It is counted
    # in its own column rather than as live, because folding it into "wired" is exactly
    # how every instrument in this census looked wired on the day it was written.
    pending = sorted(t for t in population if t in active and t not in live)
    unwired = sorted(t for t in population if t not in live and t not in active)
    excused = [t for t in unwired if t.endswith(ONE_SHOT_BY_DESIGN)]
    findings = [t for t in unwired if t not in excused]
    orphans = [t for t in findings if t not in done]

    if '--json' in sys.argv:
        import json
        print(json.dumps({
            'verdict': 'READY' if not findings else 'NOT_READY',
            'ready': not findings,
            'population': len(population),
            'roots_non_tool': len(roots),
            'live_callable': len(live),
            'reached_only_via_tool_chain': len(live - roots),
            'pending_one_shot': len(pending),
            'no_live_caller': len(unwired),
            'excused_one_shot_by_design': len(excused),
            'findings': len(findings),
            'never_referenced_by_any_task': len(orphans),
            'findings_files': findings,
            'python_parse_fallbacks': len(PARSE_FALLBACKS),
            'python_parse_fallback_files': sorted(set(PARSE_FALLBACKS)),
            'limit': 'reachability decided by textual reference to tools/<name> in an '
                     'EXECUTABLE position (T-495: comments and bare string statements are '
                     'stripped). A caller composing the path at runtime is invisible and '
                     'its tool reads unwired; a heredoc body still reads as an edge',
        }, indent=2))
        return 0        # see the docstring: the verdict is the payload, not the rc

    print('=== T-451: instruments with no live caller ===')
    print()
    print('  population                                       %4d  tools/*.{%s} on disk'
          % (len(population), ','.join(EXT)))
    print('  roots (hook, cron, tests/, agent, gap gauge)     %4d  NOT itself a tool'
          % len(roots))
    print('  live-callable (closure from roots)               %4d  of which %d reached '
          'only via a live tool chain' % (len(live), len(live - roots)))
    print('  pending one-shot (ACTIVE task Verification only)  %4d  will run once, then '
          'join the set below' % len(pending))
    print('  NO live caller                                   %4d' % len(unwired))
    print('    one-shot BY DESIGN (teeth/mutation-check/probe) %4d  excused by naming '
          'convention' % len(excused))
    print('    FINDINGS — read as standing guards             %4d' % len(findings))
    print('      never referenced by ANY task at all           %4d' % len(orphans))
    print()
    if findings:
        print('FINDINGS — each has run at most once, at the completion of the task named,')
        print('and cannot be re-run by anything in this tree:')
        for t in findings:
            where = ','.join(sorted(set(done.get(t, [])))) or '** NO CALLER ANYWHERE **'
            print('  %-42s last ran at: %s' % (t, where[:60]))
        print()
    print('LIMIT: reachability is decided by TEXTUAL reference to `tools/<name>` in an')
    print('  EXECUTABLE position, and that cuts BOTH ways.')
    print('  FALSE POSITIVE — a caller composing the path at runtime is invisible, so its')
    print('    tool is reported unwired. Cannot be closed from outside.')
    print('  FALSE NEGATIVE — T-495 closed the two prose forms (comments, and string')
    print('    literals that are whole statements). Still open, same direction:')
    print('      * a shell HEREDOC body reads as an edge (needs a shell parser)')
    print('      * .md/.yaml/.json roots are read whole — no comment syntax assumed')
    print('      * a shell string spanning lines re-opens quote state per line')
    print('  Stated so a clean run cannot imply coverage it does not have (PL-148).')
    if PARSE_FALLBACKS:
        print('  PARSE FALLBACK — %d python file(s) could not be tokenized/parsed and were'
              % len(set(PARSE_FALLBACKS)))
        print('    read WHOLE, so their comments and docstrings still count as edges:')
        for p in sorted(set(PARSE_FALLBACKS)):
            print('      %s' % p)

    # ── T-491: --ratchet ────────────────────────────────────────────────────────────────
    # This census has been correct and unscheduled since T-451. Its only live caller is the
    # gap gauge in lib/gaps.py, which runs when somebody asks to close G-035 — so the count
    # (T-493: this said G-034. Derived from the register rather than remembered: G-035 is the
    # gap whose closure_check_command names this file. A wrong id in a comment that exists to
    # tell the next reader where the only caller lives sends them to the wrong gap.)
    # it produces is real and nobody is told when it grows. That is one step milder than the
    # class it measures: not unrunnable, just unwatched.
    #
    # Wiring the raw exit code into the suite is not available: it exits 1 on a pre-existing
    # backlog, so the suite would be permanently red and the redness would carry no
    # information. PL-004 (T-052) prescribed the alternative in the same sentence that named
    # the class — "wire every gate into CI over its full subject set, with a legacy allowlist
    # (with stale-entry detection)" — and only the first half was ever built.
    #
    # So the ratchet fails on MOVEMENT, in both directions:
    #   a finding not in the baseline   -> the class GREW; a new standing guard went dark
    #   a baseline entry not in findings -> it got wired or deleted; tighten the baseline
    # The second direction is the one that matters over time. Without it the baseline decays
    # into a permanent amnesty: entries that were fixed years ago keep excusing themselves,
    # and the file stops describing the tree. A baseline that never shrinks is a hand-typed
    # denominator wearing a different hat (PL-181).
    if '--ratchet' in sys.argv:
        base_path = os.path.join('tools', 'unwired-guard-baseline.txt')
        if not os.path.exists(base_path):
            print('\nRATCHET: no baseline at %s — refusing rather than minting one silently.'
                  % base_path)
            print('  A baseline created on the fly would record whatever today happens to be')
            print('  and call it approved. Create it deliberately.')
            return 2
        with open(base_path) as fh:
            baseline = {l.strip() for l in fh
                        if l.strip() and not l.lstrip().startswith('#')}
        cur = set(findings)
        grew = sorted(cur - baseline)
        fixed = sorted(baseline - cur)
        print('\nRATCHET: baseline %d, current findings %d' % (len(baseline), len(cur)))
        if not grew and not fixed:
            print('  no movement — the backlog neither grew nor shrank.')
            return 0
        if grew:
            print('  GREW by %d — a standing guard lost its last live caller:' % len(grew))
            for t in grew:
                print('    + %s' % t)
        if fixed:
            print('  SHRANK by %d — now wired or gone, so remove from the baseline:'
                  % len(fixed))
            for t in fixed:
                print('    - %s' % t)
            print('  (A stale baseline entry is a standing exemption for a problem that no')
            print('   longer exists. Leaving it costs nothing today and hides the next one.)')
        return 1

    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
