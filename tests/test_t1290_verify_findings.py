#!/usr/bin/env python3
"""T-1290: review findings carry map evidence, and the kit checks it mechanically.

Pins:
  1. verify-findings.py labels: job 082's real GLM-5.3 clean finding is `unverified`; the same claim cited at its
     true line is `verified`; a wrong line is `unverified`; null evidence is `absence`.
  2. A calibration REPLAY through the real loop.sh --calibrate (a fake reviewer writes canned REVIEW.json files)
     prints the labels, and the VERDICT is unchanged: an unverified finding on the clean map still FAILS calibration
     (the gate counts every finding; the label only says why), and a clean [] still PASSES.
  3. The kit ships verify-findings.py.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERIFY = os.path.join(ROOT, "docs", "authoring-kit", "verify-findings.py")
BUILD = os.path.join(ROOT, "tools", "build-authoring-kit.py")
CLEAN_MAP = os.path.join(ROOT, "docs", "authoring-kit", "calibration", "clean.bpmn")
GLM_082 = {  # job 082's real clean-map finding (GLM-5.3, 2026-10-23), verbatim fields that matter here
    "element": "accept-order-anyway", "category": "readability", "severity": "minor",
    "source_evidence": "source is silent",
    "problem": "Gateway 'accept-order-anyway' sets default=\"credit-limit-exceeded--pick-parts\" ...",
    "correction": "Remove the default attribute from gateway 'accept-order-anyway' ...",
}


def run_verify(map_path, findings, tmp):
    p = os.path.join(tmp, "r.json")
    json.dump(findings, open(p, "w"))
    r = subprocess.run([sys.executable, VERIFY, map_path, p], capture_output=True, text=True)
    return [l.split()[0] for l in r.stdout.splitlines() if l.startswith("  ")]


def main():
    fails = []
    tmp = tempfile.mkdtemp(dir=os.path.join(ROOT, ".context", "working"), prefix="t1290.")
    try:
        lines = open(CLEAN_MAP, encoding="utf-8").read().split("\n")
        dline = next(i + 1 for i, l in enumerate(lines) if 'default="credit-limit-exceeded--pick-parts"' in l)
        gline = next(i + 1 for i, l in enumerate(lines) if 'id="accept-order-anyway"' in l and "exclusiveGateway" in l)
        quote = 'default="credit-limit-exceeded--pick-parts"'
        cases = [
            ("job 082's real finding (no map_evidence)", [GLM_082], "unverified"),
            ("the claim cited at its true line", [dict(GLM_082, map_evidence={"line": dline, "quote": quote})], "verified"),
            ("the claim cited at the gateway it names (wrong line)", [dict(GLM_082, map_evidence={"line": gline, "quote": quote})], "unverified"),
            ("an absence claim", [dict(GLM_082, map_evidence=None)], "absence"),
        ]
        for name, findings, want in cases:
            got = run_verify(CLEAN_MAP, findings, tmp)
            if got != [want]:
                fails.append("%s: want %s, got %s" % (name, want, got))

        # build a kit and replay a calibration with a fake reviewer
        kitout = os.path.join(tmp, "kit")
        b = subprocess.run([sys.executable, BUILD, "--version", "0.0.0-t1290", "--out", kitout], capture_output=True, text=True)
        if b.returncode != 0:
            fails.append("kit build failed: %s" % (b.stdout + b.stderr)[-400:])
        else:
            kitdir = next(os.path.join(dp, "") for dp, dn, fn in os.walk(kitout) if "loop.sh" in fn)
            if not os.path.exists(os.path.join(kitdir, "verify-findings.py")):
                fails.append("the built kit does not ship verify-findings.py")
            expected = json.load(open(os.path.join(kitdir, "calibration", "expected.json")))["planted"]
            planted = [{"element": e["elements"][0], "category": e["categories"][0], "severity": "major",
                        "source_evidence": "source is silent", "map_evidence": None,
                        "problem": "planted", "correction": "fix"} for e in expected]
            for clean_findings, want_rc, label in (([GLM_082], 1, "unverified"), ([], 0, None)):
                canned = os.path.join(tmp, "canned")
                os.makedirs(canned, exist_ok=True)
                json.dump(clean_findings, open(os.path.join(canned, "clean.json"), "w"))
                json.dump(planted, open(os.path.join(canned, "planted.json"), "w"))
                fake = os.path.join(tmp, "fake-reviewer.sh")
                open(fake, "w").write('cp "%s/$(basename "$PWD").json" REVIEW.json\n' % canned)
                wd = os.path.join(tmp, "cal-%d" % want_rc)
                env = dict(os.environ, KIT_REVIEWER_CMD="bash %s" % fake)
                r = subprocess.run(["bash", os.path.join(kitdir, "loop.sh"), "--calibrate", wd], capture_output=True, text=True, env=env)
                out = r.stdout + r.stderr
                if r.returncode != want_rc:
                    fails.append("replay with clean=%s: verdict rc %d, want %d (the gate must be unchanged)\n%s"
                                 % (json.dumps(clean_findings)[:40], r.returncode, want_rc, out[-600:]))
                if label and ("unverified" not in out or "map evidence, clean map" not in out):
                    fails.append("replay did not print the clean finding's label\n%s" % out[-600:])
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    for f in fails:
        print("FAIL: " + f)
    if fails:
        return 1
    print("OK: 4 labels as expected (082's real finding unverified); calibration replay prints labels and the verdict"
          " is unchanged (unverified clean finding FAILS, clean [] PASSES); the kit ships verify-findings.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
