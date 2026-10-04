#!/usr/bin/env python3
"""_t1017-uid-count-teeth.py — the round-trip leg counts DECLARED identities, not comment prose.

WHY (T-1017): tools/_roundtrip-serialization-cdp.mjs gates every fixture on undeclaredUid === 0,
counting `<aef:uid ` occurrences in the fixture SOURCE. It counted inside XML comments, so
plain-task-default-ns.bpmn (whose header prose mentions "<aef:uid value=…/>") read 6 declared
against 5 real elements and the leg had been red since T-970. The same blindness has a worse
twin: a fixture whose only "declaration" of an identity sits inside a comment would PASS.

Legs (temp fixture dir via ROUNDTRIP_FIXTURES_DIR, the harness's own seam; real editor):
  1. control: the real plain-task fixture, unchanged          -> ok
  2. a uid element removed                                     -> NOT ok (undeclaredUid 1)
  3. that uid moved INTO a comment (prose-only "declaration")  -> NOT ok (undeclaredUid 1)
  4. discrimination: leg 3's mutant against HEAD's harness (pre-fix) PASSES it, showing the
     fix is what catches it. Reported, not gated: once this commit lands, HEAD is the fix.
Exit 0 = legs 1-3 pass, 1 = a leg fails, 2 = cannot run.
"""
import json, os, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_roundtrip-serialization-cdp.mjs")
SRC = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "plain-task-default-ns.bpmn")
UID = '<aef:uid value="u-task-1"/>'

if shutil.which("node") is None or not os.path.isfile(HARNESS) or not os.path.isfile(SRC):
    print("CANNOT RUN: node, the harness or the source fixture is missing"); sys.exit(2)
text = open(SRC, encoding="utf-8").read()
if text.count(UID) != 1:
    print("CANNOT RUN: the fixture no longer carries exactly one %s" % UID); sys.exit(2)


def run(harness, fixtures):
    # The harness self-tests its key controls against the corpus and refuses (no per-fixture
    # verdicts) on a tiny one, so the mutants ride alongside a full copy of the real corpus.
    d = tempfile.mkdtemp(prefix="t1017-")
    try:
        corpus = os.path.dirname(SRC)
        for name in os.listdir(corpus):
            if name.endswith(".bpmn"):
                shutil.copy(os.path.join(corpus, name), d)
        for name, body in fixtures.items():
            open(os.path.join(d, name), "w", encoding="utf-8").write(body)
        p = subprocess.run(["node", harness], cwd=ROOT, capture_output=True, text=True, timeout=300,
                           env=dict(os.environ, ROUNDTRIP_FIXTURES_DIR=d))
        out = p.stdout
        v = json.loads(out[out.find("{"):out.rfind("}") + 1])
        return {f["fixture"]: f for f in v.get("fixtures", [])}
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _prose_neutral(t):
    """Remove `<aef:uid ` occurrences that sit inside comments, keeping real elements."""
    out, i = [], 0
    while True:
        a = t.find("<!--", i)
        if a < 0:
            out.append(t[i:]); break
        b = t.find("-->", a + 4)
        if b < 0:
            out.append(t[i:]); break
        out.append(t[i:a]); out.append(t[a:b + 3].replace("<aef:uid ", "aef:uid ")); i = b + 3
    return "".join(out)


fixtures = {
    "a-control.bpmn": text,
    "b-uid-removed.bpmn": text.replace(UID, ""),
    # Leg 3's mutant also neutralises the header PROSE mention (outside any element), so the
    # only "<aef:uid " left for Task_1 is the commented-out one: the case the old count passed.
    "c-uid-in-comment.bpmn": _prose_neutral(text).replace(UID, "<!-- " + UID + " -->"),
}
res = run(HARNESS, fixtures)
fails = 0


def leg(name, ok, detail):
    global fails
    fails += 0 if ok else 1
    print("  %s  %s  (%s)" % ("PASS" if ok else "FAIL", name, detail))


def show(f):
    return "ok=%s declared=%s expected=%s" % (f.get("ok"), f.get("declaredUids"), f.get("expectedUids"))


print("=== T-1017: uid count reads declarations, not comments ===")
a, b, c = res.get("a-control.bpmn", {}), res.get("b-uid-removed.bpmn", {}), res.get("c-uid-in-comment.bpmn", {})
leg("1 control fixture passes", a.get("ok") is True and a.get("undeclaredUid") == 0, show(a))
leg("2 a removed uid is caught", b.get("ok") is False and b.get("undeclaredUid") == 1, show(b))
leg("3 a uid that exists only inside a comment is caught", c.get("ok") is False and c.get("undeclaredUid") == 1, show(c))

# Leg 4: the same mutant against HEAD's harness. Informational.
head = subprocess.run(["git", "-C", ROOT, "show", "HEAD:tools/_roundtrip-serialization-cdp.mjs"],
                      capture_output=True, text=True)
if head.returncode == 0 and "T-1017" not in head.stdout:
    hp = os.path.join(ROOT, "tools", ".t1017-head-harness.mjs")
    try:
        open(hp, "w", encoding="utf-8").write(head.stdout)
        hc = run(hp, {"c-uid-in-comment.bpmn": fixtures["c-uid-in-comment.bpmn"]}).get("c-uid-in-comment.bpmn", {})
        print("  INFO  4 pre-fix harness on the comment-only mutant: %s%s" % (
            show(hc), "  <- passes it: the defect" if hc.get("ok") else ""))
    finally:
        os.remove(hp)
else:
    print("  INFO  4 skipped: HEAD already carries the fix")

print("=== %d/3 legs passed ===" % (3 - fails))
sys.exit(1 if fails else 0)
