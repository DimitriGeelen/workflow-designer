#!/usr/bin/env python3
"""T-770 — the reviewer delegation boundary, as a predicate instead of a judgement call.

The operator's standing instruction (2026-09-21):

    "We have an external verification agent. If it says it is good, we can open it up.
     With the exception of high risk, Tier 0 and large UX reviews."

An instruction phrased that way is not yet delegated. "High risk" is a judgement, and if
the agent is the one who decides each time what counts as high risk, the decision has been
MOVED to the agent, not delegated by the operator. This module turns the instruction into
something a script settles: every acceptance criterion in the live queue lands in exactly
one bucket, and the reason names the rule that put it there.

The four buckets:

  REVIEWER-CLOSEABLE  `### Agent` + [REVIEWER] prefix, no carve-out.
                      `fw reviewer` may auto-tick it. This is the whole delegated surface.
  AGENT-SELF          `### Agent`, no [REVIEWER] prefix. The agent closes it under the
                      P-011 verification gate. The reviewer must NOT touch it either —
                      static_scan.py:7, "NEVER modifies AC checkboxes for Human ACs or
                      non-[REVIEWER] Agent ACs".
  OPERATOR-ONLY       Returns to the operator. Either it sits under `### Human` (AEF
                      decision 113: original classification is inviolable) or a carve-out
                      fired.
  MISFILED            A sub-flag on OPERATOR-ONLY, not a bucket of its own: `### Human` +
                      [REVIEWER] prefix. Deterministic Expected clause, filed one heading
                      below where the reviewer may reach. Today it is OPERATOR-ONLY and
                      stays that way. It becomes REVIEWER-CLOSEABLE only if the operator
                      authorises the T-1811/T-1878 Human->Agent conversion, per item.

Every input is a heading, a literal prefix token, a frontmatter field, or a fixed token
list. There is deliberately no scoring, no heuristic and no threshold: there is nowhere in
this file for an agent to decide what counts as high risk.

Usage:
    ./tools/_t770-delegation-boundary.py                 # live tree, summary table
    ./tools/_t770-delegation-boundary.py --json          # machine-readable
    ./tools/_t770-delegation-boundary.py --task T-770    # one task, every AC + reason
    ./tools/_t770-delegation-boundary.py --self-test     # fixtures, with negative controls
"""

import argparse
import glob
import json
import os
import re
import sys
import tempfile

ACTIVE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      ".tasks", "active")

REVIEWER_CLOSEABLE = "REVIEWER-CLOSEABLE"
AGENT_SELF = "AGENT-SELF"
OPERATOR_ONLY = "OPERATOR-ONLY"

# ── Carve-outs ────────────────────────────────────────────────────────────────────────
# The operator's three exceptions — high risk, Tier 0, real UX judgement — expressed so
# that a grep settles each one. First match wins; the reason is the rule's own name.

# Tier 0 and the delegated-initiative boundary: an AC whose body names a gate bypass or a
# destructive action describes an act that is the operator's per CLAUDE.md, whatever the
# reviewer thinks of the code. Literal substrings, matched case-sensitively on the AC body.
TIER0_TOKENS = [
    "--force", "--no-verify", "--skip-", "--i-am-human", "--switch-focus",
    "FW_SAFE_MODE", "FW_ALLOW_", "FW_SWITCH_FOCUS", "FW_UNDECIDABLE_VERSION_PROCEED",
    "force push", "force-push", "hard reset", "rm -rf", "DROP TABLE",
]

# Sovereignty fields. The agent may propose; only the operator confirms. An AC that closes
# on one of these closes on the operator's own field.
SOVEREIGN_TOKENS = [
    "bvp_scores:", "voi_score:", "target_blast_radius:",
    "definition_ratified:", "attestation:", "blocks_arc_0_exit:",
]
# `cost_estimate:` is sovereign; `cost_estimate_proposed:` is the agent's. Substring
# matching cannot tell them apart, so this one needs a boundary-aware pattern.
COST_RE = re.compile(r"\bcost_estimate:(?!_)")

# A release is a sovereignty promise over immutable bytes (G-007).
RELEASE_TOKENS = ["dist/", "MANIFEST.yaml", "fw upgrade"]
RELEASE_RE = re.compile(r"\bVERSION\b")


def _carve_out(task, ac):
    """Return (rule_name, detail) for the first carve-out that fires, else None.

    Order matters, and it is deliberate: the criterion's OWN properties are tested before
    the task's. Both would return OPERATOR-ONLY, but only the intrinsic reason answers the
    question the operator actually asked — could this ever be delegated? `owner: human`
    tested first would mask every [REVIEW] behind "owner-human" and make taste look like a
    filing accident.
    """
    body = ac["body"]
    if ac["prefix"] == "REVIEW":
        return ("taste",
                "[REVIEW] is genuine human judgement — tone, layout, accountability. Never convertible.")
    if ac["prefix"] == "RUBBER-STAMP":
        return ("act-in-the-world",
                "[RUBBER-STAMP] asks a human to DO something (publish, deploy, click). A scanner cannot perform it.")
    for tok in TIER0_TOKENS:
        if tok in body:
            return ("tier0-or-bypass", "AC body names %r" % tok)
    for tok in SOVEREIGN_TOKENS:
        if tok in body:
            return ("sovereignty-field", "AC body names %r" % tok)
    if COST_RE.search(body):
        return ("sovereignty-field", "AC body names 'cost_estimate:' (the confirmed field, not _proposed)")
    for tok in RELEASE_TOKENS:
        if tok in body:
            return ("release-surface", "AC body names %r" % tok)
    if RELEASE_RE.search(body):
        return ("release-surface", "AC body names 'VERSION'")
    if task["workflow_type"] == "inception":
        return ("inception-decision",
                "inception go/no-go is the operator's; the agent may not run `fw inception decide`")
    if task["owner"] == "human":
        return ("owner-human",
                "completing an owner:human task is not delegated (CLAUDE.md, Autonomous Mode Boundaries)")
    return None


def classify(task, ac):
    """The predicate. Returns (bucket, rule, detail, misfiled)."""
    if ac["section"] == "Human":
        carve = _carve_out(task, ac)
        misfiled = ac["prefix"] == "REVIEWER"
        if misfiled:
            return (OPERATOR_ONLY, "human-section",
                    "AEF decision 113 — the reviewer NEVER ticks a `### Human` AC; original "
                    "classification is inviolable. [REVIEWER] prefix means the Expected clause "
                    "is deterministic: eligible for T-1811/T-1878 conversion on the operator's "
                    "word, per item. Not today.", True)
        rule, detail = carve if carve else ("human-section", "filed under `### Human`")
        return (OPERATOR_ONLY, rule, detail, False)

    carve = _carve_out(task, ac)
    if carve:
        return (OPERATOR_ONLY, carve[0], carve[1], False)
    if ac["prefix"] == "REVIEWER":
        return (REVIEWER_CLOSEABLE, "reviewer-prefix-agent-section",
                "`### Agent` + [REVIEWER], no carve-out — `fw reviewer` may auto-tick", False)
    return (AGENT_SELF, "agent-p011",
            "`### Agent`, no [REVIEWER] prefix — the agent closes it under P-011; the reviewer "
            "must not tick it either", False)


# ── Parsing ───────────────────────────────────────────────────────────────────────────

AC_RE = re.compile(r"^- \[([ xX])\]\s*(.*)$")
PREFIX_RE = re.compile(r"^\**\s*\[(REVIEWER|REVIEW|RUBBER-STAMP)\]")


def parse_task(path):
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")

    fm = {"owner": "", "workflow_type": ""}
    if lines and lines[0].strip() == "---":
        for line in lines[1:]:
            if line.strip() == "---":
                break
            m = re.match(r"^(owner|workflow_type):\s*(\S+)", line)
            if m:
                fm[m.group(1)] = m.group(2).strip().strip('"')

    task = {"id": os.path.basename(path).split("-")[0] + "-" + os.path.basename(path).split("-")[1],
            "path": path, "owner": fm["owner"], "workflow_type": fm["workflow_type"]}

    acs = []
    in_ac_section = False
    subsection = ""
    current = None

    def flush():
        if current is not None:
            current["body"] = "\n".join(current["_lines"])
            del current["_lines"]
            acs.append(current)

    for line in lines:
        if line.startswith("## "):
            flush()
            current = None
            in_ac_section = line.strip() == "## Acceptance Criteria"
            subsection = ""
            continue
        if not in_ac_section:
            continue
        if line.startswith("### "):
            flush()
            current = None
            subsection = line[4:].strip()
            continue
        m = AC_RE.match(line)
        if m:
            flush()
            rest = m.group(2)
            pm = PREFIX_RE.match(rest)
            current = {"ticked": m.group(1) not in (" ",),
                       "section": subsection or "Agent",
                       "prefix": pm.group(1) if pm else "",
                       "text": rest,
                       "_lines": [rest]}
        elif current is not None:
            if line.strip() == "" and current["_lines"] and current["_lines"][-1].strip() == "":
                flush()
                current = None
            else:
                current["_lines"].append(line)

    flush()
    return task, acs


def scan(paths):
    rows = []
    for path in sorted(paths):
        task, acs = parse_task(path)
        for ac in acs:
            bucket, rule, detail, misfiled = classify(task, ac)
            rows.append({"task": task["id"], "ticked": ac["ticked"], "section": ac["section"],
                         "prefix": ac["prefix"], "bucket": bucket, "rule": rule,
                         "detail": detail, "misfiled": misfiled,
                         "text": ac["text"][:110]})
    return rows


# ── Self-test ─────────────────────────────────────────────────────────────────────────

FIXTURE = """---
id: T-999
owner: %(owner)s
workflow_type: %(wtype)s
---

## Acceptance Criteria

### Agent
- [ ] [REVIEWER] The block message names both mechanisms
      **Expected:** grep finds the string
- [ ] The importer round-trips the corpus without loss
- [ ] [REVIEWER] The score is written to bvp_scores: on confirmation
- [ ] [REVIEWER] The release artefact lands in dist/ with a matching digest
- [ ] [REVIEWER] The gate can still be bypassed with --force for emergencies

### Human
- [ ] [REVIEWER] The audit section renders not-applicable
      **Expected:** the row reads N/A
- [ ] [REVIEW] The dialogue feels unhurried
- [ ] [RUBBER-STAMP] Publish the release notes

## Verification
"""


def _fixture(owner="agent", wtype="build"):
    fd, path = tempfile.mkstemp(prefix="T-999-selftest-", suffix=".md")
    os.write(fd, (FIXTURE % {"owner": owner, "wtype": wtype}).encode())
    os.close(fd)
    return path


def self_test():
    failures = []

    def check(label, got, want):
        if got != want:
            failures.append("%s: got %r want %r" % (label, got, want))
        print("%-4s %s" % ("FAIL" if got != want else "ok", label))

    path = _fixture()
    rows = scan([path])
    os.unlink(path)
    b = [r["bucket"] for r in rows]
    rules = [r["rule"] for r in rows]

    # Leg 1 — the one genuinely delegated shape, and only it.
    check("agent + [REVIEWER], no carve-out -> REVIEWER-CLOSEABLE", b[0], REVIEWER_CLOSEABLE)
    # Leg 2 — negative control for leg 1: same section, prefix removed, must NOT be closeable.
    check("agent, no prefix -> AGENT-SELF (not closeable)", b[1], AGENT_SELF)
    # Legs 3-5 — each carve-out beats the [REVIEWER] prefix in the same section.
    check("sovereignty field beats [REVIEWER]", (b[2], rules[2]), (OPERATOR_ONLY, "sovereignty-field"))
    check("release surface beats [REVIEWER]", (b[3], rules[3]), (OPERATOR_ONLY, "release-surface"))
    check("bypass token beats [REVIEWER]", (b[4], rules[4]), (OPERATOR_ONLY, "tier0-or-bypass"))
    # Leg 6 — decision 113: section wins over prefix, and the mis-filing is named not fixed.
    check("human + [REVIEWER] -> OPERATOR-ONLY, flagged misfiled",
          (b[5], rows[5]["misfiled"]), (OPERATOR_ONLY, True))
    # Leg 7 — negative control for leg 6: [REVIEW] is NOT flagged misfiled, ever.
    check("human + [REVIEW] -> OPERATOR-ONLY, NOT misfiled",
          (b[6], rows[6]["misfiled"], rules[6]), (OPERATOR_ONLY, False, "taste"))
    check("human + [RUBBER-STAMP] -> OPERATOR-ONLY act-in-the-world",
          (b[7], rules[7]), (OPERATOR_ONLY, "act-in-the-world"))

    # Leg 9 — owner:human demotes the delegated shape. Negative control is leg 1 above,
    # which is the identical file with owner:agent.
    path = _fixture(owner="human")
    rows_h = scan([path])
    os.unlink(path)
    check("owner:human demotes agent+[REVIEWER] to OPERATOR-ONLY",
          (rows_h[0]["bucket"], rows_h[0]["rule"]), (OPERATOR_ONLY, "owner-human"))

    # Leg 10 — inception demotes it too.
    path = _fixture(wtype="inception")
    rows_i = scan([path])
    os.unlink(path)
    check("workflow_type:inception demotes agent+[REVIEWER] to OPERATOR-ONLY",
          (rows_i[0]["bucket"], rows_i[0]["rule"]), (OPERATOR_ONLY, "inception-decision"))

    # Leg 11 — cost_estimate_proposed is the agent's field and must NOT fire the carve-out.
    # This is the negative control for the sovereignty rule: substring matching would
    # wrongly demote it.
    t = {"owner": "agent", "workflow_type": "build"}
    ac_proposed = {"section": "Agent", "prefix": "REVIEWER",
                   "body": "writes cost_estimate_proposed: to the task"}
    ac_confirmed = {"section": "Agent", "prefix": "REVIEWER",
                    "body": "writes cost_estimate: to the task"}
    check("cost_estimate_proposed: does NOT demote", classify(t, ac_proposed)[0], REVIEWER_CLOSEABLE)
    check("cost_estimate: DOES demote", classify(t, ac_confirmed)[0], OPERATOR_ONLY)

    print()
    if failures:
        print("SELF-TEST FAILED (%d)" % len(failures))
        for f in failures:
            print("  " + f)
        return 1
    print("SELF-TEST PASSED — 12 legs, each with a negative control in the set")
    return 0


# ── Main ──────────────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--task", help="restrict to one task id, e.g. T-770")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--unticked-only", action="store_true",
                    help="only criteria still open (the actual queue)")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    pattern = "%s-*.md" % args.task if args.task else "*.md"
    paths = glob.glob(os.path.join(ACTIVE, pattern))
    if not paths:
        print("no task files matched", file=sys.stderr)
        return 2

    rows = scan(paths)
    if args.unticked_only or not args.task:
        rows = [r for r in rows if not r["ticked"]]

    if args.json:
        print(json.dumps(rows, indent=2))
        return 0

    if args.task:
        for r in rows:
            print("[%s] %s %s" % ("x" if r["ticked"] else " ", r["bucket"], r["rule"]))
            print("     %s" % r["text"])
            print("     -> %s" % r["detail"])
        return 0

    counts = {}
    for r in rows:
        counts[r["bucket"]] = counts.get(r["bucket"], 0) + 1
    misfiled = [r for r in rows if r["misfiled"]]
    by_rule = {}
    for r in rows:
        if r["bucket"] == OPERATOR_ONLY:
            by_rule[r["rule"]] = by_rule.get(r["rule"], 0) + 1

    print("Open acceptance criteria in .tasks/active/: %d" % len(rows))
    print()
    for bucket in (REVIEWER_CLOSEABLE, AGENT_SELF, OPERATOR_ONLY):
        print("  %-20s %5d" % (bucket, counts.get(bucket, 0)))
    print()
    print("  OPERATOR-ONLY by rule:")
    for rule in sorted(by_rule, key=lambda k: -by_rule[k]):
        print("    %-26s %5d" % (rule, by_rule[rule]))
    print()
    print("  misfiled ([REVIEWER] under `### Human`): %d across %d task(s)"
          % (len(misfiled), len(set(r["task"] for r in misfiled))))
    print("    -> eligible for T-1811/T-1878 conversion on the operator's word, per item.")
    print()
    human = [r for r in rows if r["section"] == "Human"]
    by_prefix = {}
    for r in human:
        by_prefix[r["prefix"] or "(none)"] = by_prefix.get(r["prefix"] or "(none)", 0) + 1
    print("  the operator's own queue — open `### Human` criteria by prefix: %d" % len(human))
    for p in sorted(by_prefix, key=lambda k: -by_prefix[k]):
        print("    %-14s %5d" % (p, by_prefix[p]))
    print("    '(none)' means the default.md:51 prefix-routing rule was never applied to it,")
    print("    so nothing has ever asked whether it was convertible.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
