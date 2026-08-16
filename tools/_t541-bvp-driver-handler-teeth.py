#!/usr/bin/env python3
"""T-541 teeth — the three product BVP drivers must actually discriminate.

T-540 measured that a BVP driver with no dedicated handler falls through to
`score_free_driver`, which substring-matches the driver's OWN ID in the task
body: 0 of 55 non-inception tasks scored non-zero. A driver that scores nothing
ranks nothing, and it fails silently — `fw bvp` prints a column of zeros with
the same confidence it prints real scores.

T-541 wrote `score_v_workflow_routing`, `score_v_aef_integration` and
`score_v_sdlc_enablement`. This probe defends the three properties that make
them worth having, none of which a green `fw bvp` run would reveal:

  1. WIRED    — the dispatch table routes the canonical name to the handler.
                Checked behaviourally, not by introspection: the fallback emits
                a recognisable "no '<id>' mention" evidence string, so if the
                wiring is lost the probe sees the fallback's own fingerprint.
  2. ALIVE    — each fires on at least one real task (not dead).
  3. SELECTIVE— each stays silent on at least one real task (not vacuous). A
                driver that fires on everything sorts nothing.
  4. GRADED   — each returns at least three distinct non-zero levels. Guards the
                D1 shape measured in T-540: the heaviest driver in the model
                takes exactly two values across the whole corpus, so its weight
                buys a binary flag.
  5. NO DEAD LEVELS — every rubric level a handler claims must be returnable.
                One fixture per level. The first cut of the routing handler
                listed `port-indicator` as a level-2 trigger but omitted "port"
                from its entry gate, so T-294 scored 0 and level 2 could never
                be returned by any input. Same class as PL-203.
  6. BOILERPLATE-BLIND — scoring the template comment text ALONE must return 0.
                `parse_task` does not strip HTML comments and a task file here
                is 33.6% comment on average; `score_d3_usability` already scores
                37 of 58 tasks off that boilerplate alone. These three must not
                join it.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import glob
import hashlib
import importlib.util
import os
import re
import sys
from pathlib import Path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EST = os.path.join(ROOT, ".agentic-framework", "agents", "termlink", "bvp-estimator", "estimator.py")

# Minimum corpus size below which every leg would be asserting over noise.
MIN_TASKS = 20

# One fixture per rubric level per driver.
#
# EVERY LEVEL>=2 FIXTURE IS DELIBERATELY FREE OF THE DRIVER'S INCIDENTAL (GATE)
# VOCABULARY, and that constraint is the whole point of this table.
#
# The first version of these fixtures did not respect it — the level-2 routing
# fixture read "Edge arrowheads render above node-id badges...", and "Edge" is
# itself an incidental gate word. Mutation-tested against a copy whose entry gate
# was deliberately un-derived from the ladder (reintroducing the exact T-294 bug
# this leg exists to catch): the mutant scored all six fixtures correctly and the
# leg stayed GREEN. The control could not fail, because every fixture entered
# through a gate word instead of through its own level trigger. PL-206.
#
# So each fixture below reaches its level ONLY via that level's own patterns. If
# the gate stops being the union of the ladder, these fixtures fall to 0 and the
# leg goes red — which is now verified by mutation, not asserted.
# The level-1 fixture is the exception by construction: it must match ONLY
# incidental vocabulary, since that is what level 1 means.
FIXTURES = {
    "V_WORKFLOW_ROUTING": [
        (5, "Retire aef:position as the stored coordinate attribute."),
        (4, "Emit BPMN DI additively alongside the existing attributes."),
        (3, "The importer silently reassigns the owner when the reference will not resolve."),
        (2, "Port-indicator pin click does not register on mousedown."),
        (1, "Touches the lane rendering incidentally while fixing something else."),
        (0, "Rewrite the audit trend aggregator to key on the issue rather than the sentence."),
    ],
    "V_AEF_INTEGRATION": [
        (5, "Ratify the process-level conformance key for the shared standard."),
        (4, "The vendor bump is available and the peer pin needs refreshing."),
        (3, "Reverse discovery from the AEF record back to an editable document."),
        (2, "Retire the aef:position attribute from the emitted document."),
        (1, "Mentions the seam in passing while fixing an unrelated hook."),
        (0, "Rename a local helper in the rendering module."),
    ],
    "V_SDLC_ENABLEMENT": [
        (5, "Workflow Fabric: a process-dependency graph so callActivity composes them."),
        (4, "Document workflow 'review-map' plus guided-mode procedural guardrail."),
        (3, "Ratify stateKind conformance for the emitted documents."),
        (2, "Create from pending so the off-page claim can be saved."),
        (1, "The validator is mentioned once as background."),
        (0, "Adjust an arrowhead z-index in the renderer."),
    ],
}

DRIVERS = list(FIXTURES)
FALLBACK_FINGERPRINT = re.compile(r"no '.*' mention")


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_estimator():
    spec = importlib.util.spec_from_file_location("aef_bvp_estimator", EST)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def non_completed_tasks():
    import yaml
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, ".tasks", "active", "T-*.md"))):
        txt = open(p, encoding="utf-8").read()
        if not txt.startswith("---"):
            continue
        try:
            fm = yaml.safe_load(txt.split("---", 2)[1]) or {}
        except Exception:
            continue
        if fm.get("status") == "work-completed":
            continue
        if (fm.get("workflow_type") or "").lower() == "inception":
            continue  # routed to _score_inception_voi, never reaches these handlers
        out.append(p)
    return out


def main():
    if not os.path.isfile(EST):
        refuse("estimator not found at %s" % EST)

    before = sha256(EST)
    mod = load_estimator()

    handlers = {}
    for d in DRIVERS:
        fn = getattr(mod, "score_" + d.lower(), None)
        if fn is None:
            refuse("%s has no score_%s — the handler this probe defends does not exist"
                   % (d, d.lower()))
        handlers[d] = fn

    paths = non_completed_tasks()
    if len(paths) < MIN_TASKS:
        refuse("only %d non-completed non-inception task(s) (need >= %d) — every leg below "
               "would assert over noise" % (len(paths), MIN_TASKS))

    failures = []
    report = []

    # ── Leg 1 — WIRED. estimate_task must route the canonical name to the real
    #    handler, not to the score_free_driver fallback. Detected by the
    #    fallback's own evidence fingerprint rather than by reading the table.
    probe_task = Path(paths[0])
    res = mod.estimate_task(probe_task, {d: 9 for d in DRIVERS})
    for d in DRIVERS:
        ev = " ".join(res["evidence"].get(d) or [])
        if FALLBACK_FINGERPRINT.search(ev):
            failures.append("leg1 %s: estimate_task fell through to score_free_driver "
                            "(evidence %r) — the dispatch-table entry is gone, and the driver "
                            "silently scores ~0 on every build task" % (d, ev))

    # ── Legs 2/3/4 — ALIVE, SELECTIVE, GRADED, measured on the real corpus.
    for d in DRIVERS:
        levels = []
        for p in paths:
            fm, body = mod.parse_task(Path(p))
            sc, _ev = handlers[d](fm, body, list(fm.get("tags") or []))
            levels.append(sc)
        nz = sum(1 for v in levels if v)
        distinct_nz = sorted(set(v for v in levels if v))
        report.append((d, nz, len(paths), distinct_nz))
        if nz == 0:
            failures.append("leg2 %s: DEAD — fires on 0 of %d tasks" % (d, len(paths)))
        if nz == len(paths):
            failures.append("leg3 %s: VACUOUS — fires on all %d tasks, so it cannot sort them"
                            % (d, len(paths)))
        if len(distinct_nz) < 3:
            failures.append("leg4 %s: only %d distinct non-zero level(s) %s — this is the D1 "
                            "shape (weight 9 buying a binary flag)" % (d, len(distinct_nz), distinct_nz))

    # ── Leg 5 — NO DEAD LEVELS. Every level the rubric claims must be returnable.
    for d, fixtures in FIXTURES.items():
        for expected, text in fixtures:
            got, ev = handlers[d]({}, text, [])
            if got != expected:
                failures.append("leg5 %s: fixture for level %d scored %d instead (%s). Either the "
                                "level is unreachable — its trigger is missing from the entry gate, "
                                "the PL-203 shape — or the ladder order lets a broader level win "
                                "first. Fixture: %r" % (d, expected, got, ev[-1] if ev else "", text[:70]))

    # ── Leg 6 — BOILERPLATE-BLIND. The template comment text alone must score 0.
    raw = open(paths[0], encoding="utf-8").read()
    comments = "\n".join(re.findall(r"<!--.*?-->", raw, re.S))
    if not comments.strip():
        refuse("first corpus task carries no HTML comment block — the boilerplate-contamination "
               "leg would pass vacuously")
    for d in DRIVERS:
        sc, ev = handlers[d]({}, comments, [])
        if sc != 0:
            failures.append("leg6 %s: scored %d on template boilerplate ALONE (%s) — it is "
                            "scoring the task template rather than the task, the way "
                            "score_d3_usability does on 37 of 58 tasks" % (d, sc, ev[-1] if ev else ""))

    # ── Leg 7 — the probe never writes the file it reads.
    after = sha256(EST)
    if before != after:
        failures.append("leg7: estimator.py changed during the run (%s -> %s)"
                        % (before[:12], after[:12]))

    print("T-541 BVP product-driver handler teeth — %d non-completed, non-inception task(s)"
          % len(paths))
    for d, nz, n, distinct in report:
        print("    %-20s fires on %2d/%-2d (%3.0f%%)   non-zero levels reached: %s"
              % (d, nz, n, 100.0 * nz / n, distinct))
    print("    %d level fixture(s) across %d driver(s); boilerplate-only must score 0"
          % (sum(len(v) for v in FIXTURES.values()), len(DRIVERS)))

    if failures:
        print("\n%d finding(s):" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\nall legs green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
