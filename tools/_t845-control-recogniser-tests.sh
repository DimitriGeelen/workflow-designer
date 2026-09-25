#!/usr/bin/env bash
# T-845 — tests for _t560's control RECOGNISER (control_level / control_reason).
#
# WRITTEN AND RUN BEFORE THE CHANGE, on the standing directive to build on tests. Its first run
# is recorded in T-845 failing for the right reasons — three under-crediting cases plus a
# missing reason function — rather than passing vacuously.
#
# WHAT IS UNDER TEST. The recogniser decides whether an absence-asserting leg is controlled. It
# is now load-bearing: _t560 gates task closes via T-843, so a control it cannot SEE blocks a
# close and pushes the author toward a weaker assertion it can see. Three known defects:
#   OBS-377  `test -x` is not credited, though -x implies -f
#   OBS-379  patterns shorter than 3 chars can never earn PATTERN credit, silently
#   OBS-379  an uncredited leg gives no reason, so "control wrong" and "pattern ignored" look
#            identical to the author — the mistake that made T-843 report 16 drained, not 14
#
# THE REGRESSION DIRECTION THAT MATTERS. Every change here makes the census credit MORE, i.e.
# see FEWER uncontrolled legs — the false-negative direction. So the suite pins the guards as
# hard as the fixes: a substring coincidence must STILL be refused after the length floor goes,
# because the floor's real purpose was guarding that and the same-string rule must carry it
# alone.

set -uo pipefail
REPO="${T845_REPO_ROOT:-/opt/832-Workflow-designer}"
exec python3 - "$REPO" <<'PY'
import sys, importlib.util
repo = sys.argv[1]
spec = importlib.util.spec_from_file_location("c", repo + "/tools/_t560-absence-assertion-census.py")
c = importlib.util.module_from_spec(spec); spec.loader.exec_module(c)

P = F = N = 0
def ok(m):
    global P, N; P += 1; N += 1; print("ok %d - %s" % (N, m))
def bad(m):
    global F, N; F += 1; N += 1; print("not ok %d - %s" % (N, m))
def lvl(text, sibs=()):
    return c.control_level(text, list(sibs))

# ── FIX 1 (OBS-377): -x / -e / -r must count as existence controls ────────────
for flag in ("-x", "-e", "-r"):
    t = 'test %s tools/x.sh && ! grep -q \'MARKER\' tools/x.sh' % flag
    got = lvl(t)
    ok("test %s is an existence control" % flag) if got == "EXISTENCE" \
        else bad("test %s gave %s, expected EXISTENCE" % (flag, got))

# ── FIX 2 (OBS-379): a 2-char pattern must be creditable ──────────────────────
leg = """test "$(ls -d .editor-versions/*/ | xargs -n1 basename | grep -vc '^_')" -eq 24"""
sib = """test "$(ls -d .editor-versions/*/ | xargs -n1 basename | grep -c '^_')" -ge 1"""
got = lvl(leg, [sib])
ok("a 2-character same-string companion earns PATTERN") if got == "PATTERN" \
    else bad("2-char same-string companion gave %s, expected PATTERN" % got)

# ── GUARD (the floor's real purpose must survive its removal) ─────────────────
# The sibling MENTIONS the pattern in prose but never greps it. Mention is not invocation.
leg2 = """! grep -q 'workflowMeta' src/x.html"""
sib2 = """python3 -c "print('workflowMeta appears here as prose')\""""
got = lvl(leg2, [sib2])
ok("a pattern MENTIONED but not grepped is still refused") if got == "NONE" \
    else bad("substring/mention coincidence was credited as %s — over-crediting" % got)

# A 2-char pattern must also not be creditable by mere mention.
leg3 = """test "$(grep -vc '^_' f)" -eq 3"""
sib3 = """echo "the prefix ^_ is documented here\""""
got = lvl(leg3, [sib3])
ok("a 2-char pattern MENTIONED but not grepped is still refused") if got == "NONE" \
    else bad("2-char mention was credited as %s — the floor's purpose was lost" % got)

# ── NO REGRESSION on what already worked ─────────────────────────────────────
got = lvl("""test -f f && ! grep -q 'LONGPATTERN' f""")
ok("test -f still credits EXISTENCE") if got == "EXISTENCE" else bad("test -f gave %s" % got)
got = lvl("""! grep -q 'LONGPATTERN' f""", ["""grep -q 'LONGPATTERN' g"""])
ok("a long same-string companion still credits PATTERN") if got == "PATTERN" else bad("long companion gave %s" % got)
got = lvl("""! grep -q 'LONGPATTERN' f""")
ok("a leg with no control at all is still NONE") if got == "NONE" else bad("bare leg gave %s" % got)

# ── FIX 3 (OBS-379): an uncredited leg must say WHY ───────────────────────────
if not hasattr(c, "control_reason"):
    bad("control_reason() does not exist — an uncredited leg gives the author no reason")
else:
    r = c.control_reason("""! grep -q 'LONGPATTERN' f""", [])
    ok("uncredited leg carries a reason: %r" % r) if r and str(r).strip() \
        else bad("control_reason returned nothing for an uncontrolled leg")
    r2 = c.control_reason("""! grep -q $UNQUOTED f""", [])
    ok("unreadable-pattern leg carries a reason: %r" % r2) if r2 and str(r2).strip() \
        else bad("control_reason returned nothing for an unreadable leg")

print("\n# passed %d, failed %d" % (P, F))
sys.exit(1 if F else 0)
PY
