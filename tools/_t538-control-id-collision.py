#!/usr/bin/env python3
"""T-538 teeth — a control id in audit.sh must map to exactly ONE control.

`audit.sh` defines two different controls under the id CTL-029:

    audit.sh:3639  T-1903/L-403  oe-daily only          status == work-completed, 0 unchecked ACs
                                                        -> remedy: bin/fw task archive-eligible
    audit.sh:3772  T-2055        compliance || oe-daily status in (started-work, issues), Agent ACs ticked
                                                        -> remedy: bin/fw task update --status work-completed

Their status predicates are disjoint, so neither control is wrong about any single
task. The defect is in the REGISTER, not the logic: the id is a key — operators scan
for it, `.context/audits/*.yaml` records it, gap closure_check_commands grep it, the
T-535 trend aggregator protects it as an identifier token — and it does not resolve to
one thing. One real `--section oe-daily` run emits 21 lines labelled CTL-029 from both
controls, carrying two different remedies.

THE DISCRIMINATOR IS INTERLEAVING, NOT DISTANCE
    Nine other ids emit several `pass` lines each, because a control's if/elif/else arms
    each announce their own clean verdict. Those are ONE control. The obvious separator —
    "pass sites more than N lines apart" — needs a threshold nobody can justify, and the
    threshold is what would rot. This uses a structural test instead: walk every emission
    site in file order and split them into maximal runs of the same id. An id with two or
    more runs has ANOTHER control's emissions between its own, which no single
    if/elif/else chain can produce. Threshold-free, and it reports the runs so a reader
    can disagree with the verdict rather than trust it.

WHAT THIS CANNOT DO (PL-034, surfaced by the knowledge lookup when this task was filed)
    This is an INTERNAL SELF-CONSISTENCY check over one file. It can prove the ids in
    audit.sh are distinct from each other. It cannot prove an id still means to a reader
    what it meant when a report was written, and it cannot see a collision with a control
    defined somewhere else entirely. It closes the class it can see, and that limit is
    stated here rather than left for someone to discover from a green run.

RATCHET DIRECTION IS DELIBERATELY ASYMMETRIC
    A NEW collision is red. A baselined collision that has been RESOLVED prints loudly and
    exits 0. A guard that goes red when someone fixes the defect teaches people not to fix
    it, and the fix here is not ours to make unilaterally — the id namespace belongs to
    AEF upstream.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIT = os.path.join(ROOT, ".agentic-framework", "agents", "audit", "audit.sh")

# Pinned by IDENTITY, not by count (G-015). Value is the number of distinct runs observed
# when this baseline was taken, so a THIRD block under the same id is still caught.
BASELINE = {"CTL-029": 2}

EMIT = re.compile(r'^\s*(pass|warn|fail)\s+"(CTL-\d+)')

# A parse yielding fewer sites than this means the emission grammar moved and every leg
# below would be asserting over an empty set.
MIN_SITES = 20


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_sites(path):
    """[(lineno, kind, cid)] in file order."""
    out = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for i, line in enumerate(fh, 1):
            m = EMIT.match(line)
            if m:
                out.append((i, m.group(1), m.group(2)))
    return out


def runs_by_id(sites):
    """id -> [(first_line, last_line), ...] maximal runs in emission order."""
    runs = {}
    prev = None
    for lineno, _kind, cid in sites:
        if cid != prev:
            runs.setdefault(cid, []).append([lineno, lineno])
        else:
            runs[cid][-1][1] = lineno
        prev = cid
    return {k: [tuple(r) for r in v] for k, v in runs.items()}


def collisions(sites):
    return {cid: rs for cid, rs in runs_by_id(sites).items() if len(rs) >= 2}


def multi_pass_single_run(sites):
    """ids emitting 2+ `pass` lines yet forming ONE run — the look-alikes leg 2 protects."""
    rb = runs_by_id(sites)
    npass = {}
    for _l, kind, cid in sites:
        if kind == "pass":
            npass[cid] = npass.get(cid, 0) + 1
    return sorted(c for c, n in npass.items() if n >= 2 and len(rb.get(c, [])) == 1)


def mutate_plant(src, dst, sites):
    """Insert a synthetic emission for an id that already has a run elsewhere.

    Planted near the TOP of the emission region, never appended at EOF: if the chosen id
    happened to be the last emitter in the file, an appended line would be contiguous with
    its existing run and the leg would pass for the wrong reason (PL-206 — a control that
    can fail is worthless if the stimulus was built so it never would).
    """
    rb = runs_by_id(sites)
    victim = None
    for cid, rs in sorted(rb.items()):
        if len(rs) == 1 and rs[0][0] > sites[0][0]:
            victim = cid
            break
    if victim is None:
        return None
    anchor = sites[0][0]  # first emission in the file; victim's run is strictly after it
    lines = open(src, encoding="utf-8", errors="replace").read().splitlines(True)
    lines.insert(anchor, '    pass "%s: synthetic planted by the T-538 mutation leg"\n' % victim)
    open(dst, "w", encoding="utf-8").write("".join(lines))
    return victim


def mutate_fix(src, dst, sites, cid, new_id):
    """Apply the PROPOSED remedy in a copy: renumber the SECOND run of `cid` to `new_id`.

    This leg doubles as a check that the remedy actually works — it is the same edit a
    human would make upstream, executed against a throwaway copy.
    """
    rs = runs_by_id(sites)[cid]
    lo, hi = rs[1]
    lines = open(src, encoding="utf-8", errors="replace").read().splitlines(True)
    for idx in range(lo - 1, hi):
        lines[idx] = lines[idx].replace('"%s:' % cid, '"%s:' % new_id)
    open(dst, "w", encoding="utf-8").write("".join(lines))


def main():
    if not os.path.isfile(AUDIT):
        refuse("audit.sh not found at %s" % AUDIT)

    before = sha256(AUDIT)
    sites = parse_sites(AUDIT)
    if len(sites) < MIN_SITES:
        refuse("parsed only %d emission site(s) from audit.sh (expected >= %d) — the "
               "pass/warn/fail grammar moved and every leg would assert over an empty set"
               % (len(sites), MIN_SITES))

    found = collisions(sites)
    lookalikes = multi_pass_single_run(sites)
    failures = []
    notices = []

    # Leg 1 — the known collision is seen on the real file.
    if "CTL-029" not in found:
        notices.append("CTL-029 no longer collides — if it was renumbered upstream, drop it "
                       "from BASELINE in this file and the leg-4 remedy check becomes moot")
    else:
        rs = found["CTL-029"]
        if len(rs) < 2:
            failures.append("leg1: CTL-029 reported with %d run(s)" % len(rs))

    # Leg 2 — anti-vacuity on the DISCRIMINATOR. Ids that emit several `pass` lines from
    # adjacent if/elif arms must not be flagged. If this set were empty the discriminator
    # would never have been exercised and leg 1 could be passing on "flag everything".
    if not lookalikes:
        refuse("no multi-pass single-run control found — the look-alike population that "
               "separates 'several arms of one control' from 'two controls' is empty, so "
               "leg 1 proves nothing")
    for cid in lookalikes:
        if cid in found:
            failures.append("leg2: %s emits several pass lines from one contiguous run and "
                            "was flagged as a collision" % cid)

    # Legs 3 and 4 — mutation. Both run against COPIES; the real file is never written.
    sandbox = tempfile.mkdtemp(prefix="t538-collide-")
    try:
        planted_path = os.path.join(sandbox, "planted.sh")
        victim = mutate_plant(AUDIT, planted_path, sites)
        if victim is None:
            refuse("could not select a single-run id to plant a synthetic collision on")
        pl = collisions(parse_sites(planted_path))
        if victim not in pl:
            failures.append("leg3: planted a second %s block into a copy and the detector did "
                            "not report it — the detector cannot see a collision" % victim)

        if "CTL-029" in found:
            fixed_path = os.path.join(sandbox, "fixed.sh")
            mutate_fix(AUDIT, fixed_path, sites, "CTL-029", "CTL-031")
            fx = collisions(parse_sites(fixed_path))
            if "CTL-029" in fx:
                failures.append("leg4: applied the proposed remedy (second run -> CTL-031) in a "
                                "copy and CTL-029 still reports as collided — the verdict is not "
                                "being read from the file's structure")
            if "CTL-031" in fx:
                failures.append("leg4: the remedy introduced a NEW collision on CTL-031")
    finally:
        shutil.rmtree(sandbox, ignore_errors=True)

    # Leg 5 — the ratchet. New collisions are red; resolved ones are a loud notice.
    for cid, rs in sorted(found.items()):
        if cid not in BASELINE:
            failures.append("leg5: NEW control-id collision %s — %d separate runs at %s; two "
                            "controls are sharing one id" % (cid, len(rs), rs))
        elif len(rs) > BASELINE[cid]:
            failures.append("leg5: %s grew from %d baselined run(s) to %d"
                            % (cid, BASELINE[cid], len(rs)))
    for cid in sorted(BASELINE):
        if cid not in found:
            notices.append("baselined collision %s is RESOLVED — remove it from BASELINE" % cid)

    # Leg 6 — the real file was not written by any of the above.
    after = sha256(AUDIT)
    if before != after:
        failures.append("leg6: audit.sh changed during the run (%s -> %s); the mutation legs "
                        "must operate on copies only" % (before[:12], after[:12]))

    print("T-538 control-id collision teeth — %d emission site(s), %d id(s), "
          "%d look-alike(s) held clean" % (len(sites), len(runs_by_id(sites)), len(lookalikes)))
    for cid, rs in sorted(found.items()):
        print("    COLLISION %s: %d runs at %s" % (cid, len(rs), rs))
    print("    look-alikes (several pass arms, one run): %s" % ", ".join(lookalikes))
    for n in notices:
        print("    NOTICE: %s" % n)

    legs = 6
    if failures:
        print("\n%d/%d legs FAILED:" % (len(failures), legs))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\n%d/%d legs green" % (legs, legs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
