#!/usr/bin/env python3
"""_t569-card-purpose-markdown-teeth.py — a card's purpose must be readable AND safe.

THE DEFECT. `fabric_detail.html:35` rendered `{{ component.purpose }}` under Jinja
autoescape, so a markdown link written into a project-owned card came out as literal text.
Reported by 001-CashWeb-Lightspeed-Ecwid-integration, who verified it by writing a link
into a purpose and fetching the page. The card is the only project-owned surface the
Watchtower nav already reaches, so an unlinkable purpose is why AEF's own "reachable
without instructions" rule is unsatisfiable by a consumer project.

WHY TWO MUTANTS AND NOT ONE. "the link renders" is trivially satisfied by turning
autoescaping off, which would also render a card's `<script>` tag. The two legs pull in
opposite directions and each has its own mutant:

  A — revert the template to the autoescaped render  -> must redden the two RENDERING legs
      (`anchor`, `taskref`) and must NOT touch `escaped`. Both of those legs test one
      underlying property — that markdown was rendered at all — so demanding A redden
      exactly one of them would be demanding the probe misreport. What discriminates A
      from B is that A leaves the ESCAPING leg green: autoescape is, after all, safe.
  B — build the renderer with safe_mode=None          -> must redden `escaped`, ONLY that.
      The link still renders. That is the whole danger and the reason B exists: "the link
      works" is satisfied by the unsafe fix as readily as by the safe one.

A control run on unmutated source comes first, because "every mutant died" is equally
satisfied by a harness that fails on everything (T-560).

Each arm runs against a COPY of the framework in a tmpdir; nothing here mutates the tree.
The throwaway card lives in the real `.fabric/components` (that is where PROJECT_ROOT
points) and is removed on every exit path.

Exit 0 = control green and each mutant kills exactly its own leg.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARD = os.path.join(ROOT, ".fabric", "components", "t569-probe.yaml")
LEGS = ("anchor", "escaped", "nonested", "taskref")

# The purpose under test. Three properties in one string, deliberately: an explicit markdown
# link, a raw HTML tag that must NOT survive as markup, and a bare T-NNN reference that the
# shared renderer turns into an anchor with no markdown syntax at all.
PURPOSE = (
    "T569 probe. See [the index](/file/docs/reports/t569.md) for detail. "
    "Raw tag: <script>alert(1)</script>. Cross-ref T-568 by bare id."
)

RUNNER = r'''
import os, re, sys
sys.path.insert(0, os.environ["FW_DIR"])
os.chdir(os.environ["FW_DIR"])
from web.app import app
app.config["TESTING"] = True
c = app.test_client()
html = c.get("/fabric/component/t569-probe").get_data(as_text=True)

def emit(leg, ok, detail):
    print("LEG %s %s %s" % (leg, "PASS" if ok else "FAIL", detail))

# Slice to the purpose itself, so a stray anchor elsewhere on the page cannot satisfy a leg. Anchoring on the component NAME picks up a nav/header
# occurrence thousands of characters earlier and can slice PAST the text under test — a
# window that misses its target reports the same FAIL as a broken renderer.
i = html.find("T569 probe")
seg = html[i - 200:i + 1200] if i >= 0 else html

emit("anchor", '<a href="/file/docs/reports/t569.md"' in seg,
     "explicit markdown link -> anchor" if '<a href="/file/docs/reports/t569.md"' in seg
     else "no anchor; literal text present: %r" % ("[the index](" in seg))
emit("escaped", "<script>alert(1)</script>" not in html,
     "raw <script> escaped" if "<script>alert(1)</script>" not in html
     else "RAW SCRIPT TAG SURVIVED INTO THE PAGE")
emit("nonested", "<p><p>" not in seg and "<p>\n<p>" not in seg, "no nested <p>")
# A bare T-NNN ref auto-links. NOT a bare artefact path: _auto_link_files gates on
# (PROJECT_ROOT / path).exists(), and in a consumer project PROJECT_ROOT is the
# .agentic-framework directory, so no project-owned path ever resolves (OBS-305). This leg
# asserts what is TRUE here rather than what would be true in AEF's own tree.
emit("taskref", re.search(r'<a href="/tasks/T-568">T-568</a>', seg) is not None,
     "bare T-NNN ref auto-linked")
'''


def run_legs(fw_dir):
    env = dict(os.environ, FW_DIR=fw_dir, PROJECT_ROOT=ROOT)
    r = subprocess.run([sys.executable, "-c", RUNNER], env=env,
                       capture_output=True, text=True, timeout=180)
    return r.stdout + ("\n" + r.stderr if r.returncode else "")


def verdicts(out):
    v = {}
    for line in out.splitlines():
        p = line.split(None, 3)
        if len(p) >= 3 and p[0] == "LEG":
            v[p[1]] = p[2]
    return {leg: v.get(leg, "MISSING") for leg in LEGS}


def copy_fw(dst):
    shutil.copytree(os.path.join(ROOT, ".agentic-framework"), dst,
                    ignore=shutil.ignore_patterns("__pycache__", ".git"))
    return dst


def patch(path, old, new, label):
    s = open(path, encoding="utf-8").read()
    if s.count(old) != 1:
        raise SystemExit("mutant %s anchor not unique (%d)" % (label, s.count(old)))
    open(path, "w", encoding="utf-8").write(s.replace(old, new))


def main():
    npass = nfail = 0

    def report(ok, name, detail):
        nonlocal npass, nfail
        npass, nfail = (npass + 1, nfail) if ok else (npass, nfail + 1)
        print("%s  %s — %s" % ("PASS" if ok else "FAIL", name, detail))

    if os.path.exists(CARD):
        print("CANNOT RUN: %s exists — refusing to clobber it" % CARD)
        return 2
    scratch = tempfile.mkdtemp(prefix="t569-")
    try:
        with open(CARD, "w") as f:
            f.write("id: t569-probe\nname: t569-probe\ntype: script\nsubsystem: seam\n"
                    "location: tools/_t569-card-purpose-markdown-teeth.py\n"
                    "purpose: %s\n" % ("'" + PURPOSE.replace("'", "''") + "'"))

        ctl = verdicts(run_legs(os.path.join(ROOT, ".agentic-framework")))
        bad = {k: v for k, v in ctl.items() if v != "PASS"}
        if bad:
            report(False, "control: unmutated source passes all four legs", "failing: %s" % bad)
            print("\n%d passed, %d failed" % (npass, nfail))
            return 1
        report(True, "control: unmutated source passes all four legs", ", ".join(LEGS))

        # A — the shipping template: autoescaped, wrapped in its own <p>.
        fwa = copy_fw(os.path.join(scratch, "fwA"))
        patch(os.path.join(fwa, "web", "templates", "fabric_detail.html"),
              "{% if purpose_html %}{{ purpose_html | safe }}{% else %}<p>No purpose documented</p>{% endif %}",
              "<p>{{ component.purpose | default('No purpose documented') }}</p>", "A")
        va = verdicts(run_legs(fwa))
        red = [k for k, v in va.items() if v != "PASS"]
        report(sorted(red) == ["anchor", "taskref"],
               "mutant A killed (autoescaped template, as shipped)",
               "reddened %s (want both rendering legs, and NOT 'escaped')" % sorted(red))

        # B — render with safe_mode=None: the link works and the script tag lands too.
        fwb = copy_fw(os.path.join(scratch, "fwB"))
        patch(os.path.join(fwb, "web", "shared.py"),
              'markdown2.markdown(text, safe_mode="escape")',
              "markdown2.markdown(text)", "B")
        vb = verdicts(run_legs(fwb))
        red = [k for k, v in vb.items() if v != "PASS"]
        report(red == ["escaped"], "mutant B killed (safe_mode dropped)",
               "reddened %s (want ['escaped'])" % red)

        print("\n%d passed, %d failed" % (npass, nfail))
        if nfail == 0:
            print("%d/%d teeth legs passed" % (npass, npass))
        return 0 if nfail == 0 else 1
    finally:
        try:
            os.remove(CARD)
        except OSError:
            pass
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
