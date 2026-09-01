#!/usr/bin/env python3
"""_t364-t308-teeth.py — prove _t308's `unusable` bucket can actually FILL.

G-023's prevention added a self-stability check to the byte-identity gate: a document
that is not byte-stable with itself is reported `unusable` rather than counted
`identical`. The first run came back `unusable: 0` — which is exactly what a check
that cannot fire also reports. A bucket whose count is the finding has to be shown
fillable before its emptiness means anything.

---- WHY THIS FILE WAS REWRITTEN (T-663, 2026-09-01) ----

The previous version pinned `REF = "3bf37909~1"` and asserted that the 24 designer maps
emit byte-identical output between that build and the tree. It had been dead for weeks:

  control : rc=1 maps=24 identical=0 drifted=24 unusable=0
  TEETH BROKEN — the control corpus does not pass, so nothing below proves anything.

Not a regression. **22 commits deliberately changed the emitter since that baseline**
(T-602 documentation now survives, T-603 multi-process no longer dropped, T-618
determinism/sideEffect surfacing, ...), while the corpus SOURCE was untouched — zero
commits. So the maps legitimately emit ~40% more bytes than they did on 2026-08-04, and
a control asserting cross-build byte-identity could not have survived this arc's own
repair work. It died the first time we fixed an import loss, and nothing noticed,
because a teeth file that reports "TEETH BROKEN" is only loud if somebody runs it.

The old docstring predicted a version of this and prescribed the fix: "a NEW injection
that is genuinely unstable in both builds (a document with a nondeterministic emitted
field, whatever the next one turns out to be)". **That prescription is no longer
satisfiable, and the reason is good news.** After T-364 the parse->build path has no
remaining nondeterminism at all: `aef:uid` derives from the element id, and a grep for
`Math.random`/`Date.now`/`crypto.randomUUID` between `buildBpmnXml` and the parser finds
only the comment describing the defect that was fixed. No real document can be unstable
here any more.

The one live mint — `workflowMeta.uuid` at `adoptImportedXml` (src ~9641), which IS
emitted (src ~10199) — sits on the **open wrapper**, and this gate calls
`parseBpmnXml -> buildBpmnXml` directly. So it is invisible to _t308 by construction.
Worth knowing and NOT the injection: measured, `simple.bpmn` (no `aef:workflowMeta`) is
self-stable under this gate precisely because the gate never reaches the mint.

So the instability now has to come from a BUILD, not a document. `_t308` grew a
`T308_OLD_SRC` override (T-663) with the same shape and purpose as the `T308_CORPUS`
override T-364 added for exactly this reason. A run using it declares itself in the
result (`srcOverride`, and `ref` reads `T308_OLD_SRC:<path>`), so it can never be quoted
as a real gate result.

---- WHAT THIS FILE ASSERTS ----

  control   temp corpus, real tree build, no override
            -> ok=true, unusable=0, drifted=0, identical=N
            No pinned ref anywhere: this is a self-comparison of one build, so it
            cannot rot the way the old control did when the emitter legitimately moves.

  fills     same corpus, OLD side = tree build mutated to emit a random suffix
            -> ok=FALSE, unusable=N, identical=0
            The load-bearing assertion is `identical == 0` as much as `unusable == N`:
            the two failure modes G-023 was registered for are counting an unmeasurable
            document as identical, and dropping it from every bucket so the denominator
            quietly shrinks. `maps` is asserted on both runs for the same reason.

  teeth     _t308 itself mutated so the unusable branch cannot fire, same mutant build
            -> the unstable documents must reappear as `drifted`, NOT as `identical`,
            and `unusable` must be 0. Proves the `fills` result comes from the
            detection branch and not from something incidental (PL-208: assert the
            control went red FOR ITS STATED REASON, not merely that it went red).

Nothing in this file touches the real corpus or the real tree: both mutations are
written to temp copies.

Usage: python3 tools/_t364-t308-teeth.py     Exit 0 = the bucket fills as predicted.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CORPUS = os.path.join(ROOT, "examples", "aef-processes", "rendered")
GATE = os.path.join(HERE, "_t308-export-byte-identity-cdp.mjs")
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")

# Three maps is enough for every assertion here (all of them are about which bucket a
# document lands in, not about corpus size) and keeps three CDP runs to a sane runtime.
SAMPLE = ["arc-lifecycle.bpmn", "audit-process.bpmn", "context-memory.bpmn"]

PASS, FAIL = [], []


def ok(msg):
    PASS.append(msg)
    print("  PASS  " + msg)


def bad(msg):
    FAIL.append(msg)
    print("  FAIL  " + msg)


DEAD = []


def dead(msg):
    """The control leg ran and did not pass — rc 4, T-666.

    Distinct from die() (rc 3, could not measure) and from bad() (rc 1, a real
    regression in the thing this guards). A failed control is neither: it says the
    instrument is broken and makes every leg below it meaningless, which is exactly
    what this file's own docstring has claimed since T-663 while the code went on to
    run them anyway and report rc 1.
    """
    DEAD.append(msg)
    print("  TEETH BROKEN — " + msg)


def die(msg):
    print("COULD-NOT-MEASURE: " + msg, file=sys.stderr)
    sys.exit(3)


def substitute(path_in, path_out, old, new, label):
    """Write a mutant and prove the ORIGINAL FORM IS GONE.

    T-661: counting the substituted marker cannot distinguish a landed mutation from a
    marker the subject already contained. The sound assertion is before >= 1 and
    after == 0, with no upper bound.
    """
    text = open(path_in, encoding="utf-8").read()
    before = text.count(old)
    if before < 1:
        die("STALE ANCHOR — the %s anchor matches 0 sites; the mutation had nothing to "
            "change and the 'mutant' would be an unmodified copy" % label)
    out = text.replace(old, new)
    if out.count(old) != 0:
        die("MUTATION INCOMPLETE — %s sites of %s survived" % (out.count(old), label))
    open(path_out, "w", encoding="utf-8").write(out)
    return before


def run(corpus_dir, gate=GATE, old_src=None):
    env = dict(os.environ, T308_CORPUS=corpus_dir)
    if old_src:
        env["T308_OLD_SRC"] = old_src
    p = subprocess.run([ "node", gate ], cwd=ROOT, env=env,
                       capture_output=True, text=True, timeout=900)
    try:
        return json.loads(p.stdout), p.returncode
    except json.JSONDecodeError:
        die("gate did not emit JSON (rc=%s)\nstdout: %s\nstderr: %s"
            % (p.returncode, p.stdout[:400], p.stderr[-400:]))


def brief(d):
    return "ok=%s maps=%s identical=%s drifted=%s unusable=%s" % (
        d.get("ok"), d.get("maps"), d.get("identical"), d.get("drifted"), d.get("unusable"))


def main():
    for f in (GATE, SRC):
        if not os.path.exists(f):
            die("missing " + f)

    tmp = tempfile.mkdtemp(prefix="t364-teeth-")
    try:
        corpus = os.path.join(tmp, "corpus")
        os.makedirs(corpus)
        for name in SAMPLE:
            s = os.path.join(CORPUS, name)
            if not os.path.exists(s):
                die("sample map missing from corpus: " + s)
            shutil.copyfile(s, os.path.join(corpus, name))
        n = len(SAMPLE)

        print("=== T-364/T-663: _t308's `unusable` bucket must be shown fillable ===")
        print()

        # -- control ------------------------------------------------------------
        # No ref pinned, no override: the tree build compared against itself. This is
        # the assertion that used to rot; it now cannot, because there is no second
        # build to drift away from.
        print("--- control: a corpus the gate CAN measure comes back clean")
        d, rc = run(corpus)
        print("  " + brief(d))
        if d.get("srcOverride") is not None:
            dead("control ran with an override set — it is not a clean-gate result")
        elif not (d.get("ok") and rc == 0):
            dead("control did not pass, so nothing below proves anything: " + brief(d))
        elif d.get("unusable") != 0 or d.get("drifted") != 0:
            dead("control is not clean: " + brief(d))
        elif d.get("identical") != n or d.get("maps") != n:
            dead("control denominator wrong: expected %d/%d, got %s" % (n, n, brief(d)))
        else:
            ok("clean gate: ok=true, identical=%d/%d, unusable=0, no pinned baseline" % (n, n))

        # -- the bucket fills ---------------------------------------------------
        print("--- fills: an old-side build with a nondeterministic emitted field")
        mutant = os.path.join(tmp, "designer-unstable.html")
        substitute(
            SRC, mutant,
            '<aef:uid value="${escAttr(node.uid)}"/>',
            '<aef:uid value="${escAttr(node.uid)}_${Math.random()}"/>',
            "emitted-uid",
        )
        d, rc = run(corpus, old_src=mutant)
        print("  " + brief(d))
        if d.get("srcOverride") != mutant:
            bad("result does not declare the override — it could be quoted as a gate run")
        else:
            ok("the override declares itself in the result (srcOverride + ref)")

        if d.get("unusable") != n:
            bad("bucket did not fill: expected unusable=%d, got %s" % (n, brief(d)))
        else:
            ok("unusable filled: %d/%d unstable documents detected" % (n, n))

        if d.get("identical") != 0:
            bad("an unmeasurable document was counted IDENTICAL (%s) — the gate would "
                "report a green over a hole" % brief(d))
        else:
            ok("identical=0: no unmeasurable document was counted as a match")

        if d.get("maps") != n:
            bad("denominator shrank to %s — unmeasurable maps vanished from the count"
                % d.get("maps"))
        else:
            ok("maps=%d: the denominator did not quietly shrink" % n)

        if d.get("ok") is not False or rc == 0:
            bad("run reported ok=%s rc=%s — an unusable map must FAIL the gate"
                % (d.get("ok"), rc))
        else:
            ok("the run fails: a gate with no answer does not return a green")

        # -- the teeth's own teeth ----------------------------------------------
        # Disable the detection branch in a COPY of the gate. If `fills` above was
        # produced by anything other than that branch, this run still reports unusable
        # and the assertion below catches it.
        print("--- teeth: with the detection branch disabled, the same input must NOT")
        print("           report unusable — it must resurface as drifted")
        # The blunted copy must sit in tools/ , not in tmp: _t308 resolves
        # `./_cdp-attach.mjs`, `gallery-serve.py` and REPO (= its own dir/..) relatively,
        # so a copy anywhere else has no repo and dies on import. Removed in `finally`,
        # and the run asserts it is gone rather than trusting that it is.
        blunted = os.path.join(HERE, "_t308-BLUNTED-TEMP.mjs")
        substitute(
            GATE, blunted,
            "if (B.selfStable === false || A.selfStable === false) {",
            "if (false) {",
            "unusable-detection",
        )
        d2, rc2 = run(corpus, gate=blunted, old_src=mutant)
        print("  " + brief(d2))
        if d2.get("unusable") != 0:
            bad("blunted gate still reports unusable=%s — `fills` did not come from the "
                "detection branch, so it proves nothing about it" % d2.get("unusable"))
        elif d2.get("drifted") != n:
            bad("blunted gate reported drifted=%s, expected %d — the unstable documents "
                "went somewhere unexplained" % (d2.get("drifted"), n))
        else:
            ok("detection branch is load-bearing: disabling it moves all %d documents "
               "from unusable to drifted" % n)

        if d2.get("identical") != 0:
            bad("blunted gate counted an unstable document identical (%s) — that is the "
                "silent-green failure G-023 records, reachable in one edit" % brief(d2))
        else:
            ok("even blunted, nothing unstable was counted identical")

    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        stray = os.path.join(HERE, "_t308-BLUNTED-TEMP.mjs")
        if os.path.exists(stray):
            os.remove(stray)

    if os.path.exists(os.path.join(HERE, "_t308-BLUNTED-TEMP.mjs")):
        bad("the blunted copy survived in tools/ — a mutated gate left in the tree is "
            "worse than no teeth at all")

    print()
    print("=== %d passed, %d failed ===" % (len(PASS), len(FAIL)))
    # T-666: a dead control outranks a leg failure. If the control did not pass, the leg
    # results below it are not evidence either way, so reporting them as a regression
    # would be asserting something this run cannot know.
    if DEAD:
        return 4
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
