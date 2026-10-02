#!/usr/bin/env python3
"""_t989-intake-evergreen — reassemble one Evergreen delivery from a hub topic (T-989).

Generalises _t970-evergreen-intake (which was fixed to iteration 0's offsets). Reads the topic as
JSON, keeps `artifact-chunk` envelopes from SENDER whose metadata `file` matches --file, takes the
LATEST complete set of parts (a resend supersedes an earlier one), orders by part number, decodes
base64, checks the sha256 the sender declared (metadata `sha256`, or a manifest note), and unpacks
a .tgz/.tar.gz under build/evergreen-intake/<label>/ (gitignored: their corpus is never committed).

PRINTS A SUMMARY ONLY. Payloads are never echoed into an agent's context.

  python3 tools/_t989-intake-evergreen.py --list                    # what deliveries exist
  python3 tools/_t989-intake-evergreen.py --file <name> --label iter1
"""
import argparse
import base64
import collections
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tarfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SENDER = "90d4553895d5a9a6"  # aef-greenfield-test
TOPICS = ["xfer-evergreen-corpus", "xfer-evergreen-kit", "dm:90d4553895d5a9a6:d1993c2c3ec44c94"]


def envelopes(topic):
    out, cursor = [], 0
    while True:  # the hub returns at most 1000 per call: page until empty
        r = subprocess.run(["termlink", "channel", "subscribe", topic, "--json", "--limit", "1000",
                            "--cursor", str(cursor)], capture_output=True, text=True, timeout=60)
        page = []
        for line in r.stdout.splitlines():
            try:
                page.append(json.loads(line))
            except ValueError:
                pass
        page = [e for e in page if isinstance(e.get("offset"), int) and e["offset"] >= cursor]
        if not page:
            return out
        out += page
        cursor = max(e["offset"] for e in page) + 1


def part_no(p):
    m = re.match(r"\s*(\d+)\s*/\s*(\d+)", str(p or ""))
    return (int(m.group(1)), int(m.group(2))) if m else (None, None)


def chunks(topics):
    by_file = collections.defaultdict(list)
    for t in topics:
        for e in envelopes(t):
            md = e.get("metadata") or {}
            if e.get("sender_id") == SENDER and e.get("msg_type") == "artifact-chunk" and md.get("file"):
                by_file[md["file"]].append((t, e))
    return by_file


def latest_set(items):
    """Walk newest to oldest and keep the first occurrence of each part number until complete."""
    items = sorted(items, key=lambda te: te[1].get("ts", 0), reverse=True)
    got, total, sha = {}, None, None
    for t, e in items:
        n, of = part_no(e["metadata"].get("part"))
        if n is None:
            continue
        if total is None:
            total, sha = of, e["metadata"].get("sha256")
        if of != total or n in got:
            continue
        got[n] = e
        if len(got) == total:
            break
    return got, total, sha


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--file")
    ap.add_argument("--label")
    ap.add_argument("--sha256", help="expected sha256 if the sender declared it outside the chunk metadata")
    a = ap.parse_args()
    by_file = chunks(TOPICS)
    if a.list or not a.file:
        for f, items in sorted(by_file.items()):
            got, total, sha = latest_set(items)
            topics = sorted({t for t, _ in items})
            print("%-40s parts %s/%s  sha256 %s  on %s" % (f, len(got), total, (sha or "-")[:16], ",".join(topics)))
        return 0
    if a.file not in by_file:
        sys.exit("no artifact-chunk named %r from %s" % (a.file, SENDER))
    got, total, sha = latest_set(by_file[a.file])
    if len(got) != total:
        sys.exit("INCOMPLETE: %d of %s parts of %s (missing %s)" % (len(got), total, a.file,
                 sorted(set(range(1, (total or 0) + 1)) - set(got))))
    blob = b""
    for n in sorted(got):
        e = got[n]
        b64 = e.get("payload_b64") or ""
        raw = base64.b64decode(b64)
        if e["metadata"].get("encoding") == "base64":  # the payload itself is base64 text
            raw = base64.b64decode(raw)
        blob += raw
    digest = hashlib.sha256(blob).hexdigest()
    want = a.sha256 or sha
    ok = (want is None) or digest.startswith(want) or want.startswith(digest[:len(want)])
    label = a.label or re.sub(r"\W+", "-", a.file)
    out = os.path.join(ROOT, "build", "evergreen-intake", label)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, a.file), "wb") as fh:
        fh.write(blob)
    print("%s: %d parts, %d bytes, sha256 %s %s" % (a.file, total, len(blob), digest[:16],
          "MATCHES" if want and ok else ("NO DECLARED SHA" if not want else "MISMATCH (declared %s)" % want[:16])))
    if want and not ok:
        return 1
    if re.search(r"\.(tgz|tar\.gz|tar)$", a.file):
        with tarfile.open(fileobj=io.BytesIO(blob)) as tf:
            safe = [m for m in tf.getmembers() if not (m.name.startswith("/") or ".." in m.name.split("/"))]
            tf.extractall(os.path.join(out, "unpacked"), members=safe)
        n_bpmn = sum(1 for _, _, fs in os.walk(os.path.join(out, "unpacked")) for f in fs if f.endswith(".bpmn"))
        print("unpacked %d member(s) to %s (%d .bpmn)" % (len(safe), os.path.relpath(out, ROOT) + "/unpacked", n_bpmn))
    return 0


if __name__ == "__main__":
    sys.exit(main())
