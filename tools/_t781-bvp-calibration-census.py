#!/usr/bin/env python3
"""T-781 RCA: measure the estimator's output over the whole population."""
import glob, re, yaml, os
from collections import Counter

os.chdir("/opt/832-Workflow-designer")
files = sorted(glob.glob(".tasks/active/T-*.md") + glob.glob(".tasks/completed/T-*.md"))

rows = []
for f in files:
    s = open(f, encoding="utf-8", errors="replace").read()
    fm = s.split("\n---", 1)[0]
    try:
        d = yaml.safe_load(fm.lstrip("-\n")) or {}
    except Exception:
        continue
    if not isinstance(d, dict):
        continue
    tid = d.get("id")
    if not tid:
        continue
    ce = d.get("cost_estimate_proposed") or []
    last = ce[-1]["cost_estimate"] if ce and isinstance(ce[-1], dict) else {}
    bs = d.get("bvp_scores_proposed") or []
    scores = bs[-1].get("scores", {}) if bs and isinstance(bs[-1], dict) else {}
    rat = bs[-1].get("rationale", "") if bs and isinstance(bs[-1], dict) else ""
    rows.append({
        "id": tid,
        "status": d.get("status"),
        "wf": d.get("workflow_type"),
        "components": len(d.get("components") or []),
        "br": last.get("blast_radius"),
        "tier": last.get("tier"),
        "effort": last.get("effort"),
        "scores": scores,
        "rat": rat,
        "active": f.startswith(".tasks/active"),
    })

print("POPULATION: %d task files (%d active, %d completed)"
      % (len(rows), sum(r["active"] for r in rows), sum(not r["active"] for r in rows)))

# --- 1. blast_radius presence ---
have = [r for r in rows if r["br"] is not None]
miss = [r for r in rows if r["br"] is None]
print("\n=== 1. blast_radius presence (weight 0.6, dominant F8 term) ===")
print("  present: %d   absent: %d   (%.0f%% absent)"
      % (len(have), len(miss), 100.0 * len(miss) / max(1, len(rows))))
print("  absent, by status:", dict(Counter(r["status"] for r in miss).most_common(6)))
print("  present, by status:", dict(Counter(r["status"] for r in have).most_common(6)))

# --- 2. where does a PRESENT blast_radius come from? ---
print("\n=== 2. provenance of a present blast_radius ===")
src = Counter()
for r in have:
    if r["components"] > 0:
        src["components: declared"] += 1
    elif "body-paths" in r["rat"] or r["wf"] == "inception":
        src["body-paths or inception target"] += 1
    else:
        src["body-paths (inferred)"] += 1
print(" ", dict(src))
print("  tasks with NON-EMPTY components:, whole corpus: %d of %d"
      % (sum(1 for r in rows if r["components"] > 0), len(rows)))

# --- 3. the completion asymmetry ---
print("\n=== 3. does blast_radius track COMPLETION rather than scope? ===")
for st in ("work-completed", "started-work", "captured", "issues"):
    grp = [r for r in rows if r["status"] == st]
    if not grp:
        continue
    n_br = sum(1 for r in grp if r["br"] is not None)
    print("  %-15s n=%-4d blast_radius present=%-4d (%.0f%%)"
          % (st, len(grp), n_br, 100.0 * n_br / len(grp)))

# --- 4. driver score distribution ---
print("\n=== 4. value-driver score distribution (are drivers discriminating?) ===")
allk = set()
for r in rows:
    allk |= set(r["scores"].keys())
for k in sorted(allk):
    vals = [r["scores"][k] for r in rows if k in r["scores"]]
    if not vals:
        continue
    z = sum(1 for v in vals if v == 0)
    print("  %-10s n=%-4d zero=%-4d (%3.0f%%)  distinct=%s"
          % (k, len(vals), z, 100.0 * z / len(vals), sorted(set(vals))))

# --- 5. tier / effort spread ---
print("\n=== 5. tier and effort spread ===")
for fld in ("tier", "effort"):
    vals = [r[fld] for r in rows if r[fld] is not None]
    print("  %-7s n=%-4d distinct=%s  most common=%s"
          % (fld, len(vals), sorted(set(vals)), Counter(vals).most_common(3)))

# --- 6. rationale 'no-signal' rate ---
print("\n=== 6. how often does the heuristic say it had NO SIGNAL? ===")
ns = Counter()
tot = Counter()
for r in rows:
    for m in re.finditer(r"(\w[\w-]*)=\d+\s*\(([^)]*)\)", r["rat"]):
        drv, why = m.group(1), m.group(2)
        tot[drv] += 1
        if "no-signal" in why:
            ns[drv] += 1
for drv in sorted(tot):
    print("  %-10s no-signal %d/%d (%3.0f%%)"
          % (drv, ns[drv], tot[drv], 100.0 * ns[drv] / tot[drv]))
