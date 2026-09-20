#!/usr/bin/env python3
"""T-703 — enumerate the observation-inbox residue, and answer the drain-path question.

RA-007 says 101 observations have been pending for more than 7 days. Two things
a number like that cannot tell you: what the residue is MADE OF, and whether an
agent is allowed to reduce it. This tool answers both from data, not prose.

  1. ENUMERATION (AC1). Every pending observation older than 7 days is listed
     with a reason class derived from the register itself:
       carried-by-completed-task   context_task is work-completed; the thread lives
                                   in that task's episodic (L-1699: dismissal must
                                   name where the content now lives — here it can)
       carried-by-active-task      context_task is still in .tasks/active/
       orphan                      no context_task at all — nothing carries it
       dangling-task               context_task names a task that exists nowhere
     A pending entry with none of these is a bug in this tool, and --check fails.

  2. DRAIN PATH (AC2). The register has exactly two closing verbs, both in the
     vendored .agentic-framework/agents/observe/observe.sh:
       promote  -> creates a task (agent-permissible, but produces work, not closure)
       dismiss  -> flips status: pending -> dismissed via sed. do_dismiss() takes
                   --reason, ECHOES it to stdout, and writes NONE of it to the file.
                   No dismissed_by, no dismissed_at, no reason. (observe.sh:280-298)
     --probe-dismiss demonstrates this against a COPY of the inbox in a throwaway
     PROJECT_ROOT (paths.sh honours the override; the real file is hashed before
     and after and must be byte-identical). So: an agent-authority drain path
     EXISTS mechanically (dismiss is ungated) and is NOT AUDITABLE — which is why
     this task dismisses nothing.

  3. COUNTERS. Three instruments count "urgent pending" and disagree:
       audit.sh:2921     yaml parse                     -> exact
       observe.sh:217    grep -c 'urgent: true'         -> counts non-pending too
       handover.sh:382   re.split(r'\\n  - ')           -> splits on bullet lists
                                                          INSIDE observation text
     --counters prints all three next to the exact figure.

Usage:
    python3 tools/_t703-inbox-residue.py                 # summary + reason census
    python3 tools/_t703-inbox-residue.py --check         # exit 1 unless every >7d item has a reason
    python3 tools/_t703-inbox-residue.py --write PATH    # per-item enumeration as markdown
    python3 tools/_t703-inbox-residue.py --probe-dismiss # throwaway-root proof, real inbox untouched
    python3 tools/_t703-inbox-residue.py --counters
"""

import argparse
import datetime
import glob
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INBOX = os.path.join(ROOT, ".context", "inbox.yaml")
OBSERVE = os.path.join(ROOT, ".agentic-framework", "agents", "observe", "observe.sh")
STALE_DAYS = 7


def load(path=INBOX):
    with open(path) as fh:
        return yaml.safe_load(fh)["observations"]


def task_index():
    idx = {}
    for state in ("active", "completed"):
        for f in glob.glob(os.path.join(ROOT, ".tasks", state, "T-*.md")):
            tid = os.path.basename(f).split("-", 2)
            tid = f"{tid[0]}-{tid[1]}"
            status = None
            with open(f) as fh:
                for line in fh:
                    if line.startswith("status:"):
                        status = line.split(":", 1)[1].strip()
                        break
            idx[tid] = (state, status)
    return idx


def _ctx(o):
    v = o.get("context_task")
    return None if v in (None, "", "None") else str(v)


def classify(o, idx):
    t = _ctx(o)
    if t is None:
        return "orphan", "no context task — nothing carries this thread; needs operator triage"
    if t not in idx:
        return "dangling-task", f"context task {t} exists in neither active/ nor completed/"
    state, status = idx[t]
    if state == "completed":
        return ("carried-by-completed-task",
                f"{t} is work-completed; thread lives in .context/episodic/{t}.yaml — "
                f"closure blocked: dismiss verb cannot record where the content lives")
    return "carried-by-active-task", f"{t} still open ({status}); the task carries it"


def residue(obs, now):
    idx = task_index()
    rows = []
    for o in obs:
        if o.get("status") != "pending":
            continue
        cap = o["captured"]
        if isinstance(cap, str):
            cap = datetime.datetime.fromisoformat(cap)
        if cap.tzinfo is None:
            cap = cap.replace(tzinfo=datetime.timezone.utc)
        age = (now - cap).days
        if age <= STALE_DAYS:
            continue
        cls, why = classify(o, idx)
        rows.append({"id": o["id"], "age": age, "urgent": o.get("urgent") is True,
                     "task": _ctx(o), "class": cls, "reason": why,
                     "text": (o.get("text") or "").strip().split("\n")[0][:110]})
    rows.sort(key=lambda r: (-r["urgent"], -r["age"]))
    return rows


def counters():
    obs = load()
    exact = sum(1 for o in obs if o.get("status") == "pending" and o.get("urgent") is True)
    with open(INBOX) as fh:
        text = fh.read()
    grep_c = len(re.findall(r"urgent: true", text))                       # observe.sh:217
    blocks = re.split(r"\n  - ", text)                                     # handover.sh:382
    handover = sum(1 for b in blocks[1:] if "status: pending" in b and "urgent: true" in b)
    return {"exact (audit.sh yaml parse)": exact,
            "observe.sh:217 grep -c": grep_c,
            "handover.sh:382 block split": handover}


def probe_dismiss():
    """Run the real dismiss verb against a copy in a throwaway root. Never the real inbox."""
    before = hashlib.sha256(open(INBOX, "rb").read()).hexdigest()
    tmp = tempfile.mkdtemp(prefix="t703-")
    os.makedirs(os.path.join(tmp, ".tasks"))                # paths.sh root marker
    os.makedirs(os.path.join(tmp, ".context"))
    copy = os.path.join(tmp, ".context", "inbox.yaml")
    shutil.copy(INBOX, copy)
    target = next(o["id"] for o in load() if o.get("status") == "pending")
    marker = "T703-PROBE-REASON-9f1c"
    env = dict(os.environ, PROJECT_ROOT=tmp)
    for k in ("TASKS_DIR", "CONTEXT_DIR", "_FW_PATHS_DERIVED_BY"):
        env.pop(k, None)
    r = subprocess.run([OBSERVE, "dismiss", target, "--reason", marker],
                       capture_output=True, text=True, env=env, cwd=tmp)
    after = hashlib.sha256(open(INBOX, "rb").read()).hexdigest()
    copied = open(copy).read()
    # Inspect the TARGET's block only: observation bodies quote field names and
    # markers in prose (OBS-290's text literally says "dismissed_by"), so a
    # whole-file grep would read prose as a write.
    m = re.search(rf"^- id: {target}\n(.*?)(?=^- id: |\Z)", copied, re.S | re.M)
    block = m.group(1) if m else ""
    flipped = re.search(r"^  status: dismissed$", block, re.M) is not None
    persisted = marker in block
    actor = re.search(r"^  dismissed_(by|at):", block, re.M) is not None
    print("T-703 — dismiss-verb probe (throwaway root, real inbox hashed before/after)")
    print("=" * 70)
    print(f"  verb rc={r.returncode}   stdout: {r.stdout.strip()[:80]}")
    print(f"  real inbox untouched:        {'YES' if before == after else 'NO  <-- STOP'}")
    print(f"  status flipped in copy:      {'YES' if flipped else 'NO'}")
    print(f"  reason persisted in copy:    {'YES' if persisted else 'NO'}")
    print(f"  dismissed_by/at recorded:    {'YES' if actor else 'NO'}")
    shutil.rmtree(tmp, ignore_errors=True)
    if before != after:
        print("\nVERDICT: ABORT — the probe touched the real register.")
        return 2
    if flipped and not persisted and not actor:
        print("\nVERDICT: CONFIRMED — dismiss closes the entry and records neither reason nor actor.")
        return 0
    print("\nVERDICT: the verb behaves differently from observe.sh:280-298 as read; re-inspect.")
    return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--write")
    ap.add_argument("--probe-dismiss", action="store_true")
    ap.add_argument("--counters", action="store_true")
    ap.add_argument("--now", help="ISO date, for reproducible runs")
    a = ap.parse_args()

    if a.probe_dismiss:
        return probe_dismiss()
    if a.counters:
        for k, v in counters().items():
            print(f"  {v:4d}  {k}")
        return 0

    now = (datetime.datetime.fromisoformat(a.now).replace(tzinfo=datetime.timezone.utc)
           if a.now else datetime.datetime.now(datetime.timezone.utc))
    obs = load()
    rows = residue(obs, now)
    pending = sum(1 for o in obs if o.get("status") == "pending")
    census = {}
    for r in rows:
        census[r["class"]] = census.get(r["class"], 0) + 1

    if a.write:
        with open(a.write, "w") as fh:
            fh.write(f"# T-703 — observation-inbox residue, enumerated\n\n")
            fh.write(f"Generated by `tools/_t703-inbox-residue.py --write` on {now.date()} — "
                     f"regenerate, do not hand-edit.\n\n")
            fh.write(f"Pending: {pending} of {len(obs)}. Pending > {STALE_DAYS} days: {len(rows)}.\n\n")
            fh.write("## Reason census\n\n| class | count |\n|---|---|\n")
            for k, v in sorted(census.items(), key=lambda kv: -kv[1]):
                fh.write(f"| {k} | {v} |\n")
            fh.write("\n## Per-item\n\n| id | age (d) | urgent | task | class | reason | first line |\n"
                     "|---|---|---|---|---|---|---|\n")
            for r in rows:
                fh.write(f"| {r['id']} | {r['age']} | {'U' if r['urgent'] else ''} | {r['task'] or '—'} | "
                         f"{r['class']} | {r['reason']} | {r['text'].replace('|', '/')} |\n")
        print(f"wrote {a.write}: {len(rows)} rows")

    print(f"T-703 — inbox residue: {len(rows)} pending > {STALE_DAYS}d (of {pending} pending)")
    for k, v in sorted(census.items(), key=lambda kv: -kv[1]):
        print(f"  {v:4d}  {k}")
    missing = [r["id"] for r in rows if not r["reason"]]
    if a.check:
        if missing:
            print(f"FAIL: {len(missing)} item(s) without a reason: {missing[:5]}")
            return 1
        print(f"OK: every one of the {len(rows)} stale items carries a reason class")
    return 0


if __name__ == "__main__":
    sys.exit(main())
