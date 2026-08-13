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
    (no map args → every map derived from examples/aef-processes/*.workflow.yaml)

Refusal (T-447): this tool exits 2 rather than reporting on a corpus it could not
enumerate — no sources, a rendered set missing counterparts, or a named map that does
not exist. Until T-447 it printed `Baked Clean into 0 maps; ...; gallery mirror synced.`
and `--check: 0/0 maps are a Clean fixpoint` at exit 0, and T-101 reads that exit code.
The denominator is never written down as a number here; it is derived from the sources,
because a restated one goes stale the day the corpus grows (PL-158).
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


def refuse(msg):
    """Stop without a verdict. Exit 2, never 0, never 1.

    2 is deliberate and is the T-430 abstention discipline: 1 means "I looked and it is
    bad", 0 means "I looked and it is fine", and a run that examined nothing is neither.
    Collapsing it into 0 is the defect this whole repair exists for (T-440, G-034);
    collapsing it into 1 would send someone hunting for a corpus defect that is not there.
    """
    sys.stderr.write("REFUSING: " + msg + "\nNothing was examined; this is not a pass.\n")
    raise SystemExit(2)


def _basenames(d, suffix):
    if not os.path.isdir(d):
        refuse("%s does not exist, so the corpus cannot be enumerated." % os.path.relpath(d, ROOT))
    return sorted(b[:-len(suffix)] for b in os.listdir(d) if b.endswith(suffix))


def sources():
    """The AUTHORITY the rendered corpus is measured against.

    Not a constant. The docstring used to state the denominator as prose — "all 24 rendered
    maps" — and a guard that restates it as `24` rots the day the corpus grows to 25, which
    is PL-158 (T-444): derive the checked set from the authority you guard, never restate it.
    rendered/*.bpmn is generated one-for-one from these sources, so the source set IS the
    denominator and it stays correct without anyone maintaining it.
    """
    return _basenames(CORPUS, ".workflow.yaml")


def all_maps():
    return _basenames(RENDERED, ".bpmn")


def resolve_corpus(names):
    """Return the maps to operate on, or refuse and say what was examined.

    Every path out of here either hands back a non-empty corpus or exits 2. There is no
    route by which an empty corpus reaches a verdict — which was the bug: `--check` over
    zero maps printed `0/0 maps are a Clean fixpoint` and returned 0, and T-101 reads that
    exit code. A fixpoint assertion over an empty set is vacuously true (PL-081).
    """
    rendered = all_maps()

    # An explicitly named map that does not exist must be refused BY NAME. Previously
    # `maps = names or all_maps()` passed the names straight through, so a typo shrank the
    # corpus to whatever happened to match and the run reported success over the remainder.
    if names:
        missing = [n for n in names if n not in rendered]
        if missing:
            refuse("named map(s) not present in %s: %s. Named %d, %d exist — a typo must "
                   "not silently shrink the corpus to the names that happen to match."
                   % (os.path.relpath(RENDERED, ROOT), ", ".join(missing),
                      len(names), len(names) - len(missing)))
        return names

    src = sources()
    if not src:
        refuse("no *.workflow.yaml sources under %s, so there is no denominator to check "
               "the rendered corpus against." % os.path.relpath(CORPUS, ROOT))

    # The partial case, which is the one a zero-guard alone would miss: 3 rendered against
    # 24 sources is not "3 maps are a fixpoint", it is a corpus that quietly lost 21.
    lost = [b for b in src if b not in rendered]
    if lost:
        refuse("%d of %d source(s) have no rendered counterpart under %s: %s. A verdict "
               "over the %d that survive would report on a corpus that shrank."
               % (len(lost), len(src), os.path.relpath(RENDERED, ROOT),
                  ", ".join(lost[:5]) + (" ..." if len(lost) > 5 else ""), len(rendered)))

    return rendered


def main(argv):
    check = "--check" in argv
    names = [a for a in argv if not a.startswith("--")]
    maps = resolve_corpus(names)

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
                # T-448: name WHICH subsystem is implicated. This gate fails for two
                # unrelated reasons and used to print one sentence for both. Measured
                # 2026-08-13: all 24 maps read `NOT A FIXPOINT ... moved=0
                # messinessBefore=0` — the layout algorithm moved nothing and nothing was
                # messy, so the layout was already a fixpoint and only the SERIALIZATION
                # differed (exporter= identity from T-399, DI comment rewording from
                # T-361, neither ever re-baked). A reader trusting the gate's name would
                # have gone into the layout engine looking for a byte problem.
                #
                # The distinction is mechanical, not cosmetic: layout drift means re-run
                # the bake, serialization drift means the emitter changed under a corpus
                # nobody re-baked, and those have different owners and different risk.
                layout_bad = r["moved"] != 0 or r["messinessBefore"] >= MESSINESS_MAX
                if layout_bad and not byte_stable:
                    why = "LAYOUT+SERIALIZATION"
                elif layout_bad:
                    why = "LAYOUT (geometry moved or map is messy — re-run the bake)"
                else:
                    why = ("SERIALIZATION ONLY (layout is already a fixpoint: moved=0, "
                           "not messy — the emitter changed under a corpus that was never "
                           "re-baked; diff the committed bytes against the re-emission "
                           "before touching the layout engine)")
                print("  NOT A FIXPOINT: %s [%s] (byte_stable=%s moved=%s messinessBefore=%s)"
                      % (base, why, byte_stable, r["moved"], r["messinessBefore"]))
                fail += 1
        # Name the scope in the verdict line. `0/0 maps are a Clean fixpoint` was a true
        # sentence about nothing, and printing the denominator it was drawn from is what
        # makes the difference between "clean" and "empty" visible to a reader (PL-084).
        scope = ("%d named map(s)" % len(maps)) if names else ("all %d source(s)" % len(sources()))
        print("\n--check: %d/%d maps are a Clean fixpoint  [scope: %s]"
              % (len(maps) - fail, len(maps), scope))
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
    scope = ("%d named map(s)" % len(maps)) if names else ("all %d source(s)" % len(sources()))
    print("\nBaked Clean into %d maps; %d store versions minted; gallery mirror synced."
          "  [scope: %s]" % (len(maps), minted, scope))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
