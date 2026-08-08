#!/usr/bin/env python3
"""
_t379-rendered-as-wire-sweep.py — does anything here read rail message CONTENT
out of a human-rendered view instead of the payload?

WHY THIS EXISTS
---------------
AEF (their T-2872) lost a byte on a delivered artifact and it took two projects a
day to find out where. Their send was faithful, the hub was faithful, their client
was faithful. The lossy step was the CHOICE OF SOURCE: they extracted the artifact
by slicing a human-rendered `subscribe` view, which prefixes every record with a
display header and terminates each with a newline. A display format adding a header
and a terminator is a display format doing its job. Reading it as a wire format is a
category error, and category errors are not fixed by fixing anything.

Their rule, adopted here: seam bytes come from `payload_b64`, hashed before they
touch a file. Rendered output is never a wire format. This sweep is the symmetric
check on our tree.

WHAT IT CLASSIFIES, AND WHY THREE BUCKETS AND NOT TWO
-----------------------------------------------------
    PAYLOAD    invokes a content-reading verb with --json (and/or decodes payload_b64)
    RENDERED   invokes a content-reading verb WITHOUT --json and consumes the output
    NO-READ    mentions termlink but never reads message content

"Not a defect" and "not examined" are different states. A two-way split silently
merges the second into the first, and a file that never reads content would then be
counted as evidence of fidelity. It is not evidence of anything.

WHY THE DENOMINATOR IS PRINTED WITH THE VERDICT
-----------------------------------------------
Zero RENDERED readers over zero examined files is the empty-denominator failure this
project has already paid for twice (T-344: eleven watch globs all expanding to
nothing, so both coverage checks compared empty sets and printed PASS). A clean sweep
is only worth what its population is worth, so the population is in the verdict line.

TEETH
-----
A classifier that returns PAYLOAD unconditionally would give a green sweep over any
tree. Before any real file is read, the classifier is run against a constructed
rendered-reader and a constructed payload-reader and must tell them apart. If it
cannot, the sweep refuses to report.

Usage: python3 tools/_t379-rendered-as-wire-sweep.py
Exit 0 = no RENDERED reader, over a non-empty population, with a classifier proven
         able to name one.
"""

import re
import subprocess
import sys

# Verbs that return message CONTENT. Invoking these and consuming the output is the
# operation under test; `channel post`, `list`, `ping` etc. are not.
CONTENT_VERBS = [
    r"channel\s+subscribe", r"channel\s+thread", r"channel\s+search",
    r"agent\s+dms", r"agent_dms", r"agent\s+thread", r"agent\s+recent",
    r"agent\s+inbox", r"recent[_\s]dm", r"event\s+poll",
    r"channel_subscribe", r"channel_thread", r"agent_recent", r"agent_thread",
]
# Python invokes the CLI as an argv LIST -- ["termlink", "channel", "subscribe", ...] --
# where the two words are separated by quotes and a comma, not whitespace. The first
# working version of this sweep missed that form entirely, and the file it missed was
# this repo's own _t377 probe. For a findings list an under-approximating matcher errs
# safely; for a ZERO it does the opposite, because the denominator IS the claim.
ARGV_VERBS = [
    (r"channel", r"subscribe"), (r"channel", r"thread"), (r"channel", r"search"),
    (r"agent", r"dms"), (r"agent", r"thread"), (r"agent", r"recent"),
    (r"agent", r"inbox"), (r"event", r"poll"),
]
CONTENT_VERBS += [r'["\']%s["\']\s*,\s*["\']%s["\']' % (a, b) for a, b in ARGV_VERBS]
CONTENT_RE = re.compile("|".join(CONTENT_VERBS))

PAYLOAD_MARKERS = re.compile(r"--json\b|payload_b64|b64decode|--payload-from-file")


TRIPLE = re.compile(r'("""|\'\'\')(?:.|\n)*?\1')
ARRAY_USE = re.compile(r'\$\{(\w+)\[@\]\}')
# The tool itself, however it is spelled at a call site: bare binary, a resolved path
# variable, or the MCP tool name.
TOOL_RE = re.compile(r'\btermlink\b|\$\{?TERMLINK\}?|termlink_')


def strip_prose(text):
    """Remove docstrings and comment-only lines.

    The FIRST run of this sweep reported 5 rendered readers. All five were noise:
    three were array-built invocations whose --json sat outside a 4-line window, and
    two were module DOCSTRINGS describing an invocation rather than performing one --
    including this repo's own rail-sweep.py, whose docstring quotes the very commands
    it exists to distrust. An over-broad matcher manufactures findings, and a findings
    list that has to be hand-checked is not a check.
    """
    text = TRIPLE.sub(lambda m: "\n" * m.group(0).count("\n"), text)
    out = []
    for ln in text.splitlines():
        s = ln.strip()
        out.append("" if (s.startswith("#") or s.startswith("//")) else ln)
    return "\n".join(out)


def classify(text):
    """Three-way. Returns (bucket, evidence)."""
    lines = strip_prose(text).splitlines()
    reads = []
    for i, ln in enumerate(lines, 1):
        if not CONTENT_RE.search(ln):
            continue
        # The verb must appear WITH the tool. `echo "channel subscribe failed"` names
        # the operation without performing it, and was the last survivor of the first
        # run's noise -- it landed in RENDERED purely because the array assignment sat
        # one line outside its window, i.e. two of my own defects cancelled to a
        # finding. An error string is not a call site.
        if not TOOL_RE.search(ln):
            continue
        # Shell builds invocations in arrays: `sub_args=("$topic" --json ...)` sits
        # several lines above `subscribe "${sub_args[@]}"`. A fixed window cannot see
        # it, so resolve the array by name across the whole file. Widened to 12 lines
        # back as well, for plain multi-line continuations.
        window = "\n".join(lines[max(0, i - 12): i + 4])
        for var in ARRAY_USE.findall(ln):
            for j, other in enumerate(lines):
                if re.search(r"\b%s(\+)?=\(" % re.escape(var), other):
                    window += "\n" + "\n".join(lines[j: j + 6])
        reads.append((i, lines[i - 1].strip()[:110], bool(PAYLOAD_MARKERS.search(window))))
    if not reads:
        return "NO-READ", []
    rendered = [r for r in reads if not r[2]]
    if rendered:
        return "RENDERED", rendered
    return "PAYLOAD", reads


npass = nfail = 0


def ok(m):
    global npass
    npass += 1
    print("  PASS  " + m)


def bad(m):
    global nfail
    nfail += 1
    print("  FAIL  " + m)


print("T-379 — does anything here read rail content from a rendered view?")
print()

# --- teeth, before any real file is read -----------------------------------------
CTRL_RENDERED = 'out=$(termlink channel subscribe "$TOPIC" --cursor 454 --limit 1)\nbody=${out#*chat: }\n'
CTRL_PAYLOAD = 'termlink channel subscribe "$TOPIC" --cursor 454 --limit 1 --json > raw.json\npython3 -c "b64decode(payload_b64)"\n'
CTRL_NOREAD = 'termlink channel post "$TOPIC" --payload "hello"\n'

k, _ = classify(CTRL_RENDERED)
if k == "RENDERED":
    ok("teeth: a constructed rendered-slicer classifies RENDERED")
else:
    bad("teeth: the constructed rendered-slicer classified %s — the classifier cannot" % k)
    bad("      name the defect it exists to find; no sweep result below is readable")

k, _ = classify(CTRL_PAYLOAD)
if k == "PAYLOAD":
    ok("teeth: a constructed payload-reader classifies PAYLOAD")
else:
    bad("teeth: the constructed payload-reader classified %s — the classifier would" % k)
    bad("      manufacture findings out of correct code")

k, _ = classify(CTRL_NOREAD)
if k == "NO-READ":
    ok("teeth: a write-only site classifies NO-READ — 'not examined' stays separable")
else:
    bad("teeth: a write-only site classified %s — NO-READ is being folded into a" % k)
    bad("      verdict about fidelity it says nothing about")

# The three controls above existed before the first run and all three passed, and the
# run still produced five findings that were all noise. Teeth prove a classifier FIRES;
# they say nothing about whether it fires on the right thing. So the next three controls
# are not imagined failure modes — they are the two that actually occurred, plus the one
# the REPAIR could have introduced.
CTRL_ARRAY_JSON = (
    'sub_args=("$topic" --json --limit "$limit")\n'
    '[ -n "$hub" ] && sub_args+=(--hub "$hub")\n'
    'raw="$("$TERMLINK" channel subscribe "${sub_args[@]}" 2>/dev/null)"\n'
)
CTRL_ARRAY_NOJSON = (
    'sub_args=("$topic" --limit "$limit")\n'
    '[ -n "$hub" ] && sub_args+=(--hub "$hub")\n'
    'raw="$("$TERMLINK" channel subscribe "${sub_args[@]}" 2>/dev/null)"\n'
    'body=${raw#*chat: }\n'
)
CTRL_DOCSTRING = '"""\nSubstrate: `termlink event poll <target> --topic inbox.queued`.\n"""\nx = 1\n'

k, _ = classify(CTRL_ARRAY_JSON)
if k == "PAYLOAD":
    ok("teeth: an array-built invocation carrying --json resolves to PAYLOAD")
else:
    bad("teeth: array-built --json classified %s — this is the false positive that" % k)
    bad("      produced three of the first run's five findings")

k, _ = classify(CTRL_ARRAY_NOJSON)
if k == "RENDERED":
    ok("teeth: an array-built invocation WITHOUT --json still classifies RENDERED —")
    ok("      the array-resolution fix did not blanket everything into PAYLOAD")
else:
    bad("teeth: array-built without --json classified %s — the repair overshot and the" % k)
    bad("      classifier can no longer find the defect at all. A correction that")
    bad("      cannot fail is worse than the count it replaced.")

k, _ = classify(CTRL_DOCSTRING)
if k == "NO-READ":
    ok("teeth: an invocation quoted inside a docstring is not counted as one")
else:
    bad("teeth: a docstring mention classified %s — prose is being read as code, which" % k)
    bad("      is the other half of the first run's noise")

CTRL_ERRSTRING = (
    'raw="$("$TERMLINK" channel subscribe "$topic" --json)"\n'
    'echo "agent-listeners: channel subscribe failed (exit=$rc)" >&2\n'
)
k, ev = classify(CTRL_ERRSTRING)
if k == "PAYLOAD" and len(ev) == 1:
    ok("teeth: an error string naming the verb is not counted as a call site")
else:
    bad("teeth: an error string classified %s with %d read(s) — the verb is being" % (k, len(ev)))
    bad("      matched without the tool, which is how a message became a finding")

CTRL_ARGV = (
    'p = subprocess.run(["termlink", "channel", "subscribe", topic, "--json"],\n'
    '                   capture_output=True)\n'
)
k, _ = classify(CTRL_ARGV)
if k == "PAYLOAD":
    ok("teeth: a Python argv-list invocation is SEEN (and read as PAYLOAD) — the form")
    ok("      the first working version missed, in this repo's own probe")
else:
    bad("teeth: an argv-list invocation classified %s — the sweep is blind to every" % k)
    bad("      Python call site, and its zero is measured over the wrong population")

CTRL_ARGV_RENDERED = (
    'p = subprocess.run(["termlink", "channel", "subscribe", topic], capture_output=True)\n'
    'body = p.stdout.split("chat: ")[1]\n'
)
k, _ = classify(CTRL_ARGV_RENDERED)
if k == "RENDERED":
    ok("teeth: an argv-list invocation WITHOUT --json classifies RENDERED")
else:
    bad("teeth: argv-list without --json classified %s — the new form is visible but" % k)
    bad("      not discriminating, which buys nothing")

# And the one that guards the whole repair direction: after three corrections that
# each REMOVED findings, the classifier must still be able to produce one. Every fix
# here moved the count toward zero, which is the direction a broken matcher also moves.
k, _ = classify('out=$(termlink channel subscribe "$T" --limit 1)\nbody=${out#*: }\n')
if k == "RENDERED":
    ok("teeth: after three corrections the classifier still reports a real rendered")
    ok("      reader — the repairs narrowed the matcher, not the question")
else:
    bad("teeth: the classifier can no longer find a plain rendered read (%s). Three" % k)
    bad("      corrections in the same direction have ended in an instrument that")
    bad("      cannot fail, and its zero would mean nothing.")

if nfail:
    print()
    print("  classifier failed its own controls — refusing to sweep")
    sys.exit(1)

# --- population ------------------------------------------------------------------
files = subprocess.run(
    ["git", "ls-files"], capture_output=True, text=True, check=True
).stdout.splitlines()
CODE = re.compile(r"\.(sh|py|mjs|js)$")
# dist/ and vendor/ are built artifacts: copies of src, not independently maintained
# readers. Named here rather than silently filtered, so the exclusion is auditable.
candidates = [f for f in files
              if CODE.search(f)
              and not f.startswith("dist/")
              and not f.startswith("vendor/")]

buckets = {"PAYLOAD": [], "RENDERED": [], "NO-READ": []}
examined = 0
for f in candidates:
    try:
        text = open(f, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    if "termlink" not in text:
        continue
    examined += 1
    b, ev = classify(text)
    buckets[b].append((f, ev))

print()
print("  population: %d code file(s) tracked, %d mention termlink" % (len(candidates), examined))
print("  PAYLOAD %d   RENDERED %d   NO-READ %d"
      % (len(buckets["PAYLOAD"]), len(buckets["RENDERED"]), len(buckets["NO-READ"])))
print()

for f, ev in buckets["PAYLOAD"]:
    print("    PAYLOAD   %s" % f)
    for ln, src, _ in ev[:3]:
        print("              :%d  %s" % (ln, src))
for f, ev in buckets["NO-READ"]:
    print("    NO-READ   %s" % f)
for f, ev in buckets["RENDERED"]:
    print("    RENDERED  %s" % f)
    for ln, src, _ in ev:
        print("              :%d  %s" % (ln, src))

print()
# --- verdict, with the denominator attached --------------------------------------
readers = len(buckets["PAYLOAD"]) + len(buckets["RENDERED"])
if readers == 0:
    bad("no file in this tree reads rail content at all — a zero here is UNMEASURED,")
    bad("      not clean. The rule is untested because nothing exercises it.")
elif buckets["RENDERED"]:
    bad("%d file(s) read rail content from a rendered view — rendered output is not a"
        % len(buckets["RENDERED"]))
    bad("      wire format (AEF T-2872)")
else:
    ok("%d content-reading site(s) examined, all read the payload; 0 rendered readers"
       % readers)

print()
print("  %d passed, %d failed" % (npass, nfail))
sys.exit(1 if nfail else 0)
