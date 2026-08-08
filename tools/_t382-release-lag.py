#!/usr/bin/env python3
"""G-024 prevention — hold the PINNED artifact and src in one instrument.

The gap: "no instrument holds the pinned artifact and src at the same time, so a
consumer-visible fix can sit unreleased indefinitely with nothing reporting it."
That already happened — a peer waited 9 days for a fix that existed in src the
whole time, because every gate we run is scoped to src and the consumer runs the
artifact.

WHY THIS IS NOT ANOTHER G-015. G-015 is 75 verification blocks asserting
`diff src dist` — a GLOBAL, ALWAYS-MOVING property, permanently red and therefore
ignored. "src differs from the release" is true five minutes after any release and
carries no information. The signal here is deliberately not difference but AGE:
how long the product's oldest unshipped change has been sitting. A number that is
0 immediately after a cut, grows only with real delay, and is actionable at a glance.

TWO SEPARATE LAGS, MEASURED SEPARATELY. There are three points on this seam, not two:

    src  --(cut a release)-->  dist/MANIFEST latest  --(peer re-pins)-->  peer's pin

Leg 1 (BUILD LAG)    src ahead of our own latest release — a fix we have not cut.
Leg 2 (ADOPTION LAG) our latest release ahead of the peer's pin — cut but not taken up.

Collapsing them would let one hide the other: a perfectly current release the peer
never adopted looks identical, from the consumer's seat, to no release at all.

BOUND ON LEG 2, PRINTED IN THE OUTPUT AND NOT ONLY HERE. The peer's pin is read from
`.agentic-framework/policy/designer-pin.yaml`, a VENDORED copy — it reports what the
peer had pinned when we last re-vendored, not what they have pinned now. Only they can
answer the latter, on the rail. Leg 2 is therefore a LOWER BOUND: a stale vendored pin
makes it report LESS adoption lag, never more, so the single direction it errs in is
the reassuring one. That is precisely why the bound is printed next to the number
rather than filed in a comment.

Exit: 0 ok, 1 warn, 2 fail, 3 could-not-measure (deliberately never confused with ok).
"""

import subprocess
import sys
import datetime
import hashlib
import os
import re

PROJ = "/opt/832-Workflow-designer"
SRC = "src/aef-workflow-designer.html"
MANIFEST = os.path.join(PROJ, "dist/MANIFEST.yaml")
PEER_PIN = os.path.join(PROJ, ".agentic-framework/policy/designer-pin.yaml")

# Thresholds chosen from the INCIDENT, not from the current tree: the recorded harm was
# a peer waiting 9 days. WARN below that so it is visible before it repeats; FAIL past
# it so a repeat cannot pass quietly. Reading today's value first and then picking
# numbers that clear it would be fitting the gate to the tree.
WARN_DAYS = 7
FAIL_DAYS = 14


def git(*args, check=True):
    r = subprocess.run(["git", "-C", PROJ, *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError("git %s failed: %s" % (" ".join(args), r.stderr.strip()))
    return r.stdout.strip()


def yaml_scalar(path, key):
    """Minimal top-level `key: value` read — avoids a yaml dependency inside a gate."""
    with open(path) as f:
        for line in f:
            m = re.match(r'^%s:\s*"?([^"#\s]+)"?' % re.escape(key), line)
            if m:
                return m.group(1)
    return None


def days_since(iso):
    d = datetime.datetime.fromisoformat(iso)
    return (datetime.datetime.now(d.tzinfo) - d).days


def unreleased_since(tag, path):
    out = git("log", "--reverse", "--format=%h\x1f%cI\x1f%s", "%s..HEAD" % tag, "--", path)
    if not out:
        return 0, [], None
    rows = [l.split("\x1f", 2) for l in out.splitlines()]
    return len(rows), rows, rows[0]


def measure(tag_override=None):
    """Pure measurement, no verdict — so the teeth can drive it with a synthetic tag
    and read exactly the numbers the gate reads."""
    res = {}
    version = yaml_scalar(MANIFEST, "latest")
    if not version:
        raise RuntimeError("cannot read `latest:` from %s" % MANIFEST)
    res["version"] = version
    tag = tag_override or ("designer-v%s" % version)
    res["tag"] = tag

    if not git("tag", "-l", tag):
        raise RuntimeError(
            "release tag %s does not exist — cannot measure build lag. "
            "A missing tag is NOT zero lag." % tag)

    # The artifact MANIFEST names must exist and hash to what MANIFEST claims. A pin
    # that does not describe the bytes on disk makes every number below a statement
    # about a document nobody has.
    art_rel = yaml_scalar(MANIFEST, "artifact")
    claimed = yaml_scalar(MANIFEST, "sha256")
    art = os.path.join(PROJ, art_rel) if art_rel else None
    if not art or not os.path.exists(art):
        raise RuntimeError("MANIFEST artifact missing on disk: %r" % art_rel)
    res["artifact"] = art_rel
    res["sha_claimed"] = claimed
    res["sha_actual"] = hashlib.sha256(open(art, "rb").read()).hexdigest()
    res["sha_ok"] = (res["sha_actual"] == claimed)

    n, rows, oldest = unreleased_since(tag, SRC)
    res["build_commits"] = n
    res["build_rows"] = rows
    res["build_oldest"] = oldest
    res["build_days"] = days_since(oldest[1]) if oldest else 0

    # Leg 2 — adoption. Lower bound; see module docstring.
    peer_v = yaml_scalar(PEER_PIN, "version") if os.path.exists(PEER_PIN) else None
    res["peer_version"] = peer_v
    res["peer_pin_readable"] = peer_v is not None
    res["adopt_days"] = 0
    res["adopt_behind"] = None
    if peer_v and peer_v != version:
        res["adopt_behind"] = "%s -> %s" % (peer_v, version)
        rel_tag = "designer-v%s" % version
        if git("tag", "-l", rel_tag):
            res["adopt_days"] = days_since(git("log", "-1", "--format=%cI", rel_tag))
        else:
            res["adopt_days"] = None
    return res


def verdict(res):
    """ok | warn | fail. Separated from measure() so the mapping can be asserted
    directly on constructed inputs, without re-running git."""
    reasons = []
    level = "ok"

    def esc(to):
        nonlocal level
        order = {"ok": 0, "warn": 1, "fail": 2}
        if order[to] > order[level]:
            level = to

    if not res["sha_ok"]:
        reasons.append("MANIFEST sha does not match the artifact on disk")
        esc("fail")
    if not res["peer_pin_readable"]:
        # Not a pass. An unmeasured leg reported as ok is how absence starts carrying
        # a decision.
        reasons.append("peer pin unreadable — adoption lag NOT measured")
        esc("warn")
    if res["build_commits"]:
        d = res["build_days"]
        if d >= FAIL_DAYS:
            reasons.append("oldest unshipped product change is %dd old (>= %dd)" % (d, FAIL_DAYS))
            esc("fail")
        elif d >= WARN_DAYS:
            reasons.append("oldest unshipped product change is %dd old (>= %dd)" % (d, WARN_DAYS))
            esc("warn")
    if res["adopt_behind"]:
        a = res["adopt_days"]
        if a is None:
            reasons.append("peer behind (%s) by an unmeasurable amount" % res["adopt_behind"])
            esc("fail")
        elif a >= FAIL_DAYS:
            reasons.append("peer pin behind (%s), release %dd old (>= %dd)" % (res["adopt_behind"], a, FAIL_DAYS))
            esc("fail")
        else:
            reasons.append("peer pin behind (%s), release %dd old" % (res["adopt_behind"], a))
            if a >= WARN_DAYS:
                esc("warn")
    return level, reasons


def report(res, level, reasons):
    print("=== T-382 / G-024 — release lag (src <-> released artifact <-> peer pin) ===")
    print("released:     %s  (%s)" % (res["version"], res["artifact"]))
    print("manifest sha: %s" % ("matches the artifact on disk" if res["sha_ok"] else
                                "MISMATCH claimed=%s actual=%s" % (res["sha_claimed"][:12], res["sha_actual"][:12])))
    print()
    print("-- leg 1: BUILD LAG (src ahead of our own release) --")
    print("   unshipped product commits since %s: %d" % (res["tag"], res["build_commits"]))
    if res["build_oldest"]:
        print("   oldest: %s  %s  (%d days)" % (res["build_oldest"][0], res["build_oldest"][1][:10], res["build_days"]))
        print("   every commit below changes the single-file product a consumer receives:")
        for r in res["build_rows"]:
            print("     %s %s  %s" % (r[0], r[1][:10], r[2][:86]))
    else:
        print("   (none — src carries nothing the release does not)")
    print()
    print("-- leg 2: ADOPTION LAG (release ahead of the peer's pin) --")
    if not res["peer_pin_readable"]:
        print("   NOT MEASURED — peer pin unreadable at %s" % PEER_PIN)
    elif res["adopt_behind"]:
        print("   peer pin behind: %s   (our release is %s days old)" % (res["adopt_behind"], res["adopt_days"]))
    else:
        print("   peer pin == our latest (%s)" % res["version"])
    print("   BOUND: read from a VENDORED copy of the peer's policy. This reports what")
    print("          they had pinned at our last re-vendor, NOT what they have pinned")
    print("          now. It can therefore only UNDER-report adoption lag. Confirming")
    print("          the current value requires asking them on the rail.")
    print()
    print("verdict: %s" % level.upper())
    for r in reasons:
        print("  - %s" % r)


def teeth():
    """Prove the gauge moves in BOTH directions and that each escalation fires on its
    own. A gauge that can only say 'behind' would report lag on a freshly cut release;
    one that can only say 'ok' IS the gap this tool exists to close."""
    print("=== teeth ===")
    passed = failed = 0

    def leg(name, cond, detail=""):
        nonlocal passed, failed
        if cond:
            passed += 1
            print("  PASS  %s %s" % (name, detail))
        else:
            failed += 1
            print("  FAIL  %s %s" % (name, detail))

    # 1. The CLEAN state must be reachable — otherwise a green can never be earned and
    #    the tool is a constant.
    head_tag = "_t382_teeth_head"
    subprocess.run(["git", "-C", PROJ, "tag", "-f", head_tag, "HEAD"], capture_output=True, text=True)
    try:
        clean = measure(tag_override=head_tag)
        leg("clean state reachable (lag 0 when the release IS head)",
            clean["build_commits"] == 0 and clean["build_days"] == 0,
            "-> commits=%d days=%d" % (clean["build_commits"], clean["build_days"]))
        lv, _ = verdict(clean)
        leg("clean leg-1 state does not FAIL", lv in ("ok", "warn"), "-> %s" % lv)
    finally:
        subprocess.run(["git", "-C", PROJ, "tag", "-d", head_tag], capture_output=True, text=True)

    # 2. The DIRTY state must be reachable. First attempt used designer-v0.4.0 as a
    #    "deliberately old" baseline; it measured 13d — just under FAIL_DAYS — so the
    #    leg went red. The tempting repair is to assert `>= WARN_DAYS` instead, which
    #    would be lowering the bar until the tree clears it. The real fix is a baseline
    #    that cannot age out: the repository's ROOT commit, which is by construction the
    #    oldest point that exists. A synthetic tag keeps measure()'s contract (it takes a
    #    tag, not a sha) without special-casing the production path for a test.
    cur = measure()
    root = git("rev-list", "--max-parents=0", "HEAD").splitlines()[0]
    root_tag = "_t382_teeth_root"
    subprocess.run(["git", "-C", PROJ, "tag", "-f", root_tag, root], capture_output=True, text=True)
    try:
        dirty = measure(tag_override=root_tag)
        leg("dirty state reachable (root baseline -> maximal lag)",
            dirty["build_commits"] > 0 and dirty["build_days"] >= FAIL_DAYS,
            "-> commits=%d days=%d" % (dirty["build_commits"], dirty["build_days"]))
        lv2, _ = verdict(dirty)
        leg("dirty state maps to FAIL", lv2 == "fail", "-> %s" % lv2)
        # Monotonicity: an older baseline cannot report LESS lag than a newer one. This
        # is the leg that would catch a gauge wired up backwards — which a single
        # dirty/clean pair would not, since both would still differ.
        leg("older baseline reports >= lag than current baseline",
            dirty["build_days"] >= cur["build_days"] and dirty["build_commits"] >= cur["build_commits"],
            "-> root(%dd,%dc) >= cur(%dd,%dc)" % (dirty["build_days"], dirty["build_commits"],
                                                  cur["build_days"], cur["build_commits"]))
    finally:
        subprocess.run(["git", "-C", PROJ, "tag", "-d", root_tag], capture_output=True, text=True)

    # 3. A missing tag must be UNMEASURED, never ok.
    try:
        measure(tag_override="designer-vNO-SUCH-TAG")
        leg("missing tag refuses to measure", False, "-> returned a result")
    except RuntimeError as e:
        leg("missing tag refuses to measure", "does not exist" in str(e), "-> %s" % str(e)[:56])

    # 4/5. Each escalation must fire ALONE, on a zero-lag input — otherwise it could be
    #      riding on the build-lag number rather than discriminating.
    base = {"sha_ok": True, "peer_pin_readable": True, "build_commits": 0,
            "build_days": 0, "adopt_days": 0, "adopt_behind": None}
    leg("all-clean input -> ok", verdict(dict(base))[0] == "ok", "-> %s" % verdict(dict(base))[0])
    lv3, _ = verdict({**base, "sha_ok": False})
    leg("sha mismatch ALONE -> fail", lv3 == "fail", "-> %s" % lv3)
    lv4, _ = verdict({**base, "peer_pin_readable": False})
    leg("unreadable peer pin ALONE -> not ok", lv4 != "ok", "-> %s" % lv4)
    lv5, _ = verdict({**base, "adopt_behind": "0.1.0 -> 0.8.0", "adopt_days": 99})
    leg("stale peer pin ALONE -> fail", lv5 == "fail", "-> %s" % lv5)

    print("teeth: %d passed, %d failed" % (passed, failed))
    return 0 if failed == 0 else 2


def main():
    if "--teeth" in sys.argv:
        return teeth()
    try:
        res = measure()
    except RuntimeError as e:
        print("=== T-382 / G-024 — release lag ===")
        print("COULD NOT MEASURE: %s" % e)
        print("verdict: UNMEASURED (exit 3) — deliberately not 'ok'")
        return 3
    level, reasons = verdict(res)
    report(res, level, reasons)
    return {"ok": 0, "warn": 1, "fail": 2}[level]


if __name__ == "__main__":
    sys.exit(main())
