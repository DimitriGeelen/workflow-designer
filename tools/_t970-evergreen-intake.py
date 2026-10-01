#!/usr/bin/env python3
"""_t970-evergreen-intake — reassemble the Evergreen corpus from the hub topic.

The maps arrive as gzip bytes, base64-encoded, split across several topic posts.
`termlink channel subscribe` renders human lines rather than JSON and drops the
metadata, so parts are reassembled by OFFSET ORDER, which is the order the hub
preserves.

PRINTS A SUMMARY ONLY. The payload is ~90KB of base64 and must never be echoed
into an agent's context; everything lands on disk and only counts are reported.
"""
import base64
import gzip
import io
import os
import re
import subprocess
import sys
import tarfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "evergreen-intake")
TOPIC = "xfer-evergreen-corpus"

os.makedirs(OUT, exist_ok=True)
raw_path = os.path.join(OUT, "raw.txt")

with open(raw_path, "w") as fh:
    subprocess.run(["termlink", "channel", "subscribe", TOPIC],
                   stdout=fh, stderr=subprocess.STDOUT, check=False)

text = open(raw_path, encoding="utf-8", errors="replace").read()

# Messages render as "  [N] <sender>: <payload...>" with the payload possibly
# continuing on following lines until the next "[N]" header.
parts = re.split(r"\n(?=\s*\[\d+\]\s)", text)
msgs = []
for p in parts:
    m = re.match(r"\s*\[(\d+)\]\s+([0-9a-f]+):\s?(.*)", p, re.S)
    if m:
        msgs.append((int(m.group(1)), m.group(2), m.group(3)))

print("messages on %s: %d" % (TOPIC, len(msgs)))

B64 = re.compile(r"^[A-Za-z0-9+/=\s]+$")
chunks = []
for off, sender, payload in sorted(msgs):
    body = payload.strip()
    if len(body) > 200 and B64.match(body) and "H4sI" in body[:400] or (
            len(body) > 200 and B64.match(body) and chunks):
        chunks.append((off, re.sub(r"\s+", "", body)))

print("base64 chunks: %d (offsets %s)" % (
    len(chunks), ", ".join(str(o) for o, _ in chunks) if chunks else "-"))
if not chunks:
    print("NO BINARY PAYLOAD YET — answers may have arrived but not the maps.")
    sys.exit(0)

blob = "".join(c for _, c in chunks)
try:
    data = base64.b64decode(blob, validate=False)
except Exception as e:
    print("FAILED to base64-decode the concatenation: %s" % e)
    sys.exit(1)
print("decoded: %d bytes" % len(data))

try:
    plain = gzip.decompress(data)
except Exception as e:
    print("FAILED to gunzip: %s" % e)
    print("  (a missing or out-of-order part looks exactly like this)")
    sys.exit(1)
print("gunzipped: %d bytes" % len(plain))

corpus = os.path.join(OUT, "corpus")
os.makedirs(corpus, exist_ok=True)
try:
    tf = tarfile.open(fileobj=io.BytesIO(plain))
except Exception:
    out = os.path.join(corpus, "payload.bin")
    open(out, "wb").write(plain)
    print("not a tar; wrote %s" % out)
    sys.exit(0)

names = tf.getnames()
tf.extractall(corpus, filter="data")
bpmn = [n for n in names if n.endswith(".bpmn")]
print("EXTRACTED to %s" % corpus)
print("  entries: %d   .bpmn maps: %d" % (len(names), len(bpmn)))
for n in sorted(bpmn)[:30]:
    print("    %s" % n)
if len(bpmn) > 30:
    print("    ... and %d more" % (len(bpmn) - 30))
