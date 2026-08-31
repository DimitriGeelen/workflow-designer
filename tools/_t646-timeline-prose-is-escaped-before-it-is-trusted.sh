#!/usr/bin/env bash
# T-646 — prose that reaches the browser through `linkify_tasks` must be ESCAPED
# before the result is declared trusted HTML.
#
# WHAT WENT WRONG. `app.py` registers the filter as
#     lambda text: Markup(linkify_tasks(text))
# and `linkify_tasks` substituted anchors into the RAW string. Markup() then vouched
# for the whole result, not just the anchors the function had added. A FUNCTION MAY
# ONLY VOUCH FOR MARKUP IT CREATED ITSELF; this one was vouching for its input.
#
# The input is not incidental. Timeline narratives are read out of committed handover
# markdown (blueprints/timeline.py:159) — prose written by sessions, and sessions
# write about HTML. Measured on the live board before the fix: two `<html` tags
# reaching the browser from a paragraph *discussing* fragments, in the same sentence
# as a live `<a href="/tasks/T-2309">` that proves the string was marked safe.
#
# WHAT THIS PROBER DOES NOT DO: it does not retype the function. The teeth leg
# extracts `linkify_tasks`' REAL source out of shared.py, reverses the two tokens the
# fix introduced, and executes that — so if the function is later rewritten in a shape
# the mutation cannot find, this file says COULD-NOT-MEASURE instead of passing.
#
# Exit 0 = all legs pass.

set -uo pipefail

PROJ="${T646_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FWROOT="$PROJ/.agentic-framework"
SHARED="$FWROOT/web/shared.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SHARED" ] || { echo "COULD-NOT-MEASURE: $SHARED not found" >&2; exit 3; }

echo "=== T-646: timeline prose is escaped before it is trusted ==="
echo

# ---------------------------------------------------------------------------
echo "--- the live function: metacharacters become text, T-refs become links"
T646_FWROOT="$FWROOT" python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ["T646_FWROOT"])
from web.shared import linkify_tasks

def leg(name, got, want_in=(), want_not_in=()):
    bad = [w for w in want_in if w not in got] + [w for w in want_not_in if w in got]
    print(("  PASS  " if not bad else "  FAIL  ") + name + ("" if not bad else "  | offending=%r got=%r" % (bad, got)))
    return not bad

rc = 0
s = str(linkify_tasks("see T-123 for <html> and & stuff"))
rc |= not leg("a raw < in prose is published as text, not as a tag",
              s, want_in=["&lt;html&gt;"], want_not_in=["<html>"])
rc |= not leg("the feature survives: T-123 is still an anchor, beside escaped neighbours",
              s, want_in=['<a href="/tasks/T-123">T-123</a>'])

s = str(linkify_tasks("<script>alert(1)</script> in T-2309"))
rc |= not leg("a script tag in a narrative does not become a script element",
              s, want_in=["&lt;script&gt;"], want_not_in=["<script"])
rc |= not leg("...and the T-ref adjacent to it still links",
              s, want_in=['<a href="/tasks/T-2309">T-2309</a>'])

s = str(linkify_tasks("a & b"))
rc |= not leg("EXACTLY ONE escaping pass: `a & b` -> `a &amp; b`, never `&amp;amp;`",
              s, want_in=["a &amp; b"], want_not_in=["&amp;amp;"])

# The filter's own contract: Jinja must not escape the anchors a second time.
from markupsafe import Markup
rc |= not leg("the return value is Markup, so Jinja renders the anchors rather than showing them",
              type(linkify_tasks("T-123")).__name__, want_in=["Markup"])
sys.exit(1 if rc else 0)
PY
if [ $? -eq 0 ]; then PASS=$((PASS+6)); else FAIL=$((FAIL+1)); fi

# ---------------------------------------------------------------------------
echo
echo "--- teeth: restore the linkify-then-trust order and the injection must come back"
T646_SHARED="$SHARED" python3 - <<'PY'
import os, re, sys
src = open(os.environ["T646_SHARED"]).read()
m = re.search(r"\ndef linkify_tasks\(text\):.*?\n(?=\n\n)", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: linkify_tasks' source could not be located.\n"); sys.exit(3)
body = m.group(0)

# Reverse exactly the two tokens the T-646 fix introduced. Anchored on the shipped
# text so a rewrite that changes the shape is reported rather than silently skipped.
if "str(escape(text))" not in body or "return Markup(re_mod.sub(" not in body:
    sys.stderr.write("COULD-NOT-MEASURE: the fix is not present in the shape this "
                     "mutation reverses; update the mutation rather than pinning a copy.\n")
    sys.exit(3)
pre = body.replace("str(escape(text))", "str(text)")
pre = pre.replace("return Markup(re_mod.sub(", "return (re_mod.sub(")

import re as re_mod
from markupsafe import Markup, escape
ns = {"re_mod": re_mod, "Markup": Markup, "escape": escape}
exec(compile(pre, "<pre-t646-linkify>", "exec"), ns)

# app.py's filter is the second half of the defect: it wraps whatever comes back.
out = str(Markup(ns["linkify_tasks"]("<script>alert(1)</script> in T-2309")))
if "<script" in out:
    print("  PASS  pre-fix ordering republishes the injected element: %r" % out[:48])
    sys.exit(0)
print("  FAIL  pre-fix ordering did NOT reproduce the defect — this leg cannot fail and proves nothing")
sys.exit(1)
PY
RC=$?
if   [ $RC -eq 0 ]; then PASS=$((PASS+1))
elif [ $RC -eq 3 ]; then echo "COULD-NOT-MEASURE: teeth leg could not be built" >&2; exit 3
else FAIL=$((FAIL+1)); fi

# ---------------------------------------------------------------------------
echo
echo "--- end to end: the live board serves no prose-borne tag on /timeline"
# Skipped rather than failed when the board is down or is still running pre-fix code:
# a stale server is a deployment fact, not a defect in this change. The skip says which.
WURL=$(cat "$PROJ/.context/working/watchtower.url" 2>/dev/null || echo "")
if [ -z "$WURL" ] || ! curl -sf --max-time 10 "$WURL/" -o /dev/null 2>/dev/null; then
    echo "  SKIP  Watchtower not reachable at '${WURL:-<unset>}' — end-to-end leg not decidable"
else
    T646_WURL="$WURL" python3 - <<'PY'
import os, sys, urllib.request
url = os.environ["T646_WURL"] + "/timeline"
req = urllib.request.Request(url, headers={"HX-Request": "true"})
try:
    h = urllib.request.urlopen(req, timeout=120).read().decode("utf-8", "replace")
except Exception as e:
    print("  SKIP  /timeline did not respond (%s) — end-to-end leg not decidable" % type(e).__name__)
    sys.exit(0)
raw, esc = h.count("<html"), h.count("&lt;html")
if raw == 0:
    print("  PASS  /timeline: 0 raw `<html`, %d escaped — prose is text on the live board" % esc)
    sys.exit(0)
print("  FAIL  /timeline still publishes %d raw `<html` (%d escaped). If the fix is in the "
      "tree, the server is running pre-fix code — restart Watchtower and re-run." % (raw, esc))
sys.exit(1)
PY
    [ $? -eq 0 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
