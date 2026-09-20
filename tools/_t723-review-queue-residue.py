#!/usr/bin/env python3
"""T-723 / RA-027: enumerate the D2 human-review queue with a reason per row.

D2 fails when a task sits in the review queue over 30 days. T-656 split that
queue by WHAT IT IS WAITING FOR -- judgement vs. a bare status flip -- because
a task the human had fully signed off was counting identically to one they had
not opened. This probe carries that same principle one step further and names
the reason for every row, so "12 waiting" is never again a number without a
cause attached to each unit of it.

The classification mirrors the control exactly (audit.sh D2 +
active-task-scan.py Loop 10) rather than inventing a second definition:

  entry     status == work-completed AND owner == human AND still in active/
  age       date_finished, falling back to last_update
  tiers     >=720h (30d) FAIL, >=336h (14d) WARN

What it adds is the Agent/Human split of the unticked boxes. The control counts
unticked across the WHOLE Acceptance Criteria section, so a task still owing
AGENT work is indistinguishable in its output from one owing a human decision.
For a work-completed task P-010 should have made that impossible -- it blocks
completion on an unchecked Agent AC -- so any row landing in awaiting-agent-work
is either a pre-P-010 task or one completed under --force, and is a finding in
its own right rather than a queue entry.

  signed-off-flip       0 unticked            -> fw task archive-eligible
  awaiting-judgement    unticked Human only   -> a real operator decision
  awaiting-agent-work   any unticked Agent    -> NOT the operator's to clear

Comments are stripped FIRST and non-greedily. This is not optional and not
cosmetic: the task template keeps worked [REVIEW] examples, with real unticked
boxes, inside the ### Human section's HTML comment. A line-range delete
(sed '/<!--/,/-->/d') pairs each opener with the next closer anywhere in the
file and swallows real criteria with it -- over T-093 it yields one ticked
criterion instead of seven.

Usage:
  _t723-review-queue-residue.py            summary to stdout
  _t723-review-queue-residue.py --check    exit 0 only if every >30d row has a reason
  _t723-review-queue-residue.py --write    write docs/reports/T-723-review-queue-residue.md
"""
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ACTIVE = ROOT / ".tasks" / "active"
REPORT = ROOT / "docs" / "reports" / "T-723-review-queue-residue.md"

FAIL_HOURS = 720   # 30d, audit.sh D2
WARN_HOURS = 336   # 14d, audit.sh D2


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        fm = re.match(r"^([a-z_]+):\s*(.*)$", line)
        if fm:
            out[fm.group(1)] = fm.group(2).strip().strip('"')
    return out


def ac_split(text):
    """Return (unticked_agent, unticked_human, human_open_texts).

    Comments stripped first, non-greedy -- see module docstring.
    """
    body = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    sec = re.search(r"## Acceptance Criteria(.*?)\n## ", body, re.S)
    if not sec:
        return 0, 0, []
    block = sec.group(1)
    agent_m = re.search(r"^### Agent\s*$(.*?)(?=^### |\Z)", block, re.S | re.M)
    human_m = re.search(r"^### Human\s*$(.*?)(?=^### |\Z)", block, re.S | re.M)
    if not agent_m and not human_m:
        # No split headers: every box is gated as an Agent AC by P-010.
        return len(re.findall(r"^\s*-\s*\[ \]", block, re.M)), 0, []
    a_txt = agent_m.group(1) if agent_m else ""
    h_txt = human_m.group(1) if human_m else ""
    a_open = len(re.findall(r"^\s*-\s*\[ \]", a_txt, re.M))
    h_open = re.findall(r"^\s*-\s*\[ \]\s*(.+)$", h_txt, re.M)
    return a_open, len(h_open), [t.strip() for t in h_open]


def collect():
    now = datetime.now(timezone.utc)
    rows = []
    for f in sorted(ACTIVE.glob("T-*.md")):
        text = f.read_text(encoding="utf-8", errors="replace")
        fm = frontmatter(text)
        if fm.get("status") != "work-completed" or fm.get("owner") != "human":
            continue
        ds = fm.get("date_finished", "")
        if not ds or ds == "null":
            ds = fm.get("last_update", "")
        if not ds or ds == "null":
            continue
        try:
            ts = datetime.fromisoformat(ds.replace("Z", "+00:00"))
        except ValueError:
            continue
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        age_h = int((now - ts).total_seconds() / 3600)
        a_open, h_open, h_texts = ac_split(text)
        if a_open > 0:
            kind = "awaiting-agent-work"
        elif h_open > 0:
            kind = "awaiting-judgement"
        else:
            kind = "signed-off-flip"
        rows.append({
            "id": fm.get("id", f.stem),
            "name": fm.get("name", ""),
            "age_h": age_h,
            "age_d": age_h // 24,
            "kind": kind,
            "agent_open": a_open,
            "human_open": h_open,
            "reasons": h_texts,
            "tier": "FAIL>30d" if age_h >= FAIL_HOURS else ("WARN>14d" if age_h >= WARN_HOURS else "ok"),
        })
    rows.sort(key=lambda r: -r["age_h"])
    return rows


def reason_for(r):
    if r["kind"] == "signed-off-flip":
        return "every criterion ticked; needs only `fw task archive-eligible`"
    if r["kind"] == "awaiting-agent-work":
        return f"{r['agent_open']} Agent AC(s) still open -- NOT an operator decision"
    if r["reasons"]:
        return r["reasons"][0]
    return ""


def main():
    args = sys.argv[1:]
    rows = collect()
    over30 = [r for r in rows if r["age_h"] >= FAIL_HOURS]
    missing = [r for r in over30 if not reason_for(r)]

    if "--check" in args:
        print(f">30d rows: {len(over30)} | without a reason: {len(missing)}")
        for r in missing:
            print(f"  NO REASON: {r['id']} ({r['age_d']}d)")
        return 1 if missing else 0

    by_kind = {}
    for r in rows:
        by_kind.setdefault(r["kind"], []).append(r)

    if "--write" in args:
        L = []
        L.append("# T-723 / RA-027 -- human review queue residue\n")
        L.append(f"Generated by `tools/_t723-review-queue-residue.py --write` on "
                 f"{datetime.now(timezone.utc).strftime('%Y-%m-%d')}.\n")
        L.append("Classification mirrors the control (audit.sh D2 + active-task-scan.py "
                 "Loop 10): entry is `status: work-completed` + `owner: human` + still in "
                 "`.tasks/active/`; age is `date_finished` falling back to `last_update`; "
                 "tiers are 720h/336h. What this report adds is the Agent/Human split of "
                 "the unticked boxes -- the control counts them together, so a task owing "
                 "AGENT work reads identically to one owing a human decision.\n")
        L.append(f"**Queue: {len(rows)} task(s)** -- "
                 f"{len(by_kind.get('awaiting-judgement', []))} awaiting judgement, "
                 f"{len(by_kind.get('signed-off-flip', []))} signed off awaiting only the flip, "
                 f"{len(by_kind.get('awaiting-agent-work', []))} still owing agent work. "
                 f"{len(over30)} are over 30 days.\n")
        for kind, title, gloss in [
            ("awaiting-judgement", "Awaiting judgement",
             "A real operator decision. These are the only rows the queue legitimately holds."),
            ("awaiting-agent-work", "Still owing agent work",
             "P-010 blocks `work-completed` on an unchecked Agent AC, so a row here is "
             "either pre-P-010 or was completed under `--force`. Not the operator's to clear."),
            ("signed-off-flip", "Signed off, awaiting only the status flip",
             "Nothing is being decided. `fw task archive-eligible` closes these."),
        ]:
            group = by_kind.get(kind, [])
            L.append(f"\n## {title} ({len(group)})\n")
            L.append(f"_{gloss}_\n")
            if not group:
                L.append("\nNone.\n")
                continue
            L.append("\n| Task | Age | Tier | Reason it is still open |")
            L.append("|------|-----|------|--------------------------|")
            for r in group:
                reason = reason_for(r).replace("|", "\\|")
                if len(reason) > 160:
                    reason = reason[:157] + "..."
                L.append(f"| {r['id']} | {r['age_d']}d | {r['tier']} | {reason} |")
            L.append("")
        REPORT.parent.mkdir(parents=True, exist_ok=True)
        REPORT.write_text("\n".join(L) + "\n", encoding="utf-8")
        print(f"wrote {REPORT.relative_to(ROOT)} ({len(rows)} rows, {len(over30)} over 30d)")
        return 0

    print(f"review queue: {len(rows)} task(s), {len(over30)} over 30 days")
    for kind in ("awaiting-judgement", "awaiting-agent-work", "signed-off-flip"):
        group = by_kind.get(kind, [])
        print(f"  {kind:22s} {len(group):3d}  " +
              " ".join(f"{r['id']}({r['age_d']}d)" for r in group[:14]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
