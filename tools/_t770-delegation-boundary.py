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
import subprocess
import sys
import tempfile

ACTIVE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      ".tasks", "active")

REVIEWER_CLOSEABLE = "REVIEWER-CLOSEABLE"
REVIEWER_JUDGES = "REVIEWER-JUDGES"
AGENT_SELF = "AGENT-SELF"
OPERATOR_ONLY = "OPERATOR-ONLY"

# ── `### Human` criteria: AEF decides (T-1079, operator directive PD-357, 2026-10-06) ──────
# "Review routing follows the CURRENT AEF ruleset; 832's own rules only where AEF is silent; on a
# conflict AEF wins." AEF classifies Human criteria in lib/delegation.py (CLASS_TO_DELEGATION, "THE
# one encoding"; T-3557 sends taste and unclassified to REVIEWER-JUDGES). So this file no longer
# routes a Human criterion itself: it asks AEF. That also settles G-052 (two encodings of one
# boundary). AEF does not examine `### Agent` rows, so the 832 rules below still route those.
#
# T-1080: AEF's published interface is the verb `fw task classify-ac` (T-3963, v1.8.6), not an
# import of lib/delegation — the verb is the contract, the module is AEF's to rearrange. Anything
# short of a clean answer (verb missing, non-zero exit, unparsable JSON) fails CLOSED to the operator.
_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_FW = os.path.join(_ROOT, ".agentic-framework", "bin", "fw")
_RENDER_LIB = os.path.join(_ROOT, ".agentic-framework", "lib", "render_surface.sh")
# The classes `--render-surface` can still change. AEF's precedence puts tier0/sovereignty/
# act-in-the-world BEFORE render-surface, and every other class already routes to REVIEWER-JUDGES,
# same as render-surface — so only these two can move. The self-test pins that precedence.
_RENDER_MOVABLE = ("REVIEWER-CLOSEABLE", "AGENT-SELF")


def _norm(title):
    return re.sub(r"\s+", " ", title or "").strip()[:100]


def _classify_ac(path, workflow_type, render_surface):
    """Rows from `fw task classify-ac --file PATH --json`, or None if AEF gave no clean answer."""
    cmd = [_FW, "task", "classify-ac", "--file", path, "--json"]
    if workflow_type:
        cmd += ["--workflow-type", workflow_type]
    if render_surface:
        cmd.append("--render-surface")
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        rows = json.loads(out.stdout) if out.returncode == 0 else None
    except (OSError, subprocess.SubprocessError, ValueError):
        return None
    if not isinstance(rows, list):
        return None
    return rows


def _touches_render_surface(path):
    """AEF's own predicate (lib/render_surface.sh) — the one `fw task delegate` and the close gate use."""
    try:
        return subprocess.run(["bash", "-c", 'source "$1" && task_touches_render_surface "$2"', "_",
                               _RENDER_LIB, path], capture_output=True, timeout=120).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return True   # unknown: the flag can only move a criterion toward the reviewer, never away


def aef_human_classes(path, workflow_type=""):
    """{normalised criterion title: (delegation_class, class, reason)} from AEF, or None."""
    rows = _classify_ac(path, workflow_type, False)
    # The render-surface check is a `git log` per task, so it runs only when it could change a route.
    if rows and any(r.get("subhead") == "Human" and r.get("delegation_class") in _RENDER_MOVABLE
                    for r in rows) and _touches_render_surface(path):
        rows = _classify_ac(path, workflow_type, True)
    if rows is None:
        return None
    try:
        return {_norm(r["title"]): (r["delegation_class"], r["class"], r["reason"])
                for r in rows if r.get("subhead") == "Human"}
    except (KeyError, TypeError):
        return None

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


def classify(task, ac, aef=None):
    """The predicate. Returns (bucket, rule, detail, misfiled).

    `aef` is aef_human_classes(path) for the task file: a `### Human` criterion is routed by AEF
    (PD-357). No entry for it, or no AEF at all, fails closed to the operator."""
    if ac["section"] == "Human":
        misfiled = ac["prefix"] == "REVIEWER"   # [REVIEWER] filed under Human: still worth naming
        if aef is None:
            return (OPERATOR_ONLY, "aef-unavailable",
                    "AEF's `fw task classify-ac` gave no clean answer — Human criteria fail closed to "
                    "the operator (T-1079, T-1080)", misfiled)
        hit = aef.get(_norm(ac.get("text") or ac.get("body", "").split("\n")[0]))
        if hit is None:
            return (OPERATOR_ONLY, "aef-unmatched",
                    "AEF's parser does not list this Human criterion — fails closed to the operator "
                    "(T-1079)", misfiled)
        bucket, cls, reason = hit
        return (bucket, "aef:" + cls, reason, misfiled)

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
        aef = (aef_human_classes(path, task.get("workflow_type") or "")
               if any(a["section"] == "Human" for a in acs) else {})
        for ac in acs:
            bucket, rule, detail, misfiled = classify(task, ac, aef)
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

    ran = []

    def check(label, got, want):
        ran.append(label)
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
    # Legs 6-8 — `### Human` criteria are routed by AEF (T-1079, PD-357), never by this file.
    # Leg 6: a [REVIEWER] filed under Human is still NAMED misfiled, and its bucket is AEF's.
    path = _fixture()
    aef = aef_human_classes(path)
    os.unlink(path)
    check("AEF's `fw task classify-ac` answers for the fixture's Human criteria",
          aef is not None and len(aef) == 3, True)
    aef = aef or {}
    want6 = aef.get(_norm(rows[5]["text"]), (None,))[0]
    check("human + [REVIEWER] -> AEF's bucket, flagged misfiled",
          (b[5], rows[5]["misfiled"], rules[5].startswith("aef:")), (want6, True, True))
    # Leg 7 — the PD-357 change itself: taste goes to the reviewer, as in AEF (T-3557).
    check("human + [REVIEW] taste -> REVIEWER-JUDGES (AEF), NOT misfiled",
          (b[6], rows[6]["misfiled"], rules[6]), (REVIEWER_JUDGES, False, "aef:taste"))
    # Leg 8 — negative control for leg 7: an AEF carve-out still returns to the operator.
    check("human + [RUBBER-STAMP] publish -> OPERATOR-ONLY act-in-the-world (AEF carve-out)",
          (b[7], rules[7]), (OPERATOR_ONLY, "aef:act-in-the-world"))
    # Leg 8b — fail closed: with no AEF classification a Human criterion goes to the operator.
    ac_h = {"section": "Human", "prefix": "REVIEW", "text": "[REVIEW] The dialogue feels unhurried",
            "body": "[REVIEW] The dialogue feels unhurried"}
    check("no AEF module -> Human criterion fails closed to OPERATOR-ONLY",
          classify({"owner": "agent", "workflow_type": "build"}, ac_h, None)[:2],
          (OPERATOR_ONLY, "aef-unavailable"))
    check("AEF lists no such criterion -> fails closed to OPERATOR-ONLY",
          classify({"owner": "agent", "workflow_type": "build"}, ac_h, {})[:2],
          (OPERATOR_ONLY, "aef-unmatched"))
    # Leg 8c (T-1080) — anything short of a clean answer from the verb is "no AEF": verb missing,
    # non-zero exit, output that is not a JSON list. Each must yield None, i.e. leg 8b's fail-closed.
    global _FW
    real_fw = _FW
    path = _fixture()
    fake_dir = tempfile.mkdtemp(prefix="t770-fakefw-")
    fakes = {"verb missing": os.path.join(fake_dir, "absent"),
             "non-zero exit": os.path.join(fake_dir, "fails"),
             "not JSON": os.path.join(fake_dir, "garbage"),
             "JSON but not a list": os.path.join(fake_dir, "dict")}
    for name, body in (("fails", "echo '[]'; exit 3"), ("garbage", "echo 'classify-ac: unknown verb'"),
                       ("dict", "echo '{\"rows\": []}'")):
        with open(os.path.join(fake_dir, name), "w") as fh:
            fh.write("#!/bin/sh\n%s\n" % body)
        os.chmod(os.path.join(fake_dir, name), 0o755)
    try:
        for label, fake in fakes.items():
            _FW = fake
            check("classify-ac %s -> no AEF answer (fails closed)" % label, aef_human_classes(path, "build"), None)
    finally:
        _FW = real_fw
        os.unlink(path)
        for name in os.listdir(fake_dir):
            os.unlink(os.path.join(fake_dir, name))
        os.rmdir(fake_dir)
    # Leg 8d (T-1080) — pins the AEF precedence that lets aef_human_classes skip the render-surface
    # check unless a row is REVIEWER-CLOSEABLE or AGENT-SELF: with --render-surface, an act-in-the-world
    # criterion stays OPERATOR-ONLY and a taste one stays REVIEWER-JUDGES (neither can move), while a
    # deterministic one moves to REVIEWER-JUDGES. If AEF reorders its classes this goes red.
    pin_dir = tempfile.mkdtemp(prefix="t770-pin-")
    pin = os.path.join(pin_dir, "criteria.md")
    with open(pin, "w") as fh:
        fh.write("### Human\n- [ ] [RUBBER-STAMP] Publish the release to npm\n"
                 "- [ ] [REVIEW] The dialogue feels unhurried\n"
                 "- [ ] [REVIEWER] The audit section renders not-applicable\n"
                 "      **Expected:** the row reads N/A\n")
    try:
        plain = _classify_ac(pin, "build", False) or []
        flag = _classify_ac(pin, "build", True) or []
    finally:
        os.unlink(pin)
        os.rmdir(pin_dir)
    check("precedence pin: classify-ac answers both ways", (len(plain), len(flag)), (3, 3))
    if len(plain) == 3 and len(flag) == 3:
        check("precedence pin: act-in-the-world is not moved by --render-surface",
              (plain[0]["delegation_class"], flag[0]["delegation_class"]), (OPERATOR_ONLY, OPERATOR_ONLY))
        check("precedence pin: taste routes like render-surface",
              (plain[1]["delegation_class"], flag[1]["delegation_class"]), (REVIEWER_JUDGES, REVIEWER_JUDGES))
        check("precedence pin: a movable class is moved by --render-surface",
              (plain[2]["delegation_class"] in _RENDER_MOVABLE, flag[2]["delegation_class"]),
              (True, REVIEWER_JUDGES))

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
    print("SELF-TEST PASSED — %d checks, each with a negative control in the set" % len(ran))
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
    for bucket in (REVIEWER_CLOSEABLE, REVIEWER_JUDGES, AGENT_SELF, OPERATOR_ONLY):
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
