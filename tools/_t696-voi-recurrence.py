#!/usr/bin/env python3
"""T-696 — measure the RECURRENCE, not the state.

T-624 measured 38 of 41 inceptions sitting at the template's planted `voi_score`
on 2026-08-29, diagnosed it correctly, and chose an in-template warning as its
prevention. Twelve days later the proportion was unchanged. The warning is
emphatic, correct, and physically adjacent to the field it governs.

    A COMMENT IS NOT A GATE.

The thing T-624 could not do -- because it needed time to pass -- is show that
the number did not move. Doing that by re-reading two prose reports is how the
observation decays into another prose claim. This records the figure with its
date into an append-only ledger, so the next check is a DIFF AGAINST A RECORDED
NUMBER.

What this is NOT: a gate. The prevention has not been chosen yet -- that is the
`[REVIEW]` Human AC on T-696, and it is the operator's ruling (A/B/C/D/no-repair).
Shipping a failing check here would be choosing the prevention by installing it,
which is T-624's error run in reverse: asserting a prevention before anyone picked
one. `--require-improvement` exists for whoever wires it up AFTER the ruling, and
is deliberately not referenced by this task's own Verification block.

────────────────────────────────────────────────────────────────────────────────
2026-09-26 — THE PREVENTION WAS CHOSEN, AND IT MOVED THE GOALPOSTS UNDER THIS FILE
────────────────────────────────────────────────────────────────────────────────

The paragraph above is now historical. The operator ruled (T-865, verbatim: rank
everything automatically, take the human out, "but if I want to override it then
it should not be overwritten by an automatic ranking"), and the repair shipped by
a route none of A/B/C/D described: voi_score and target_blast_radius are now
ESTIMATED from the task's own text, the template pre-fill was deleted, and a
`<field>_source: human` flag makes a deliberate override sticky.

THE RECURRENCE METRIC ABOVE IS THEREFORE SUPERSEDED, AND READING IT NOW MISLEADS.
It counts tasks whose FRONTMATTER carries the template default. After T-865 that
value is ignored at score time unless it carries `source: human`, so the count
measures a property that no longer determines anything. Measured the day the
prevention landed: 43/45, 96% -- UP from 93%, while the defect it was built to
track had been structurally removed hours earlier.

That is a false RED, and it is not the harmless direction. A check that reports a
problem which no longer exists trains its readers to ignore it, and it will still
be there, still red, when a real regression arrives (OBS-293). A probe whose
subject moved does not go quiet; it starts misinforming (PL-332).

The ledger is append-only and is NOT rewritten: those datapoints were true when
recorded and are the evidence that T-624's warning failed. The series is closed,
not falsified. `--prevention-check` below is its successor and watches what the
chosen prevention actually depends on.

WHAT THE NEW CHECK WATCHES, and why these two things:
  1. The template must not re-acquire a pre-filled voi_score / target_blast_radius.
     Deleting that default IS the gate; if it comes back, the collision comes back.
  2. Estimated VoI across active inceptions must span more than one distinct value.
     This is the failure mode that survived the repair and that I hit TWICE in one
     day: a scorer keyed on a phrase the template supplies scores every inception
     identically, produces confident numbers, passes validation, and ranks nothing.
     Uniformity is the signature, so uniformity is what gets watched.

Usage:
    python3 tools/_t696-voi-recurrence.py                    # diff against last record
    python3 tools/_t696-voi-recurrence.py --record           # append a dated datapoint
    python3 tools/_t696-voi-recurrence.py --prevention-check # the live guard (T-865)
    python3 tools/_t696-voi-recurrence.py --self-test        # throwaway root, no real ledger
"""

import argparse
import datetime
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROVENANCE = os.path.join(ROOT, "tools", "_t624-voi-provenance.py")
LEDGER = os.path.join(ROOT, ".context", "audits", "t696-voi-recurrence.jsonl")

FIELDS = ("voi_score", "target_blast_radius")


def measure():
    """Current figures, from T-624's tool -- one source of truth, not a re-implementation."""
    out = subprocess.run(
        [sys.executable, PROVENANCE, "--json"],
        capture_output=True, text=True, cwd=ROOT,
    )
    if out.returncode != 0:
        raise RuntimeError(f"provenance tool failed rc={out.returncode}: {out.stderr[:300]}")
    return json.loads(out.stdout)


def _ratio(entry):
    total = entry["total"]
    return (entry["template_default_count"] / total) if total else 0.0


def read_ledger(path):
    if not os.path.exists(path):
        return []
    rows = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def record(path, data, today=None):
    """Append one dated datapoint. Append-only: never rewrites prior lines."""
    today = today or datetime.date.today().isoformat()
    row = {"date": today, "fields": data}
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a") as fh:
        fh.write(json.dumps(row, sort_keys=True) + "\n")
    return row


def diff(path, data, require_improvement=False):
    """Report the delta since the last recorded datapoint. Returns an exit code."""
    rows = read_ledger(path)
    print("T-696 — voi_score / target_blast_radius recurrence")
    print("=" * 66)

    if not rows:
        print("\nNo prior datapoint in the ledger.")
        print(f"  ledger: {path}")
        for f in FIELDS:
            e = data[f]
            print(f"  {f:22s} {e['template_default_count']}/{e['total']} at template default "
                  f"({_ratio(e):.0%})")
        print("\nRun with --record to establish the baseline. Nothing to diff yet, and\n"
              "saying 'unchanged' with nothing to compare against would be the prose\n"
              "claim this tool exists to replace.")
        return 0

    prev = rows[-1]
    print(f"\n  last recorded: {prev['date']}   ({len(rows)} datapoint(s) in ledger)")
    print(f"  ledger: {path}\n")

    worsened = False
    for f in FIELDS:
        now, was = data[f], prev["fields"][f]
        d_count = now["template_default_count"] - was["template_default_count"]
        d_ratio = _ratio(now) - _ratio(was)
        arrow = "unchanged" if d_count == 0 else (f"{d_count:+d}")
        print(f"  {f:22s} {was['template_default_count']}/{was['total']} "
              f"({_ratio(was):.0%})  ->  {now['template_default_count']}/{now['total']} "
              f"({_ratio(now):.0%})   [{arrow}]")
        if d_ratio > 0.001:
            worsened = True

    try:
        d0 = datetime.date.fromisoformat(prev["date"])
        days = (datetime.date.today() - d0).days
        print(f"\n  elapsed since last datapoint: {days} day(s)")
    except ValueError:
        days = None

    if require_improvement:
        stalled = all(
            data[f]["template_default_count"] >= prev["fields"][f]["template_default_count"]
            for f in FIELDS
        )
        if stalled:
            print("\nFAIL (--require-improvement): the proportion has not fallen since the\n"
                  "last datapoint. Whatever prevention is in place has not refused anything.")
            return 1

    print("\nThis is an INSTRUMENT, not a gate. The prevention is T-696's open [REVIEW]\n"
          "ruling (A/B/C/D/no-repair). Wire --require-improvement in only after that is\n"
          "decided — installing a failing check now would BE the decision.")
    return 1 if (worsened and require_improvement) else 0


INCEPTION_TEMPLATE = os.path.join(ROOT, ".tasks", "templates", "inception.md")


def prevention_check(template_path=None, voi_values=None):
    """The live guard for the prevention chosen in T-865. Returns (ok, findings).

    Both arguments are injectable so the self-test can drive the FAILING cases
    without touching the corpus — "watched failing before it is relied on" is
    T-696's own acceptance criterion, and a guard only ever seen passing is
    exactly the artefact T-624 shipped.
    """
    findings = []

    # 1. The deleted default must stay deleted. That deletion IS the gate.
    tpl = template_path or INCEPTION_TEMPLATE
    try:
        with open(tpl, encoding="utf-8") as fh:
            lines = [ln for ln in fh.read().splitlines()
                     if not ln.lstrip().startswith("#")]
        for field in FIELDS:
            if any(ln.startswith(f"{field}:") for ln in lines):
                findings.append(
                    f"{tpl} pre-fills {field!r} again — the collision it caused "
                    f"returns with it (an absent value and the default both score 2)")
    except OSError as exc:
        findings.append(f"cannot read inception template {tpl}: {exc}")

    # 2. Estimated VoI must differentiate. Uniformity is the signature failure.
    vals = voi_values if voi_values is not None else _live_voi_values()
    if vals is None:
        findings.append("could not evaluate inception VoI — guard NOT EVALUATED, "
                        "which is not the same as passing (T-3105)")
    elif len(vals) < 2:
        findings.append(f"only {len(vals)} inception(s) found — too few to judge "
                        f"differentiation; NOT EVALUATED rather than passed")
    else:
        distinct = sorted(set(vals))
        if len(distinct) < 2:
            findings.append(
                f"all {len(vals)} inceptions estimate to the SAME VoI ({distinct[0]}) — "
                f"the scorer is keyed on something every inception carries (template "
                f"boilerplate is the usual cause) and is ranking nothing")
    return (not findings), findings


def _live_voi_values():
    """Estimated VoI for every active inception, or None if unavailable."""
    try:
        import glob as _glob
        import importlib.util
        from pathlib import Path
        est = os.path.join(ROOT, ".agentic-framework", "agents", "termlink",
                           "bvp-estimator", "estimator.py")
        spec = importlib.util.spec_from_file_location("_t696est", est)
        mod = importlib.util.module_from_spec(spec)
        sys.modules["_t696est"] = mod
        spec.loader.exec_module(mod)
        out = []
        for f in sorted(_glob.glob(os.path.join(ROOT, ".tasks", "active", "*.md"))):
            fm, body = mod.parse_task(Path(f))
            if (fm.get("workflow_type") or "").lower() != "inception":
                continue
            v, _ = mod._estimate_voi(fm, body, list(fm.get("tags") or []))
            out.append(v)
        return out
    except Exception:
        return None


def self_test():
    """Runs entirely in a throwaway root. Never touches the real ledger."""
    print("T-696 recurrence — self-test (throwaway ledger root)")
    print("=" * 66)
    failures = []

    tmp = tempfile.mkdtemp()
    led = os.path.join(tmp, "audits", "t696.jsonl")

    def mk(n, total=43):
        return {f: {"template_default": "0.5", "total": total,
                    "scored": total - n, "template_default_count": n, "absent": 0}
                for f in FIELDS}

    # 1. empty ledger is not an error, and does not claim "unchanged"
    rc = diff(led, mk(40))
    if rc != 0:
        failures.append("empty ledger should exit 0")
    if read_ledger(led):
        failures.append("diff must not write to the ledger")

    # 2. record appends, and appends WITHOUT rewriting
    record(led, mk(40), today="2026-08-29")
    record(led, mk(40), today="2026-09-10")
    rows = read_ledger(led)
    if len(rows) != 2:
        failures.append(f"expected 2 ledger rows, got {len(rows)}")
    if rows[0]["date"] != "2026-08-29":
        failures.append("append-only violated: first row changed")

    # 3. the real recurrence shape -- unchanged over time -- is reported, not hidden
    rc = diff(led, mk(40))
    if rc != 0:
        failures.append("unchanged should exit 0 without --require-improvement")

    # 4. --require-improvement DOES fail on a stall (the gate is real when wired)
    rc = diff(led, mk(40), require_improvement=True)
    if rc != 1:
        failures.append("--require-improvement must fail on a stalled figure")

    # 5. ... and passes when the figure actually falls
    rc = diff(led, mk(12), require_improvement=True)
    if rc != 0:
        failures.append("--require-improvement must pass when the figure falls")

    # 6. a WORSENING figure must not read as improvement
    rc = diff(led, mk(43), require_improvement=True)
    if rc != 1:
        failures.append("--require-improvement must fail when the figure worsens")

    # ── T-865 prevention guard: WATCHED FAILING, which is T-696's own AC ────────
    # A guard only ever seen passing is the artefact T-624 shipped. Each case
    # below drives a real failure through injected inputs; the corpus is never
    # touched.
    good_tpl = os.path.join(tmp, "tpl-ok.md")
    with open(good_tpl, "w", encoding="utf-8") as fh:
        fh.write("---\n# voi_score: 0.5   <- commented out, must NOT count\n"
                 "id: T-X\n---\nbody\n")
    bad_tpl = os.path.join(tmp, "tpl-bad.md")
    with open(bad_tpl, "w", encoding="utf-8") as fh:
        fh.write("---\nid: T-X\nvoi_score: 0.5\n---\nbody\n")

    # 7. FAILS when the template re-acquires a pre-fill
    ok, finds = prevention_check(template_path=bad_tpl, voi_values=[0.2, 0.6])
    if ok or not any("pre-fills" in f for f in finds):
        failures.append("prevention_check passed a template that re-added the default")

    # 8. FAILS when every inception estimates to the same value
    ok, finds = prevention_check(template_path=good_tpl, voi_values=[0.6] * 14)
    if ok or not any("SAME VoI" in f for f in finds):
        failures.append("prevention_check passed a scorer with zero variance — "
                        "the exact failure that shipped twice on 2026-09-26")

    # 9. ABSTAINS rather than passes when there is nothing to judge
    ok, finds = prevention_check(template_path=good_tpl, voi_values=[])
    if ok or not any("NOT EVALUATED" in f for f in finds):
        failures.append("prevention_check reported PASS on an empty candidate set")

    # 10. PASSES on a healthy shape — without this the three above could be
    #     satisfied by a check that simply always fails.
    ok, finds = prevention_check(template_path=good_tpl, voi_values=[0.2, 0.4, 0.8])
    if not ok:
        failures.append(f"prevention_check failed a healthy shape: {finds}")

    print("\n" + "=" * 66)
    for f in failures:
        print(f"  FAIL: {f}")
    if failures:
        print(f"\nVERDICT: RED — {len(failures)} of 10 checks failed.")
        return 1
    print("\nVERDICT: GREEN — 10/10 checks passed, real ledger untouched.")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--record", action="store_true",
                    help="append a dated datapoint to the append-only ledger")
    ap.add_argument("--require-improvement", action="store_true",
                    help="exit non-zero if the proportion has not fallen since the last "
                         "datapoint. NOT wired into T-696's Verification: the prevention "
                         "has not been chosen yet, and installing a failing check would "
                         "be choosing it.")
    ap.add_argument("--prevention-check", action="store_true",
                    help="the live guard for the prevention chosen in T-865: the "
                         "inception template must not re-acquire a pre-filled "
                         "voi_score/target_blast_radius, and estimated VoI must span "
                         "more than one value. Exits non-zero on either.")
    ap.add_argument("--ledger", default=LEDGER)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    if args.prevention_check:
        ok, finds = prevention_check()
        if ok:
            print("T-696 prevention guard: GREEN — template carries no pre-fill, "
                  "and inception VoI estimates differentiate.")
            return 0
        print("T-696 prevention guard: RED")
        for f in finds:
            print(f"  - {f}")
        return 1

    data = measure()
    if args.record:
        row = record(args.ledger, data)
        print(f"recorded {row['date']} -> {args.ledger}")
        for f in FIELDS:
            e = data[f]
            print(f"  {f:22s} {e['template_default_count']}/{e['total']} at template default")
        return 0
    return diff(args.ledger, data, require_improvement=args.require_improvement)


if __name__ == "__main__":
    sys.exit(main())
