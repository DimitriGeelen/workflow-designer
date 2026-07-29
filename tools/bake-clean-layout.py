#!/usr/bin/env python3
"""bake-clean-layout — bake the editor's Clean layout into the corpus (T-101).

The rendered corpus (examples/aef-processes/rendered/*.bpmn) is machine-generated
by tools/yaml-to-bpmn.py, which copies each node's x/y and each lane's height
straight from the *.workflow.yaml source. Nobody hand-placed those nodes, so the
editor's Tidy/Clean standard finds most of them untidy (T-100 messiness). This
tool bakes Clean in ONCE so the shipped corpus is already tidy.

Design (why this shape):
  * The committed rendered/*.bpmn are EDITOR-SAVED dialect (T-288): editor node
    ids, bpmndi DI, hand-carried aef:meta notes. The bake writes back the
    editor's own buildBpmnXml() from the same session that ran Clean — it NEVER
    regenerates via yaml-to-bpmn.py (T-300 / G-012: the regen emits a different
    projection and clobbers ids, DI, and notes corpus-wide).
  * The bake does NOT touch the *.workflow.yaml sources. Since T-125 lane
    compaction, editor-state y is lane-relative — patching it into the YAML's
    absolute-y fields breaks the lane-band convention (check-lane-bands.py).
    And with regen forbidden (G-012), YAML geometry is no longer load-bearing:
    the YAML is the SEMANTIC source, rendered/*.bpmn the visual truth.
  * Maps tracked in .editor-versions/ (the T-145 adopt gate: rendered must equal
    the latest store save) get a new store version minted on byte change, with
    an honest post-Clean thumbnail from the same editor session.
  * Clean = cleanLayout(), which lives ONLY in the editor JS. We reuse it verbatim
    by running the real editor headless (tools/_clean-layout-cdp.mjs) — we never
    reimplement Tidy in Python (PL-005: editor/bridge drift on shared logic).
  * The YAML patch is line-surgical: only the specific `y:`/`x:`/`height:` numbers
    that Clean changed are rewritten; every other byte (comments, key order,
    quoting, flow-style io) is left exactly as-is, so the diff is the geometry
    delta and nothing else.

Re-run after Clean logic changes:  tools/bake-clean-layout.py
Check the corpus is a Clean fixpoint (idempotent, no writes):  --check

Usage:
  tools/bake-clean-layout.py [--check] [map ...]
    (no map args → all 24 rendered maps)
"""
import base64
import json
import os
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "examples", "aef-processes")
RENDERED = os.path.join(CORPUS, "rendered")
GALLERY = os.path.join(ROOT, "build", "gallery", "rendered")
DRIVER = os.path.join(ROOT, "tools", "_clean-layout-cdp.mjs")
MESSINESS_MAX = 3  # T-100 CLEAN_NUDGE_MIN — a clean map scores < 3


def run_driver(maps):
    """Run the headless editor over the given maps; return {map: result}."""
    cmd = ["node", DRIVER] + maps
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit("clean-layout driver failed (exit %d)" % proc.returncode)
    return json.loads(proc.stdout)


def mint_store_version(base, xml, thumb_data_url):
    """Append a new .editor-versions/<base>/ version when the baked bytes differ.

    Keeps the T-145 adopt gate true (rendered == latest store save) after a
    re-bake, with the same provenance shape the editor's "Save to project"
    writes: v<N>.bpmn + v<N>.png thumbnail + index.json entry. No-op for maps
    without a store dir, and idempotent (byte-equal latest → nothing minted).
    Returns the minted version number, or None.
    """
    store = os.path.join(ROOT, ".editor-versions", base)
    idx_path = os.path.join(store, "index.json")
    if not os.path.exists(idx_path):
        return None
    with open(idx_path) as fh:
        idx = json.load(fh)
    latest = max(e["v"] for e in idx)
    with open(os.path.join(store, "v%d.bpmn" % latest), "rb") as fh:
        if fh.read() == xml.encode():
            return None
    v = latest + 1
    with open(os.path.join(store, "v%d.bpmn" % v), "w") as fh:
        fh.write(xml)
    entry = {"v": v, "ts": int(time.time() * 1000),
             "note": "T-300 dialect-preserving Clean re-bake", "bytes": len(xml.encode())}
    if thumb_data_url and thumb_data_url.startswith("data:image/png;base64,"):
        with open(os.path.join(store, "v%d.png" % v), "wb") as fh:
            fh.write(base64.b64decode(thumb_data_url.split(",", 1)[1]))
        entry["thumb"] = "v%d.png" % v
    idx.append(entry)
    with open(idx_path, "w") as fh:
        json.dump(idx, fh, indent=2)
    return v


def write_back(base, xml):
    """Write the editor's own serialized XML → rendered/<base>.bpmn, mirror to gallery.

    T-300 (G-012): the committed corpus is EDITOR-SAVED dialect (T-288) — editor
    node ids, bpmndi DI, hand-carried aef:meta notes. The bake therefore writes
    back buildBpmnXml() output from the same editor session that ran Clean,
    NEVER a yaml-to-bpmn.py regen (which emits a different projection and
    clobbers all of the above — the G-012 incident, 2026-07-29).
    """
    out = os.path.join(RENDERED, base + ".bpmn")
    with open(out, "w") as fh:
        fh.write(xml)  # byte-verbatim editor output (no trailing-newline massage)
    shutil.copyfile(out, os.path.join(GALLERY, base + ".bpmn"))


def all_maps():
    return sorted(b[:-len(".bpmn")] for b in os.listdir(RENDERED) if b.endswith(".bpmn"))


def main(argv):
    check = "--check" in argv
    names = [a for a in argv if not a.startswith("--")]
    maps = names or all_maps()

    results = run_driver(maps)

    # Report table.
    bad = 0
    print("%-28s %6s %6s %8s %8s" % ("map", "moved", "iters", "messy→", "→messy"))
    for base in maps:
        r = results.get(base, {})
        if not r.get("ok"):
            print("  %-26s  ERROR: %s" % (base, r.get("error", "no result")))
            bad += 1
            continue
        warn = "  ⚠ not converged" if r.get("lastMoved", 0) != 0 else ""
        print("  %-26s %5d %6s %8s %8s%s" % (
            base, r["moved"], r.get("iters", "?"),
            r["messinessBefore"], r["messinessAfter"], warn))

    if check:
        # Fixpoint check: an already-baked corpus moves nothing and is not messy.
        fail = 0
        for base in maps:
            r = results.get(base, {})
            if not r.get("ok"):
                fail += 1
                continue
            # The bake contract is FILE-LEVEL: re-running the bake must produce
            # byte-identical output. In-state metrics (moved/netMoved) are
            # unreliable proxies — adoptImportedXml normalizes coordinates on
            # import, so transient/net movement can be nonzero while the
            # serialization is byte-stable (T-300: audit-process +
            # error-escalation-ladder). Compare the editor's post-Clean
            # serialization against the committed bytes directly.
            with open(os.path.join(RENDERED, base + ".bpmn")) as fh:
                on_disk = fh.read()
            byte_stable = r.get("xml") is not None and r["xml"] == on_disk
            if not byte_stable or r["messinessBefore"] >= MESSINESS_MAX:
                print("  NOT A FIXPOINT: %s (byte_stable=%s moved=%s messinessBefore=%s)"
                      % (base, byte_stable, r["moved"], r["messinessBefore"]))
                fail += 1
        print("\n--check: %d/%d maps are a Clean fixpoint"
              % (len(maps) - fail, len(maps)))
        return 1 if fail else 0

    if bad:
        raise SystemExit("driver returned errors for %d map(s); aborting bake" % bad)

    # Bake: write back editor-saved XML, mirror, mint store versions (T-145).
    minted = 0
    for base in maps:
        r = results[base]
        if not r.get("xml"):
            raise SystemExit("driver returned no xml for %s (buildBpmnXml missing?); aborting bake" % base)
        write_back(base, r["xml"])
        m = mint_store_version(base, r["xml"], r.get("thumb"))
        minted += 1 if m else 0
        print("  baked %-24s%s" % (base, "  (store v%d minted)" % m if m else ""))
    print("\nBaked Clean into %d maps; %d store versions minted; gallery mirror synced."
          % (len(maps), minted))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
