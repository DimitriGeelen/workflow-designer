#!/usr/bin/env python3
"""_t1152-stale-review-doc.py — a [REVIEW] criterion that points at a document older than its task (T-1152, OBS-291).

What it catches. T-189's [REVIEW] criterion told the operator to read a proposal last edited 2026-07-12, while four
later items lived only in the task. A sign-off would have ruled on the July proposal believing it ruled on the
current one. Nothing compared a referenced document with the task it stands for.

The check. For every task in the tasks dir (default .tasks/active: completed tasks await no sign-off) and every
UNCHECKED `[REVIEW]` / `[REVIEWER]` criterion, take each tracked repo path its text names (the criterion line and
its indented Steps/Expected/If-not block). Compare:
  doc date   last commit touching the path (a path with uncommitted edits counts as fresh: someone is on it)
  task date  last commit that changed the task's CONTENT. Skipped, because each would make every task "newer"
             than everything: frontmatter-only edits (the BVP estimator stamps bvp_scores_proposed: on every task),
             checkbox ticks, edits confined to bookkeeping sections (Updates, Reviewer Verdict, Verification), and
             corpus sweeps (a commit editing --sweep-files task files or more; T-660 rewrote 81 at once).
STALE when the task content is newer than the document by more than --days (default 7).
Documents only by default: docs/**/*.md|html, what a reviewer is asked to READ as the decision's subject. Tests,
tools, fixtures and screenshots are evidence, not the task's stand-in (--all-paths includes them).

Template comments (<!-- ... -->) are stripped first: the default task template carries example [REVIEW] criteria
inside a comment, and they are not criteria.

States, never a bare empty list (NOT EVALUATED is not PASSED):
  STALE <task> AC<n> <path> doc=<date> (<sha>) task-body=<date> (<sha>) gap=<d>d     one per finding
  STALE-REVIEW-DOCS <n> (examined ...)     exit 1
  NO-STALE (examined ...)                  exit 0
  NOT EVALUATED: <why>                     exit 3   (no unchecked [REVIEW] criterion names a tracked path)

Usage: _t1152-stale-review-doc.py [--root DIR] [--tasks-dir DIR] [--days N]
"""
import argparse
import datetime
import glob
import json
import os
import re
import subprocess
import sys

CRIT_RE = re.compile(r"^(\s*)- \[ \] \[(REVIEW|REVIEWER)\]")
ANY_BOX_RE = re.compile(r"^\s*- \[[ xX]\] ")
# Candidate path tokens; only those that are tracked files count.
# The documents a reviewer is asked to READ as the subject of a decision (proposals, reports, plans). Tests, tools,
# fixtures and screenshots a criterion names are evidence, not the task's stand-in; --all-paths includes them.
DOC_RE = re.compile(r"^docs/.*\.(md|html)$")
PATH_RE = re.compile(r"(?<![\w./-])((?:\.?[\w-]+/)*[\w.-]+\.[A-Za-z0-9]{1,5})(?::\d+)?(?![\w/])")


def git(root, *args):
    return subprocess.run(["git", "-C", root, *args], capture_output=True, text=True, check=False).stdout


def strip_comments(text):
    return re.sub(r"<!--.*?-->", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)


def body_start(text):
    """Line index (0-based) of the first body line, i.e. after the closing frontmatter ---."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return 0
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return i + 1
    return 0


def criteria(text):
    """Yield (n, block_text) for each unchecked [REVIEW]/[REVIEWER] criterion, n counting every checkbox in the file."""
    lines = strip_comments(text).split("\n")
    n = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if ANY_BOX_RE.match(line):
            n += 1
            m = CRIT_RE.match(line)
            if m:
                indent = len(m.group(1))
                block = [line]
                j = i + 1
                while j < len(lines):
                    nxt = lines[j]
                    if nxt.strip() and (len(nxt) - len(nxt.lstrip())) <= indent:
                        break
                    block.append(nxt)
                    j += 1
                yield n, "\n".join(block)
        i += 1


_SWEEP = {}


def _is_sweep(root, sha, limit):
    """A commit that edits `limit` or more task files is a corpus sweep (T-660 rewrote 81 task bodies at once to
    fix a literal T-XXX), not news about any one task."""
    if sha not in _SWEEP:
        names = git(root, "show", "--format=", "--name-only", sha).split("\n")
        _SWEEP[sha] = sum(1 for n in names if n.startswith(".tasks/")) >= limit
    return _SWEEP[sha]


def task_body_commit(root, rel, sweep_limit=20):
    """(sha, epoch) of the newest commit that changed a body line of rel, following renames; None if untracked.
    Skipped: frontmatter-only edits, checkbox ticks, bookkeeping sections, and corpus sweeps."""
    log = git(root, "log", "--follow", "--format=C %H %ct", "--name-only", "--", rel)
    commits = []  # (sha, ct, path at that commit)
    cur = None
    for line in log.split("\n"):
        if line.startswith("C "):
            _, sha, ct = line.split()
            cur = [sha, int(ct), None]
            commits.append(cur)
        elif line.strip() and cur is not None and cur[2] is None:
            cur[2] = line.strip()
    for sha, ct, path in commits:
        path = path or rel
        if _is_sweep(root, sha, sweep_limit) and sha != commits[-1][0]:
            continue                                   # never skip the creating commit
        diff = git(root, "show", "--format=", "-U0", sha, "--", path)
        if not diff.strip():
            # a rename-only commit or a merge: no content change to judge
            continue
        new_lines = git(root, "show", f"{sha}:{path}").split("\n")
        fm_end = body_start("\n".join(new_lines))
        section_at = _sections(new_lines)
        for h in _hunks(diff):
            start, count, minus, plus = h
            if not _is_content(minus, plus):
                continue                               # a checkbox tick, nothing said
            span = range(start, start + max(count, 1))  # 1-based; a pure deletion sits at `start`
            for ln in span:
                if ln > fm_end and section_at(ln) not in BOOKKEEPING:
                    return sha, ct
    return None


# Sections whose edits are bookkeeping, not content a referenced document should reflect: auto-appended
# update and verdict entries, and the shell checks of Verification.
BOOKKEEPING = {"updates", "reviewer verdict", "verification"}
_TICK = re.compile(r"^(\s*- \[)[ xX](\] )")


def _sections(lines):
    """1-based line -> lowercased name of the enclosing level-2 section ('' before the first)."""
    marks = [(i + 1, re.sub(r"\s*\(.*\)\s*$", "", l[3:]).strip().lower())
             for i, l in enumerate(lines) if l.startswith("## ")]
    def at(ln):
        name = ""
        for start, sec in marks:
            if start > ln:
                break
            name = sec
        return name
    return at


def _hunks(diff):
    """Yield (new_start, new_count, minus_lines, plus_lines) per -U0 hunk."""
    cur = None
    for line in diff.split("\n"):
        m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
        if m:
            if cur:
                yield cur
            cur = (int(m.group(1)), int(m.group(2) if m.group(2) is not None else 1), [], [])
        elif cur and line.startswith("-") and not line.startswith("---"):
            cur[2].append(line[1:])
        elif cur and line.startswith("+") and not line.startswith("+++"):
            cur[3].append(line[1:])
    if cur:
        yield cur


def _is_content(minus, plus):
    """False when the hunk only toggles checkboxes: same lines, ticks normalised."""
    norm = lambda ls: sorted(_TICK.sub(r"\1 \2", l) for l in ls)
    return not (minus and len(minus) == len(plus) and norm(minus) == norm(plus))


def doc_commit(root, rel, dirty):
    if rel in dirty:
        return "worktree", int(datetime.datetime.now().timestamp())
    out = git(root, "log", "-1", "--format=%H %ct", "--", rel).split()
    return (out[0], int(out[1])) if len(out) == 2 else None


class DateCache:
    """Per-file git answers keyed by the file's committed blob hash: a task's content commit and a document's
    last commit can only change when the file's content does. Turns ~20 s of git log/show into a read.
    T1152_NO_CACHE=1 disables it. Same shape as _t451's refs cache (T-1191)."""

    def __init__(self, root, sweep_limit):
        self.path = os.path.join(root, ".context", "working", ".t1152-dates-cache.json")
        self.on = os.environ.get("T1152_NO_CACHE") != "1"
        self.key_extra = f"sweep={sweep_limit}"
        self.blob = {}
        for line in git(root, "ls-files", "-s").split("\n"):
            parts = line.split(None, 3)            # mode blob stage\tpath
            if len(parts) == 4:
                self.blob[parts[3].split("\t", 1)[-1]] = parts[1]
        self.data, self.dirty = {}, False
        if self.on:
            try:
                self.data = json.load(open(self.path))
            except (OSError, ValueError):
                self.data = {}

    def get(self, kind, rel, compute):
        blob = self.blob.get(rel)
        if not self.on or blob is None:
            return compute()
        key = f"{kind}|{rel}|{blob}|{self.key_extra}"
        if key not in self.data:
            v = compute()
            self.data[key] = list(v) if v else None
            self.dirty = True
        v = self.data[key]
        return tuple(v) if v else None

    def save(self):
        if not (self.on and self.dirty):
            return
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            tmp = f"{self.path}.{os.getpid()}.tmp"
            json.dump(self.data, open(tmp, "w"))
            os.replace(tmp, self.path)
        except OSError:
            pass                                       # a cache that cannot be written is only slower


def day(ct):
    return datetime.datetime.fromtimestamp(ct, datetime.timezone.utc).strftime("%Y-%m-%d")


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--root", default=os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")))
    p.add_argument("--tasks-dir", default=None)
    p.add_argument("--days", type=int, default=7)
    p.add_argument("--all-paths", action="store_true",
                   help="every tracked path a criterion names, not only docs/ documents")
    p.add_argument("--sweep-files", type=int, default=20,
                   help="a commit editing this many task files or more is a sweep and does not date a task (default 20)")
    a = p.parse_args(argv)
    root = os.path.abspath(a.root)
    tasks_dir = a.tasks_dir or os.path.join(root, ".tasks", "active")
    tracked = set(git(root, "ls-files").split("\n"))
    dirty = {l[3:] for l in git(root, "status", "--porcelain").split("\n") if len(l) > 3 and l[1] == "M"}

    findings, n_tasks, n_crit, n_paths = [], 0, 0, 0
    doc_cache = {}
    cache = DateCache(root, a.sweep_files)
    for path in sorted(glob.glob(os.path.join(tasks_dir, "T-*.md"))):
        rel = os.path.relpath(path, root)
        text = open(path, encoding="utf-8").read()
        crits = []
        for n, block in criteria(text):
            named = {m.group(1)[2:] if m.group(1).startswith("./") else m.group(1) for m in PATH_RE.finditer(block)}
            paths = sorted(p for p in (named & tracked) - {rel} if a.all_paths or DOC_RE.match(p))
            if paths:
                crits.append((n, paths))
        if not crits:
            continue
        # A task file with uncommitted edits is judged on its committed history: the edit is not yet content
        # anyone has signed. Its blob key is the committed one, so the cache stays correct.
        task_c = cache.get("task", rel, lambda: task_body_commit(root, rel, a.sweep_files))
        if task_c is None:
            continue
        n_tasks += 1
        task_id = os.path.basename(path).split("-", 2)
        task_id = f"{task_id[0]}-{task_id[1]}"
        for n, paths in crits:
            n_crit += 1
            for dp in paths:
                n_paths += 1
                if dp not in doc_cache:
                    doc_cache[dp] = (doc_commit(root, dp, dirty) if dp in dirty
                                     else cache.get("doc", dp, lambda: doc_commit(root, dp, dirty)))
                d = doc_cache[dp]
                if d is None:
                    continue
                gap = (task_c[1] - d[1]) / 86400
                if gap > a.days:
                    findings.append(f"STALE {task_id} AC{n} {dp} doc={day(d[1])} ({d[0][:8]}) "
                                    f"task-body={day(task_c[1])} ({task_c[0][:8]}) gap={int(gap)}d")
    cache.save()
    examined = (f"examined {n_tasks} task(s), {n_crit} unchecked [REVIEW] criteria naming {n_paths} tracked path(s) "
                f"under {os.path.relpath(tasks_dir, root)}; threshold {a.days}d")
    if n_paths == 0:
        print(f"NOT EVALUATED: no unchecked [REVIEW]/[REVIEWER] criterion names a tracked path ({examined})")
        return 3
    for f in findings:
        print(f)
    if findings:
        print(f"STALE-REVIEW-DOCS {len(findings)} ({examined})")
        return 1
    print(f"NO-STALE ({examined})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
