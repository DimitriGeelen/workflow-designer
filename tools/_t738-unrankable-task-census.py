#!/usr/bin/env python3
"""T-738: why is each unrankable task unrankable, and what can be proposed for it?

Every task with `quadrant: '-'` is invisible to quadrant-ordered selection. This
reports WHICH of score_blast_radius's three evidence sources was empty for each,
splits the population, and writes a components: PROPOSAL — it applies nothing.

The estimator's OWN functions are imported rather than reimplemented. A
reimplementation would measure my reading of the detector; importing measures the
detector. Class A in particular is only a repro if the real code produced it.

Read-only with respect to task files. Writes one report when --report is given.
"""
import glob, importlib.util, os, re, subprocess, sys
from pathlib import Path

ROOT = "/opt/832-Workflow-designer"
os.chdir(ROOT)
EST = os.path.join(ROOT, ".agentic-framework/agents/termlink/bvp-estimator/estimator.py")

# The estimator derives PROJECT_ROOT as: $PROJECT_ROOT or $FRAMEWORK_ROOT or
# Path(__file__).parents[3]. In a VENDORED install that fallback lands on
# .agentic-framework/, not the project, so every (root / p).is_file() check fails and
# score_blast_radius returns None for EVERYTHING. `fw` sets the env var, so this never
# bites in normal operation — it bites a direct import, which is what this tool does.
# Measured: without this line the census reported 3 spurious "estimator defects".
os.environ.setdefault("PROJECT_ROOT", ROOT)
FW = os.path.join(ROOT, ".agentic-framework/bin/fw")

spec = importlib.util.spec_from_file_location("bvp_estimator", EST)
est = importlib.util.module_from_spec(spec)
spec.loader.exec_module(est)

import yaml


def frontmatter(text):
    fm = text.split("\n---", 1)[0]
    try:
        d = yaml.safe_load(fm.lstrip("-\n")) or {}
    except Exception:
        return {}
    return d if isinstance(d, dict) else {}


def body_of(text):
    parts = text.split("\n---", 1)
    return parts[1] if len(parts) > 1 else text


def quadranted():
    """Task ids the ranker actually places in a quadrant."""
    got = set()
    for q in ("hv-lc", "hv-hc", "lv-lc", "lv-hc"):
        r = subprocess.run([FW, "bvp", "--quadrant", q, "--include-proposed"],
                           capture_output=True, text=True, timeout=180)
        for line in r.stdout.splitlines():
            m = re.match(r"^(T-\d+)", line.strip())
            if m:
                got.add(m.group(1))
    return got


def git_paths_for(tid):
    """Source paths touched by commits that reference this task id.

    This is the SAME signal `components:` is populated from at completion, so a
    proposal built from it is the proposal the framework would itself have made —
    it is not a new opinion about scope.
    """
    r = subprocess.run(["git", "log", "--format=%H", "--grep", tid + ":"],
                       capture_output=True, text=True)
    shas = [s for s in r.stdout.split() if s]
    if not shas:
        return []
    files = set()
    for sha in shas[:20]:
        rr = subprocess.run(["git", "show", "--name-only", "--format=", sha],
                            capture_output=True, text=True)
        for p in rr.stdout.splitlines():
            p = p.strip()
            if not p or not os.path.isfile(p):
                continue
            if p.startswith(".tasks/") or p.startswith(".context/"):
                continue          # task/context churn is not the task's surface
            files.add(p)
    return sorted(files)


def main():
    quad = quadranted()
    rows = []
    for fn in sorted(glob.glob(".tasks/active/T-*.md")):
        m = re.match(r"^\.tasks/active/(T-\d+)-", fn)
        if not m:
            continue
        tid = m.group(1)
        text = open(fn, encoding="utf-8", errors="replace").read()
        fm = frontmatter(text)
        if fm.get("status") == "work-completed":
            continue                       # excluded from the rank by design (T-2223)
        if tid in quad:
            continue                       # rankable — not this task's population
        body = body_of(text)
        tags = fm.get("tags") or []
        comps = [c for c in (fm.get("components") or []) if c]
        tbr = fm.get("target_blast_radius")
        named = sorted(est._paths_named_in_body(body, Path(ROOT)))
        br, ev = est.score_blast_radius(fm, body, tags if isinstance(tags, list) else [])

        # THIRD exclusion mechanism, found by T-738 and not in the original framing:
        # the ranker needs a VALUE score as well as a cost. A task with no
        # bvp_scores_proposed: has no bvp_norm, so it is dropped from the ranking
        # even when its cost is fully computed. Measured: 30 of 149 active tasks.
        has_value = bool(fm.get("bvp_scores_proposed"))

        if not has_value:
            klass = "C-NO-VALUE-SCORE"
        elif named and br is None:
            klass = "A-ESTIMATOR-DEFECT"
        elif br is not None:
            klass = "A2-SCORED-BUT-STILL-UNRANKED"
        else:
            klass = "B-DECLARATION-GAP"

        proposal = []
        if klass.startswith("B"):
            proposal = git_paths_for(tid)
        rows.append({
            "id": tid, "owner": fm.get("owner"), "status": fm.get("status"),
            "wf": fm.get("workflow_type"), "name": (fm.get("name") or "")[:64],
            "components": comps, "tbr": tbr, "named": named,
            "br": br, "ev": ev, "class": klass, "proposal": proposal,
        })

    C = [r for r in rows if r["class"] == "C-NO-VALUE-SCORE"]
    A = [r for r in rows if r["class"] == "A-ESTIMATOR-DEFECT"]
    A2 = [r for r in rows if r["class"] == "A2-SCORED-BUT-STILL-UNRANKED"]
    B = [r for r in rows if r["class"] == "B-DECLARATION-GAP"]
    B1 = [r for r in B if r["proposal"]]
    B2 = [r for r in B if not r["proposal"]]
    agent_owned = [r for r in rows if r["owner"] == "agent"]

    print("=== unrankable non-completed active tasks: %d ===" % len(rows))
    print("  A  estimator defect (body names an EXISTING path, still scored absent) : %d" % len(A))
    print("  A2 scored a blast_radius yet still unranked (other cause)              : %d" % len(A2))
    print("  B  declaration gap (no components, no tbr, no existing path in body)   : %d" % len(B))
    print("     B1 mechanical proposal available from this task's own commits       : %d" % len(B1))
    print("     B2 NO mechanical basis — never worked, names nothing                : %d" % len(B2))
    print("  C  no VALUE score at all -> no bvp_norm -> dropped regardless of cost : %d" % len(C))
    print("  agent-owned among the unrankable                                       : %d" % len(agent_owned))
    if C:
        print("     class C is mechanically fixable with `fw bvp estimate` (advisory verb):")
        print("     %s" % ", ".join(sorted(r["id"] for r in C)))

    print("\n=== the agent-owned unrankable, named individually (AC4) ===")
    for r in sorted(agent_owned, key=lambda x: int(x["id"][2:])):
        print("  %-7s %-13s %-12s %-22s %s" % (r["id"], r["status"], r["wf"] or "-",
                                               r["class"], r["name"][:44]))

    if A:
        print("\n=== CLASS A — estimator defect, with repro ===")
        for r in A:
            print("  %s  named=%s  ->  score_blast_radius returned %r" % (r["id"], r["named"], r["br"]))
            print("     evidence: %s" % r["ev"])

    if "--report" in sys.argv:
        out = ["# T-738 — unrankable task census and `components:` proposal", "",
               "**Generated by** `tools/_t738-unrankable-task-census.py`. "
               "**Nothing here is applied.**", "",
               "| class | n |", "|---|---|",
               "| A — estimator defect | %d |" % len(A),
               "| A2 — scored yet unranked | %d |" % len(A2),
               "| B1 — proposal available | %d |" % len(B1),
               "| B2 — no mechanical basis | %d |" % len(B2), ""]
        out += ["## Class B1 — proposed `components:` (NOT applied)", ""]
        for r in sorted(B1, key=lambda x: int(x["id"][2:])):
            out.append("### %s — %s" % (r["id"], r["name"]))
            out.append("`owner: %s` · `status: %s`" % (r["owner"], r["status"]))
            out.append("")
            out.append("```yaml")
            out.append("components: [%s]" % ", ".join(r["proposal"][:8]))
            out.append("```")
            out.append("")
        out += ["## Class B2 — no mechanical basis, an author must declare", ""]
        for r in sorted(B2, key=lambda x: int(x["id"][2:])):
            out.append("- **%s** (`%s`, %s) — %s" % (r["id"], r["owner"], r["status"], r["name"]))
        out.append("")
        Path("docs/reports/T-738-unrankable-census.md").write_text("\n".join(out), encoding="utf-8")
        print("\nreport written: docs/reports/T-738-unrankable-census.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
