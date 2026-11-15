#!/usr/bin/env python3
"""_t1289-host-contract — the designer's server endpoints against what AEF's Watchtower serves (T-1289, T-1285 GO).

AEF hosts the designer. Every designer feature that needs a server answer degrades quietly when the host does not
answer, so a release can be pinned by AEF and still arrive with features dead. On 2026-10-23, 4 of the 13 endpoints
the designer calls had been missing in AEF for 13-25 days (Check, instance overlay, project field profile, "Suggest
as a field"), and nothing compared the two (T-1285 spike 4). This compares them.

  used    every `/api/<name>` path in src/aef-workflow-designer.html
  served  every route in AEF's Watchtower code (.agentic-framework/web/**/*.py) at the vendor divergence BASELINE
          (.agentic-framework/.vendor-divergence.yaml `baseline_commit`): AEF's own code as the last upgrade vendored
          it, WITHOUT 832's local fixes, which AEF does not run
  declined used - served, that AEF has ruled it will not serve (DECLINED below, each with its ruling; T-1414)
  missing used - served - declined: the gaps nobody has decided

  python3 tools/_t1289-host-contract.py [--json] [--ref <git ref of AEF's vendored code>]
  exit 0 nothing missing · 1 something missing · 2 cannot read a side (never a silent "nothing missing")
  A declined endpoint never makes the exit 1, and one AEF starts serving counts as served, so a ruling that is
  overtaken shows up as served rather than staying declined.

LIMITS, stated so a clean run cannot claim more than it measured:
  - paths only: a route can exist and still differ in method or payload from what the designer sends;
  - the vendored copy is only as new as 832's last framework upgrade: AEF may already serve more (or less) today;
  - designer side is a text scan for "/api/<name>": a path built at run time from pieces would be missed.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
DIV = os.path.join(ROOT, ".agentic-framework", ".vendor-divergence.yaml")

# T-1414: endpoints AEF has ruled it will not serve. Each entry carries the ruling and where it was given, so the
# report says why, not only that. Remove an entry when AEF reverses the ruling.
_T4737 = ("AEF T-4737 IW-3: write paths with an approval flow and no recorded demand; revisit only if an operator "
          "asks (consult-832-Workflow-designer msg 219d838b, 2026-11-15)")
DECLINED = {
    "/api/field-profile": _T4737,
    "/api/field-suggestions": _T4737,
}


def classify(used, served, declined):
    """(served, declined, missing) for the used endpoints. Served wins over declined."""
    ok = [u for u in used if u in served]
    dec = [u for u in used if u not in served and u in declined]
    missing = [u for u in used if u not in served and u not in declined]
    return ok, dec, missing


def git(*args):
    return subprocess.run(["git", "-C", ROOT] + list(args), capture_output=True, text=True)


def baseline_ref():
    with open(DIV, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"^baseline_commit:\s*([0-9a-f]{7,40})\s*$", line)
            if m:
                return m.group(1)
    raise RuntimeError("no baseline_commit in %s" % DIV)


def used_endpoints():
    with open(SRC, encoding="utf-8") as fh:
        return sorted(set(re.findall(r"/api/[a-z_-]+", fh.read())))


def served_endpoints(ref):
    ls = git("ls-tree", "-r", "--name-only", ref, ".agentic-framework/web/")
    if ls.returncode != 0:
        raise RuntimeError("cannot list AEF's web code at %s: %s" % (ref, ls.stderr.strip()))
    served = set()
    for path in ls.stdout.split():
        if not path.endswith(".py"):
            continue
        body = git("show", "%s:%s" % (ref, path))
        if body.returncode != 0:
            raise RuntimeError("cannot read %s at %s" % (path, ref))
        for route in re.findall(r"route\(\s*['\"]([^'\"]+)['\"]", body.stdout):
            served.add(route.split("<")[0].rstrip("/"))
    if not served:
        raise RuntimeError("no routes found in AEF's web code at %s: the scan read nothing" % ref)
    return served


def main(argv):
    as_json = "--json" in argv
    ref = argv[argv.index("--ref") + 1] if "--ref" in argv else None
    try:
        ref = ref or baseline_ref()
        used = used_endpoints()
        if not used:
            raise RuntimeError("no /api/ path found in %s: the scan read nothing" % SRC)
        served = served_endpoints(ref)
    except (OSError, RuntimeError) as e:
        print("NOT CHECKED: %s" % e)
        return 2
    ok, dec, missing = classify(used, served, DECLINED)
    if as_json:
        print(json.dumps({"ref": ref, "used": used, "served": ok, "missing": missing,
                          "declined": {d: DECLINED[d] for d in dec}}, indent=1))
    else:
        print("%d used, %d served, %d missing%s%s (AEF code at %s)" % (
            len(used), len(ok), len(missing),
            (": " + ", ".join(missing)) if missing else "",
            ("; %d not served by design (AEF's ruling, see --json): %s" % (len(dec), ", ".join(dec))) if dec else "",
            ref[:9]))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
