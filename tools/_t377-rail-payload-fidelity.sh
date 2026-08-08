#!/usr/bin/env bash
# _t377-rail-payload-fidelity.sh — does the termlink rail deliver payload bytes verbatim?
#
# WHY THIS EXISTS. I delivered a frozen 7905-byte standard to AEF as rail message text.
# Their extraction hashed 7906 B — one appended newline. The content was byte-perfect
# (trimming one byte reproduced the named sha256, which a one-byte edit cannot reach by
# chance), so the delta was pure transport. Their diagnosis was "the rail transport
# appended one". That named ONE of at least four stages — my send, hub storage, hub read,
# their decode-and-save — from a SINGLE observation, and I was about to repeat it onward.
#
# WHAT THIS MEASURES. Post a payload of known bytes, read it back off the hub, compare.
# That covers send -> storage -> read on this side. It cannot see the peer's decode step,
# and this script does not claim to.
#
# WHY SEVERAL SHAPES. One transfer of one payload is one sample. The observed direction
# (append) is the RECOVERABLE one: a receiver can trim and re-hash, and a match on a named
# sha is proof. The dangerous direction is STRIPPING — a channel that eats trailing
# whitespace leaves a receiver no way to know how many bytes to restore, and no one-byte
# repair that proves anything. A payload that already ends in newlines cannot show a strip
# at all if the channel also appends. So the shapes deliberately include one ending in no
# newline and one ending in spaces, where both directions are visible and distinguishable.
#
# TEETH. A comparator that always reports VERBATIM would pass over every defect it exists
# to find. Leg T feeds it two payloads that genuinely differ and requires it to say so.
#
# POPULATION. If the hub is unreachable, zero transfers complete and every shape is
# trivially "not observed to mutate". That is the empty-denominator failure this project
# has now hit twice, so a run that completes no transfers FAILS rather than passing.
#
# Usage: bash tools/_t377-rail-payload-fidelity.sh
# Exit 0 = every attempted transfer round-tripped verbatim, over a non-empty population,
#          with the comparator proven able to report a difference.

set -uo pipefail

TOPIC="${T377_TOPIC:-t377-fidelity-probe}"

command -v termlink >/dev/null 2>&1 || { echo "  FAIL  termlink CLI not on PATH — cannot measure"; exit 1; }

python3 - "$TOPIC" <<'PY'
import base64, hashlib, json, subprocess, sys

topic = sys.argv[1]
npass = nfail = 0

def ok(m):
    global npass; npass += 1; print("  PASS  " + m)

def bad(m):
    global nfail; nfail += 1; print("  FAIL  " + m)

def digest(b):
    return hashlib.sha256(b).hexdigest()

# The shapes. Names describe the TRAILING bytes, because that is where both the observed
# mutation and its unrecoverable inverse live.
SHAPES = [
    ("two-trailing-newlines", b"alpha\nbeta\n\n"),          # the standard's own ending
    ("no-trailing-newline",   b"alpha\nbeta"),              # append is visible here
    ("trailing-spaces",       b"alpha\nbeta   "),           # strip is visible here
    ("crlf-line-endings",     b"alpha\r\nbeta\r\n"),        # CR is a classic casualty
    ("utf8-multibyte-tail",   "alpha\nβγ—✓\n".encode("utf-8")),
]

def post(raw):
    """Post raw bytes via the CLI's stdin path. Returns offset, or None."""
    p = subprocess.run(
        ["termlink", "channel", "post", topic, "--ensure-topic", "--json"],
        input=raw, capture_output=True, timeout=60,
    )
    if p.returncode != 0:
        return None, (p.stderr or b"").decode("utf-8", "replace").strip()[:200]
    try:
        out = json.loads(p.stdout.decode("utf-8", "replace"))
    except Exception:
        return None, "post returned non-JSON: " + p.stdout.decode("utf-8", "replace")[:120]
    # The hub answers {"delivered": {"offset": N, "ts": ...}}; accept a bare "offset"
    # too rather than pinning the one shape observed today.
    off = out.get("offset")
    if off is None:
        for k in ("delivered", "result", "data"):
            if isinstance(out.get(k), dict) and "offset" in out[k]:
                off = out[k]["offset"]
                break
    if off is None:
        return None, "post JSON carried no offset: " + json.dumps(out)[:160]
    return int(off), None

def fetch(off):
    """Read one envelope back off the hub and return its raw payload bytes."""
    p = subprocess.run(
        ["termlink", "channel", "subscribe", topic, "--cursor", str(off), "--limit", "1", "--json"],
        capture_output=True, timeout=60,
    )
    if p.returncode != 0:
        return None, (p.stderr or b"").decode("utf-8", "replace").strip()[:200]
    lines = [l for l in p.stdout.decode("utf-8", "replace").splitlines() if l.strip()]
    if not lines:
        return None, "subscribe returned no envelope at offset %d" % off
    env = json.loads(lines[0])
    if env.get("offset") != off:
        return None, "subscribe returned offset %s, asked for %d" % (env.get("offset"), off)
    if "payload_b64" not in env:
        return None, "envelope carried no payload_b64"
    return base64.b64decode(env["payload_b64"]), None


def classify(sent, got):
    """Name the relationship. Deliberately NOT a boolean — 'differs' is the answer that
    hides which direction, and the direction is the whole finding."""
    if sent == got:
        return "VERBATIM", ""
    if got.startswith(sent):
        return "APPENDED", "+%d byte(s): %r" % (len(got) - len(sent), got[len(sent):])
    if sent.startswith(got):
        return "STRIPPED", "-%d byte(s): %r" % (len(sent) - len(got), sent[len(got):])
    return "CHANGED", "sent %d B %s / got %d B %s" % (
        len(sent), digest(sent)[:8], len(got), digest(got)[:8])


# --- teeth: the comparator must be able to report a difference --------------------
# Without this, a classify() that returned VERBATIM unconditionally would make every
# shape below green and the run would certify a fidelity it never measured.
t_kind, _ = classify(b"alpha", b"gamma")
if t_kind != "VERBATIM":
    ok("teeth: comparator reports %s on two unrelated payloads" % t_kind)
else:
    bad("teeth: comparator called two different payloads VERBATIM — it discriminates")
    bad("      nothing and no result below can be read")

t_kind2, t_det = classify(b"abc", b"abc\n")
if t_kind2 == "APPENDED":
    ok("teeth: a one-byte trailing append is classified APPENDED (%s)" % t_det)
else:
    bad("teeth: a one-byte trailing append classified %s — the exact mutation this" % t_kind2)
    bad("      probe exists to catch would be misreported")

t_kind3, _ = classify(b"abc\n", b"abc")
if t_kind3 == "STRIPPED":
    ok("teeth: a one-byte trailing loss is classified STRIPPED — the unrecoverable")
    ok("      direction is reachable, so a clean run is evidence about it")
else:
    bad("teeth: a trailing loss classified %s — the strip direction is unreachable and" % t_kind3)
    bad("      a green below would say nothing about it")

# --- the measurement -------------------------------------------------------------
attempted = completed = verbatim = 0
for name, raw in SHAPES:
    attempted += 1
    off, err = post(raw)
    if off is None:
        bad("%-22s post failed: %s" % (name, err))
        continue
    got, err = fetch(off)
    if got is None:
        bad("%-22s read-back failed: %s" % (name, err))
        continue
    completed += 1
    kind, detail = classify(raw, got)
    if kind == "VERBATIM":
        verbatim += 1
        ok("%-22s %4d B round-tripped VERBATIM (sha %s, offset %d)"
           % (name, len(raw), digest(raw)[:8], off))
    else:
        bad("%-22s %4d B came back %s — %s" % (name, len(raw), kind, detail))

# --- population ------------------------------------------------------------------
# n is printed with the verdict, not buried: "no shape mutated" over zero completed
# transfers is the same sentence as full fidelity, and they are not the same fact.
print()
print("  n = %d of %d shapes completed a round trip; %d verbatim" % (completed, attempted, verbatim))
if completed == 0:
    bad("zero transfers completed — nothing was measured. A clean report here would be")
    bad("      an empty denominator, not fidelity.")
elif completed < attempted:
    bad("%d shape(s) never completed a transfer — they are UNMEASURED, not clean"
        % (attempted - completed))
else:
    ok("every shape attempted completed a transfer — the population is whole")

print()
print("  %d passed, %d failed" % (npass, nfail))
sys.exit(1 if nfail else 0)
PY
