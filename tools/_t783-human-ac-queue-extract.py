#!/usr/bin/env python3
"""T-783: enumerate every unchecked Human AC in the live queue, from the TASK FILES.

PL-260: do not cite a queue you have not fetched. The handover renders this queue;
this reads the source it renders from, so the two can be reconciled rather than
one trusted.

Read-only. Writes nothing, ticks nothing.
"""
import glob, os, re, sys, json

ROOT = "/opt/832-Workflow-designer"
os.chdir(ROOT)

OWNER_RE = re.compile(r"^owner:\s*(\S+)", re.M)
STATUS_RE = re.compile(r"^status:\s*(\S+)", re.M)
NAME_RE = re.compile(r'^name:\s*"?(.*?)"?\s*$', re.M)


def human_block(text):
    """Text between '### Human' and the next '###'/'## ' heading, or ''."""
    i = text.find("### Human")
    if i < 0:
        return ""
    j = len(text)
    for pat in ("\n### ", "\n## "):
        k = text.find(pat, i + 5)
        if k > 0:
            j = min(j, k)
    return text[i:j]


def strip_comments(block):
    """Drop HTML comment spans — the template's <!-- ... --> carries EXAMPLE
    criteria that look exactly like real ones and would otherwise be counted."""
    return re.sub(r"<!--.*?-->", "", block, flags=re.S)


def bullets(block):
    """Unchecked '- [ ]' bullets plus their indented continuation lines."""
    lines = block.split("\n")
    out = []
    for idx, line in enumerate(lines):
        if not line.startswith("- [ ]"):
            continue
        body = [line]
        for nxt in lines[idx + 1:]:
            if nxt.startswith("- ["):
                break
            body.append(nxt)
        out.append("\n".join(body).rstrip())
    return out


PREFIX_RE = re.compile(r"\[(RUBBER-STAMP|REVIEW|REVIEWER)\]")


def main():
    rows = []
    for fn in sorted(glob.glob(".tasks/active/T-*.md")):
        text = open(fn, encoding="utf-8", errors="replace").read()
        m = re.match(r"^\.tasks/active/(T-\d+)-", fn)
        if not m:
            continue
        tid = m.group(1)
        blk = strip_comments(human_block(text))
        bs = bullets(blk)
        if not bs:
            continue
        owner = (OWNER_RE.search(text) or [None, "?"])[1] if OWNER_RE.search(text) else "?"
        owner = OWNER_RE.search(text).group(1) if OWNER_RE.search(text) else "?"
        status = STATUS_RE.search(text).group(1) if STATUS_RE.search(text) else "?"
        nm = NAME_RE.search(text)
        for b in bs:
            pm = PREFIX_RE.search(b)
            rows.append({
                "task": tid,
                "owner": owner,
                "status": status,
                "name": (nm.group(1) if nm else "")[:70],
                "prefix": pm.group(1) if pm else "NONE",
                "has_steps": "**Steps:**" in b,
                "has_expected": "**Expected:**" in b,
                "text": b,
            })

    if "--json" in sys.argv:
        print(json.dumps(rows, indent=1))
        return 0

    from collections import Counter
    print("=== unchecked Human ACs in .tasks/active/ ===")
    print("criteria: %d   across tasks: %d"
          % (len(rows), len(set(r["task"] for r in rows))))
    print("by prefix :", dict(Counter(r["prefix"] for r in rows)))
    print("by owner  :", dict(Counter(r["owner"] for r in rows)))
    print("with Steps/Expected blocks: %d / %d"
          % (sum(r["has_steps"] for r in rows), sum(r["has_expected"] for r in rows)))
    print()
    for r in rows:
        first = r["text"].split("\n")[0]
        first = re.sub(r"^- \[ \]\s*", "", first)[:88]
        print("  %-7s %-6s %-13s %-13s %s" % (r["task"], r["owner"], r["status"],
                                              r["prefix"], first))
    return 0


if __name__ == "__main__":
    sys.exit(main())
