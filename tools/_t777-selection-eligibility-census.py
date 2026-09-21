#!/usr/bin/env python3
"""T-777 — the eligibility census that autonomous selection actually needs.

`fw bvp` answers "what is most valuable?". It does not answer "what can an agent
actually execute?", and those two questions have different answers in this project.
A quadrant-ordered run that consults only the first one selects work it cannot do.

This census computes the second predicate and joins it to the first, so the claim
"every high-value task is blocked" is a number a later reader can re-derive rather
than a sentence they have to trust.

Four reasons a task is not agent-executable, kept SEPARATE because they have
different owners and different remedies:

  owner-human    `owner: human`. Completing human-owned tasks is not delegated
                 (CLAUDE.md, Autonomous Mode Boundaries). The remedy is a human.
  no-open-ac     no unchecked criterion under `### Agent`. Nothing to do.
  placeholder    the ACs are still `[First criterion]` template text — the task was
                 never scoped. G-020 blocks work on it. The remedy is scoping.
  ac-blocked     every open Agent AC is marked `**BLOCKED**`, i.e. a previous session
                 already established the work is downstream of a ruling.
  verb-gated     an open AC's own text requires a verb the agent is forbidden to
                 invoke. This is the quietest class: the task looks workable, its
                 ACs look ordinary, and the block only appears when you read what
                 the criterion asks you to run.

Usage:
    _t777-selection-eligibility-census.py            full census
    _t777-selection-eligibility-census.py --brief    summary only
    _t777-selection-eligibility-census.py --self-test
"""

import os
import re
import subprocess
import sys

ROOT = "/opt/832-Workflow-designer"
FW = os.path.join(ROOT, ".agentic-framework/bin/fw")

# Verbs an agent must never invoke. Each is enforced by at least one independent gate;
# they are listed here so a criterion that REQUIRES one is classified as gated rather
# than silently counted as available work.
FORBIDDEN_VERBS = [
    ("fw inception decide", "inception decisions are operator-only (two gates)"),
    ("--i-am-human", "sovereignty assertion on the operator's behalf"),
    ("fw bvp confirm", "moves proposed scores to confirmed — sovereignty boundary"),
    ("fw inception sweep", "never run by the agent"),
    ("--force-downgrade", "version sovereignty"),
    ("fw upgrade", "the bump is the operator's call"),
]

OWNER_RE = re.compile(r"^owner:\s*(\S+)", re.M)
STATUS_RE = re.compile(r"^status:\s*(\S+)", re.M)
PLACEHOLDER_RE = re.compile(r"\[(First|Second|Third|Fourth|Fifth) criterion\]")


def agent_block(text):
    """The text between '### Agent' and the next '###' heading, or ''."""
    i = text.find("### Agent")
    if i < 0:
        # No split headers: the whole AC section is agent-verifiable (T-193).
        i = text.find("## Acceptance Criteria")
        if i < 0:
            return ""
        j = text.find("\n## ", i + 5)
        return text[i:j if j > 0 else len(text)]
    j = text.find("\n### ", i + 5)
    return text[i:j if j > 0 else len(text)]


def classify(text):
    """Return (owner, status, open_acs, reasons) for one task body."""
    m = OWNER_RE.search(text)
    owner = m.group(1).strip() if m else "?"
    m = STATUS_RE.search(text)
    status = m.group(1).strip() if m else "?"

    block = agent_block(text)
    open_lines = [l for l in block.split("\n") if l.startswith("- [ ]")]
    blocked = [l for l in open_lines if "**BLOCKED" in l]

    reasons = []
    if owner != "agent":
        reasons.append("owner-human" if owner == "human" else "owner-" + owner)
    if not open_lines:
        reasons.append("no-open-ac")
    if PLACEHOLDER_RE.search(text):
        reasons.append("placeholder")
    if open_lines and len(blocked) == len(open_lines):
        reasons.append("ac-blocked")

    # verb-gated: an OPEN criterion's own text names a forbidden verb. Scan the open
    # bullet plus its indented continuation lines, not the whole file — a verb named in
    # the Context or the RCA is discussion, not a required step.
    gated = []
    lines = block.split("\n")
    for idx, line in enumerate(lines):
        if not line.startswith("- [ ]"):
            continue
        body = [line]
        for nxt in lines[idx + 1:]:
            if nxt.startswith("- [") or nxt.startswith("#"):
                break
            body.append(nxt)
        joined = "\n".join(body)
        for verb, why in FORBIDDEN_VERBS:
            if verb in joined:
                gated.append(why)
                break
    if gated and len(gated) == len([l for l in open_lines if "**BLOCKED" not in l]) and open_lines:
        reasons.append("verb-gated")
    elif gated:
        reasons.append("verb-gated-partial")

    return owner, status, len(open_lines), len(blocked), reasons


def quadrants():
    """{task_id: quadrant} from the scorer. The scorer is the authority on value."""
    out = {}
    for q in ("hv-lc", "hv-hc", "lv-lc", "lv-hc"):
        try:
            r = subprocess.run([FW, "bvp", "--quadrant", q, "--include-proposed"],
                               cwd=ROOT, capture_output=True, text=True, timeout=120)
        except Exception:
            continue
        for line in r.stdout.split("\n"):
            m = re.match(r"^(T-\d+)\s", line)
            if m:
                out[m.group(1)] = q
    return out


def census():
    tasks = {}
    d = os.path.join(ROOT, ".tasks/active")
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".md"):
            continue
        m = re.match(r"^(T-\d+)-", fn)
        if not m:
            continue
        text = open(os.path.join(d, fn), encoding="utf-8", errors="replace").read()
        owner, status, n_open, n_blocked, reasons = classify(text)
        tasks[m.group(1)] = {
            "owner": owner, "status": status, "open": n_open,
            "blocked": n_blocked, "reasons": reasons,
            "executable": not reasons,
        }
    return tasks


def run_self_test():
    """Negative controls: each fixture has a KNOWN answer, and each asserts a
    DIFFERENT reason. A classifier that returned 'blocked' for everything would
    pass a suite of blocked fixtures — so executable fixtures are in the set."""
    FIX = [
        ("agent, one plain open AC -> EXECUTABLE",
         "owner: agent\nstatus: started-work\n### Agent\n- [ ] do a thing\n### Human\n",
         []),
        ("human-owned -> owner-human",
         "owner: human\nstatus: started-work\n### Agent\n- [ ] do a thing\n### Human\n",
         ["owner-human"]),
        ("no open AC -> no-open-ac",
         "owner: agent\nstatus: started-work\n### Agent\n- [x] done\n### Human\n",
         ["no-open-ac"]),
        ("template text -> placeholder",
         "owner: agent\nstatus: captured\n### Agent\n- [ ] [First criterion]\n### Human\n",
         ["placeholder"]),
        ("every open AC blocked -> ac-blocked",
         "owner: agent\nstatus: started-work\n### Agent\n- [ ] **BLOCKED** waiting\n### Human\n",
         ["ac-blocked"]),
        ("open AC requires a forbidden verb -> verb-gated",
         "owner: agent\nstatus: started-work\n### Agent\n"
         "- [ ] decision recorded via `fw inception decide T-1 go`\n### Human\n",
         ["verb-gated"]),
        ("forbidden verb only in prose, not in an AC -> EXECUTABLE",
         "owner: agent\nstatus: started-work\n### Agent\n- [ ] do a thing\n### Human\n"
         "\n## RCA\nwe could not run `fw inception decide` here\n",
         []),
        ("one blocked, one open -> still EXECUTABLE",
         "owner: agent\nstatus: started-work\n### Agent\n"
         "- [ ] **BLOCKED** waiting\n- [ ] do the other thing\n### Human\n",
         []),
    ]
    npass = nfail = 0
    for label, body, want in FIX:
        _, _, _, _, got = classify(body)
        if sorted(got) == sorted(want):
            print("  PASS  %s" % label)
            npass += 1
        else:
            print("  FAIL  %s\n        got %s, want %s" % (label, got, want))
            nfail += 1
    print("\n=== self-test: %d passed, %d failed ===" % (npass, nfail))
    return nfail == 0


def main():
    if "--self-test" in sys.argv:
        return 0 if run_self_test() else 1

    brief = "--brief" in sys.argv
    tasks = census()
    quad = quadrants()

    hv = {t for t, q in quad.items() if q.startswith("hv-")}
    active_hv = {t for t in hv if t in tasks}
    executable = {t for t, v in tasks.items() if v["executable"]}
    hv_exec = sorted(active_hv & executable)
    exec_not_hv = sorted(executable - hv)

    if not brief:
        print("=== high-value tasks (scorer: hv-lc or hv-hc), and why each is not executable ===\n")
        for t in sorted(active_hv, key=lambda x: int(x[2:])):
            v = tasks[t]
            why = ", ".join(v["reasons"]) if v["reasons"] else "EXECUTABLE"
            print("  %-7s %-6s %-14s open=%-2s blocked=%-2s %-8s %s"
                  % (t, v["owner"], v["status"], v["open"], v["blocked"], quad[t], why))

    print("\n=== summary ===")
    print("  active tasks                      : %d" % len(tasks))
    print("  placed in a high-value quadrant   : %d" % len(active_hv))
    print("  of those, agent-executable        : %d  %s" % (len(hv_exec), hv_exec))
    print("  agent-executable overall          : %d" % len(executable))
    print("  ...but outside every hv quadrant  : %d" % len(exec_not_hv))
    print("  unquadranted (cost unmeasured)    : %d of %d"
          % (len(tasks) - len([t for t in tasks if t in quad]), len(tasks)))

    print("\n=== the control ===")
    if not executable:
        print("  INCONCLUSIVE — the executable set is EMPTY, so this census cannot")
        print("  distinguish 'all high-value work is blocked' from 'the predicate")
        print("  rejects everything'. Treat the headline as unmeasured.")
        return 2
    print("  The executable set is NON-EMPTY (%d tasks), so the predicate admits work." % len(executable))
    if hv_exec:
        print("  And %d high-value task(s) ARE executable: %s" % (len(hv_exec), hv_exec))
        print("  -> the blocking claim is FALSE as of this run. Select from that list.")
    else:
        print("  Every executable task falls outside hv-lc and hv-hc.")
        print("  -> quadrant-ordered autonomous selection has no legal move.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
