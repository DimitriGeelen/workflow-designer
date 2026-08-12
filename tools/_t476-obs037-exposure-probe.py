#!/usr/bin/env python3
"""T-476 — measure this tree's exposure to the OBS-037 phantom-checkbox misalignment.

AEF's T-2954 (rail 588) fixed a defect in the Human-AC tick guard: `get_checkbox_states`
counts `- [ ]` lines that live inside `<!-- ... -->` guidance comments, and `detect_toggle`
zips old/new box lists POSITIONALLY. Phantoms at low indices shift every real AC's index,
so deleting a COMMENT is reported as a Human-AC tick — blocked under agent control, and
under FW_ALLOW_HUMAN_AC_TICK=1 written into the Tier-2 bypass log as a tick that never
happened. The guard can manufacture the record it exists to prevent.

This probe does NOT read the code and reason about it. It imports our own vendored guard
and RUNS it, so the verdict is behavioural.

Reports only. Exits 0 always — this is a measurement, not a gate.
"""
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUARD = os.path.join(ROOT, ".agentic-framework", "agents", "context", "check-human-ac-tick.py")


def load_guard():
    spec = importlib.util.spec_from_file_location("_fw_tick_guard", GUARD)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def phantom_census(g):
    """Whole-corpus denominator (PL-084): files whose ### Human section contains
    checkboxes that live inside HTML comments."""
    scanned = exposed = 0
    worst = 0
    for base, _dirs, files in os.walk(os.path.join(ROOT, ".tasks")):
        for fn in sorted(files):
            if not fn.endswith(".md"):
                continue
            path = os.path.join(base, fn)
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            human = g.extract_human_section(text)
            if not human:
                continue
            scanned += 1
            all_boxes = len(g.get_checkbox_states(human))
            stripped = re.sub(r"<!--.*?-->", "", human, flags=re.DOTALL)
            real_boxes = len(g.get_checkbox_states(stripped))
            phantoms = all_boxes - real_boxes
            if phantoms > 0:
                exposed += 1
                worst = max(worst, phantoms)
    return scanned, exposed, worst


def main():
    if not os.path.exists(GUARD):
        print("guard not found at %s — nothing to measure" % GUARD)
        return 0
    g = load_guard()

    print("== site: %s" % os.path.relpath(GUARD, ROOT))
    print("   comment_strip.py present: %s"
          % os.path.exists(os.path.join(ROOT, ".agentic-framework", "lib", "comment_strip.py")))

    # ---- (A) reachability, swept across the REAL corpus ---------------------------
    # First attempt used this task's own file and returned "not reachable" — because
    # T-476's ### Human section holds only the two phantoms and NO real AC, so the zip
    # compared phantom-to-phantom and saw nothing. The misalignment needs a real ticked
    # AC for the shifted index to land on. That negative was a property of the sample,
    # not of the guard. Swept over every task file instead, with the denominator stated.
    #
    # Simulated edit: the agent deletes the template's guidance comments from the Human
    # section while filling in ACs — a routine, extremely common edit that touches NO
    # checkbox.
    print("\n== (A) reachability — agent deletes guidance comments, touches no AC")
    swept = fabricating = 0
    examples = []
    for base, _dirs, files in os.walk(os.path.join(ROOT, ".tasks")):
        for fn in sorted(files):
            if not fn.endswith(".md"):
                continue
            path = os.path.join(base, fn)
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            old_h = g.extract_human_section(text)
            if not old_h:
                continue
            new_h = re.sub(r"<!--.*?-->", "", old_h, flags=re.DOTALL)
            if new_h == old_h:
                continue  # no comment to delete — not this shape
            swept += 1
            toggled, toggles = g.detect_toggle(old_h, new_h)
            if toggled:
                fabricating += 1
                if len(examples) < 3:
                    examples.append((os.path.relpath(path, ROOT), toggles))
    print("   task files where the edit is possible (Human section has comments): %d" % swept)
    print("   of those, guard reports a Human-AC TICK that never happened:        %d" % fabricating)
    if swept:
        print("   share: %.1f%%" % (100.0 * fabricating / swept))
    for p, t in examples:
        print("     e.g. %s -> %s" % (p, t))
    if fabricating:
        print("   VERDICT: FABRICATION REACHABLE in this tree. Under agent control the edit")
        print("            is BLOCKED; with FW_ALLOW_HUMAN_AC_TICK=1 log_bypass() records a")
        print("            tick that never happened — corrupting the audit trail that the")
        print("            'never tick a Human AC' constraint is enforced by.")
    else:
        print("   VERDICT: not reachable in this corpus.")

    # ---- (B) positive control: a REAL tick must still be detected -----------------
    real_old = "### Human\n- [ ] a real human AC\n"
    real_new = "### Human\n- [x] a real human AC\n"
    ctl_toggled, ctl = g.detect_toggle(real_old, real_new)
    print("\n== (B) positive control — a genuine [ ] -> [x] on a real AC")
    print("   detect_toggle -> toggled=%s toggles=%s" % (ctl_toggled, ctl))
    print("   control %s" % ("OK (probe can see a real tick)" if ctl_toggled
                             else "BROKEN — probe proves nothing"))

    # ---- (C) corpus denominator --------------------------------------------------
    scanned, exposed, worst = phantom_census(g)
    print("\n== (C) corpus exposure (PL-084 denominator)")
    print("   task files with a ### Human section: %d" % scanned)
    print("   of those, carrying phantom boxes:     %d" % exposed)
    print("   worst-case phantom count in one file: %d" % worst)
    if scanned:
        print("   share: %.1f%%" % (100.0 * exposed / scanned))
    return 0


if __name__ == "__main__":
    sys.exit(main())
