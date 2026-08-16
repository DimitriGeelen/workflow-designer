#!/usr/bin/env python3
"""T-552 teeth — a hermeticity check that cannot pass on Mondays isn't checking hermeticity.

`_t525` leg 7 asserts that running the real `fw audit` leaves this repository's audit directory
as it found it. T-533 scoped that to `.context/audits` minus `cron/`, which was right. The
comparand was `git status --porcelain`, which was wrong twice over, and the two wrongs point in
opposite directions:

  * it reads STATUS LETTERS, so a rewrite of an already-dirty file is invisible. Measured
    2026-08-17: appending to `.context/audits/2026-08-16.yaml` moved its digest from
    f42311649879 to 47b2499bdbf7 and left porcelain byte-identical. Both files the audit
    actually writes sit in that state on every run after the first of the day.

  * it reads a CREATE as a violation, and the first audit of any day creates
    `.context/audits/<today>.yaml`. So the leg was guaranteed red once every 24 hours — which
    is how it was found, as the sweep's rc=1 on 2026-08-17 against a standalone 8/8 minutes
    later (OBS-273).

These legs drive `write_set_violations()` over synthetic path->digest maps rather than over the
real tree, because the production path costs ~61 seconds and a real audit run to say one thing
about a pure function, and because the interesting states — midnight rollover, a rewritten
historical record — cannot be summoned on demand in a live repository.

PL-234 requires two arms to prove a scoping is real, and both are kept here: an unrelated
writer must leave the verdict GREEN (leg 5, the T-533 defect staying fixed) and the subject's
own write-set being dirtied must still make it RED (legs 3, 4, 6 — or the invariant has been
narrowed into a decoration, PL-206).

Seam: T552_MODULE points at a copy of the module, so a reconstructed pre-fix comparand can be
shown to turn these legs red without editing the tracked file.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODULE = os.environ.get("T552_MODULE") or os.path.join(ROOT, "tools", "_writeset_hermeticity.py")

TODAY = ".context/audits/2026-08-17.yaml"
TOMORROW = ".context/audits/2026-08-18.yaml"
LATEST = ".context/audits/discoveries/LATEST.yaml"
HISTORICAL = ".context/audits/2026-08-09.yaml"
ELSEWHERE = "src/editor/canvas.js"

ALLOWED = {TODAY, LATEST}

# A settled tree the morning's audit has not touched yet. Digests are arbitrary but must differ
# from the "after" values below, or a leg could pass because nothing was ever varied.
SETTLED = {
    HISTORICAL: "aaaa1111",
    ".context/audits/2026-08-16.yaml": "bbbb2222",
    LATEST: "cccc3333",
}


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def load():
    if not os.path.isfile(MODULE):
        refuse("%s not found — there is no verdict function to drive" % MODULE)
    spec = importlib.util.spec_from_file_location("writeset_hermeticity", MODULE)
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except SystemExit:
        refuse("importing %s ran a main path and exited; nothing below was measured" % MODULE)
    for name in ("write_set_violations", "snapshot", "today_iso", "declared_writes_observed"):
        if not hasattr(mod, name):
            refuse("%s has no %s(); the verdict is no longer computed by a function this probe "
                   "can drive, so its green would be about nothing" % (MODULE, name))
    return mod


def main():
    mod = load()
    failures = []
    passes = 0

    def leg(name, ok, detail=""):
        nonlocal passes
        if ok:
            passes += 1
            print("  PASS  %s" % name)
        else:
            failures.append(name)
            print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))

    v = mod.write_set_violations

    # ── leg 1: the reported defect — first audit of a day ──────────────────────────────────
    first_of_day = v(SETTLED, dict(SETTLED, **{TODAY: "dddd4444", LATEST: "eeee5555"}), ALLOWED)
    leg("1 the first audit of a day is hermetic (today's report may be CREATED)",
        first_of_day == [],
        "verdict was %r. This is OBS-273 verbatim: the audit creates .context/audits/<today>."
        "yaml on the first run of each day, and the old comparand read that creation as a "
        "violation. A hermeticity leg that cannot pass between midnight and the first audit "
        "is not reporting on hermeticity, it is reporting on the clock." % (first_of_day,))

    # ── leg 2: the ordinary case — same two files, rewritten ───────────────────────────────
    later_run = v(dict(SETTLED, **{TODAY: "dddd4444"}),
                  dict(SETTLED, **{TODAY: "ffff6666", LATEST: "eeee5555"}), ALLOWED)
    leg("2 a later audit the same day is hermetic (both declared outputs may be MODIFIED)",
        later_run == [],
        "verdict was %r. The allow-list has to cover modification as well as creation, or the "
        "repair trades a once-a-day red for an every-run red." % (later_run,))

    # ── leg 3: the blindness the old comparand had ─────────────────────────────────────────
    # `.context/audits/2026-08-16.yaml` is already dirty in the working tree, so its status
    # letter never moves. Measured on the real file: f42311649879 -> 47b2499bdbf7, porcelain
    # byte-identical. The whole point of the digest comparand is that this is now visible.
    dirty_rewrite = v(SETTLED, dict(SETTLED, **{".context/audits/2026-08-16.yaml": "9999zzzz"}),
                      ALLOWED)
    leg("3 rewriting an already-dirty file in the write-set is a violation",
        len(dirty_rewrite) == 1 and "2026-08-16" in dirty_rewrite[0],
        "verdict was %r. Under the old comparand this stimulus was GREEN — an already-dirty "
        "file stays ' M' however often it is rewritten, so the assertion was passing on "
        "silence for both of the files the audit actually writes." % (dirty_rewrite,))

    # ── leg 4: an immutable historical record ──────────────────────────────────────────────
    hist = v(SETTLED, dict(SETTLED, **{HISTORICAL: "8888yyyy"}), ALLOWED)
    leg("4 rewriting a HISTORICAL audit is a violation",
        len(hist) == 1 and HISTORICAL in hist[0],
        "verdict was %r. Audit reports are immutable historical records; a run that edits one "
        "is the failure this leg is worth having for, and the old form could only see it when "
        "the file happened to be committed and clean." % (hist,))

    # ── leg 5: PL-234 arm one — an unrelated writer must NOT turn it red ───────────────────
    # This is the T-533 defect. It stays fixed by scope, not by the new comparand, so it has to
    # be re-measured against the new form rather than assumed to have survived the change.
    unrelated = v(SETTLED, dict(SETTLED), ALLOWED)
    outside_snapshot = ELSEWHERE not in SETTLED
    leg("5 a writer OUTSIDE the write-set leaves the verdict green (T-533 stays fixed)",
        unrelated == [] and outside_snapshot,
        "verdict was %r with %s outside the snapshot=%s. The snapshot is scoped to "
        ".context/audits, so a concurrent agent or a handover commit elsewhere in the repo "
        "cannot reach it. If this ever goes red the scoping regressed, and the symptom is a "
        "non-deterministic bridge suite (T-526)." % (unrelated, ELSEWHERE, outside_snapshot))

    # ── leg 6: PL-234 arm two — a stray file inside the write-set IS red ───────────────────
    # Without this, legs 1 and 2 are satisfied by a function that returns [] unconditionally,
    # which is the decoration PL-206 warns about and is strictly worse than the daily red.
    stray = v(SETTLED, dict(SETTLED, **{".context/audits/fabricated-report.yaml": "7777xxxx"}),
              ALLOWED)
    leg("6 a file created inside the write-set but outside the allow-list is a violation",
        len(stray) == 1 and "fabricated-report" in stray[0],
        "verdict was %r. Fabricating a real-looking report into the live audits directory is "
        "the specific accident this file's header warns about; if the allow-list swallowed it, "
        "the repair would have removed the reason leg 7 exists." % (stray,))

    # ── leg 7: a DELETE is never allowed, not even of a declared output ────────────────────
    deleted = v(dict(SETTLED, **{TODAY: "dddd4444"}),
                {k: val for k, val in SETTLED.items()}, ALLOWED)
    leg("7 deleting a declared output is still a violation",
        len(deleted) == 1 and "DELETED" in deleted[0] and TODAY in deleted[0],
        "verdict was %r. Being entitled to WRITE today's report is not being entitled to "
        "remove it, and an allow-list keyed on the path rather than on the operation would "
        "have granted both." % (deleted,))

    # ── leg 8: the midnight straddle the allow-list is doubled for ─────────────────────────
    straddle = v(SETTLED, dict(SETTLED, **{TOMORROW: "6666wwww"}), ALLOWED | {TOMORROW})
    straddle_unallowed = v(SETTLED, dict(SETTLED, **{TOMORROW: "6666wwww"}), ALLOWED)
    leg("8 a run crossing midnight is green ONLY because both dates are allowed",
        straddle == [] and len(straddle_unallowed) == 1,
        "with tomorrow allowed the verdict was %r and without it %r. `_t525` reads the date on "
        "both sides of a ~61s run for this case; if the second reading were dropped the leg "
        "would fail on exactly one run per day, at the one moment nobody is watching. The "
        "second half of this leg is what keeps the doubling from being a blanket 'any date'."
        % (straddle, straddle_unallowed))

    # ── leg 9: a subject that never ran must not read as hermetic ──────────────────────────
    # Hermeticity is a negative claim, and T-524's lesson is that a negative claim is satisfied
    # by silence: an audit that crashed before writing produces an empty violation list, which
    # is indistinguishable from an audit that behaved. `_t525` leg 7 ANDs in this observation.
    obs = mod.declared_writes_observed
    ran = obs(SETTLED, dict(SETTLED, **{TODAY: "dddd4444", LATEST: "eeee5555"}), ALLOWED)
    never_ran = obs(SETTLED, dict(SETTLED), ALLOWED)
    leg("9 a run that wrote NO declared output is distinguishable from one that did",
        ran == sorted([TODAY, LATEST]) and never_ran == [],
        "a real run reported %r and a no-op run reported %r. If the second is non-empty the "
        "guard cannot fire; if the first is empty it fires on every healthy run. Leg 7 of "
        "_t525 is `not breaches AND wrote`, so both halves have to be live." % (ran, never_ran))

    # ── leg 10: anti-vacuity — the function can see 'no difference' ────────────────────────
    identical = v(SETTLED, dict(SETTLED), ALLOWED)
    populated = len(SETTLED) >= 3
    leg("10 identical states over a NON-EMPTY snapshot produce no violations",
        identical == [] and populated,
        "verdict was %r over %d path(s). If the fixture were empty every green above would be "
        "green about nothing — the failure mode T-524 named as a negative assertion satisfied "
        "by silence." % (identical, len(SETTLED)))

    print()
    if failures:
        print("T-552 TEETH: %d/%d legs passed — FAILED: %s"
              % (passes, passes + len(failures), ", ".join(failures)))
        return 1
    print("T-552 TEETH: %d/%d legs passed — the write-set assertion is content-addressed, "
          "passes on the first audit of a day and on a run crossing midnight, still catches a "
          "rewritten historical record, a fabricated report and a deletion, and is still deaf "
          "to writers outside its scope" % (passes, passes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
