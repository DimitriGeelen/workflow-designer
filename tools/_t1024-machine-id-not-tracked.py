#!/usr/bin/env python3
"""T-1024: this host's /etc/machine-id must not appear in any file git tracks.

WHY. The framework's secrets store derives its encryption key from the machine-id (T-939), so the
id is key material by derivation. T-939 redacted it from the vendored T-375 key-storage report on
2026-09-30; the 1.7.740 re-vendor (2659abad, 2026-10-02) restored it silently, and the same file
is in AEF's public GitHub mirror. Found by the T-1020 census. A path-based secret scanner cannot
see this (the file is a markdown report), so this checks content, for exactly one value.

NEVER PRINTS THE VALUE: it compares and prints paths only. Scope is HEAD's tracked files (what a
clone receives at the tip); history is the operator's call (rotation first, rewrite is Tier 0).

Exit 0 = absent from every tracked file; 1 = present (paths listed); 2 = cannot run.
--self-test plants the value in a scratch repo and requires a hit (the control).
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def machine_id():
    for p in ("/etc/machine-id", "/var/lib/dbus/machine-id"):
        try:
            v = open(p).read().strip()
            if len(v) >= 16:
                return v
        except OSError:
            continue
    return None


def scan(repo, needle):
    files = subprocess.run(["git", "-C", repo, "ls-files", "-z"], capture_output=True,
                           check=True).stdout.split(b"\0")
    hits, n = [], 0
    nb = needle.encode()
    for rel in files:
        if not rel:
            continue
        path = os.path.join(repo, rel.decode("utf-8", "replace"))
        try:
            if os.path.getsize(path) > 50 * 1024 * 1024:
                continue
            with open(path, "rb") as fh:
                data = fh.read()
        except OSError:
            continue
        n += 1
        if nb in data:
            hits.append(rel.decode("utf-8", "replace"))
    return n, hits


def self_test(needle):
    with tempfile.TemporaryDirectory(prefix="t1024-") as d:
        subprocess.run(["git", "init", "-q", d], check=True)
        with open(os.path.join(d, "planted.md"), "w") as fh:
            fh.write("host id: %s\n" % needle)
        with open(os.path.join(d, "clean.md"), "w") as fh:
            fh.write("nothing here\n")
        subprocess.run(["git", "-C", d, "add", "-A"], check=True)
        _, hits = scan(d, needle)
    return hits == ["planted.md"]


def main():
    needle = machine_id()
    if not needle:
        print("CANNOT RUN: no machine-id on this host")
        return 2
    if not self_test(needle):
        print("CONTROL FAILED: a planted copy was not found; a clean result below would mean nothing")
        return 2
    n, hits = scan(ROOT, needle)
    if n == 0:
        print("CANNOT RUN: no tracked files read")
        return 2
    if hits:
        print("FAIL: this host's machine-id (secrets-store key material, T-939) is in %d tracked file(s):"
              % len(hits))
        for h in hits:
            print("  %s" % h)
        print("Redact the value (never print it); history and rotation are the operator's call.")
        return 1
    print("PASS: machine-id absent from all %d tracked file(s) at HEAD (control: planted copy found)" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
