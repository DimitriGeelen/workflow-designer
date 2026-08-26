#!/usr/bin/env python3
"""T-606 — renderer output must reach the page as HTML, and file content must not.

WHAT THIS GUARDS. Watchtower has three markdown renderers. All three used to return a
plain str carrying an unwritten obligation: "the caller must mark this `| safe`". Two of
the four AC templates forgot, so /approvals served the operator 205 escaped &lt;code&gt;
against 2 real ones, and /tasks/T-XXX served the same defect latently. The obligation is
now discharged at the DEFINITION: each renderer returns markupsafe.Markup.

WHY THE LEGS LOOK LIKE THIS. The tempting fix is the dangerous one. Three of the fields on
those pages ARE renderer output; `ac.text` is RAW markdown read straight out of the task
file and never rendered at all. Marking that one `| safe` would have turned a cosmetic
defect into stored XSS in the operator's own console — so L4 exists to prove the change
moved escaping in the safe direction, and it is backed by an arm (C) that can actually
turn it red. A security assertion nothing can falsify is decoration.

The probe runs against Flask's test client rather than the live server: the arms must not
reach into the instance the operator is reading.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
FW = REPO / ".agentic-framework"
TASKS_PY = FW / "web" / "blueprints" / "tasks.py"
SHARED_PY = FW / "web" / "shared.py"
TEMPLATES = FW / "web" / "templates"

# Tasks whose ACs actually contain backticks/bold. T-604 does NOT: sampling it first is
# what produced a clean measurement over a broken page and nearly hid the second consumer.
RICH = ["T-347", "T-597", "T-344"]

ESC_CODE = "&lt;code&gt;"
ESC_STRONG = "&lt;strong&gt;"
ESC_A = "&lt;a href"


# ---------------------------------------------------------------- probe (child process)

def probe():
    """Measure inside a fresh interpreter so module-level import caching cannot mask a
    patched file. Prints one JSON object."""
    os.chdir(FW)
    sys.path.insert(0, str(FW))
    os.environ.setdefault("PROJECT_ROOT", str(REPO))
    os.environ.setdefault("FRAMEWORK_ROOT", str(FW))

    out = {"pages": {}, "renderers": {}, "security": {}}

    from markupsafe import Markup
    from web.blueprints.tasks import _render_md_inline, _render_md_block
    from web.shared import render_markdown_safe

    sample = "a `code` and **bold** and [x](/y)"
    for name, fn in (("_render_md_inline", _render_md_inline),
                     ("_render_md_block", _render_md_block),
                     ("render_markdown_safe", render_markdown_safe)):
        r = fn(sample)
        e = fn("")
        out["renderers"][name] = {
            "markup": isinstance(r, Markup),
            "markup_on_empty": isinstance(e, Markup),
            "renders_code": "<code>" in r,
        }

    # L4 subject: hostile content that a task file could legitimately contain.
    hostile = (
        "<script>alert(1)</script> "
        "<img src=x onerror=alert(2)> "
        "<a href=\"javascript:alert(3)\">click</a>"
    )
    for name, fn in (("_render_md_inline", _render_md_inline),
                     ("_render_md_block", _render_md_block),
                     ("render_markdown_safe", render_markdown_safe)):
        r = str(fn(hostile))
        out["security"][name] = {
            "raw_script": "<script>" in r,
            "raw_onerror": "onerror=" in r and "&lt;img" not in r,
            "escaped_script": "&lt;script&gt;" in r,
        }

    from web.app import app
    app.config["TESTING"] = True
    client = app.test_client()
    for path in ["/approvals"] + [f"/tasks/{t}" for t in RICH] + ["/review/T-597"]:
        resp = client.get(path)
        body = resp.get_data(as_text=True)
        out["pages"][path] = {
            "status": resp.status_code,
            "esc_code": body.count(ESC_CODE),
            "esc_strong": body.count(ESC_STRONG),
            "esc_a": body.count(ESC_A),
            "real_code": body.count("<code>"),
        }
    print(json.dumps(out))


def run_probe():
    r = subprocess.run([sys.executable, str(Path(__file__).resolve()), "--probe"],
                       capture_output=True, text=True, timeout=180, cwd=str(FW))
    if r.returncode != 0:
        return None, (r.stderr or r.stdout)[-1500:]
    line = [l for l in r.stdout.strip().split("\n") if l.startswith("{")]
    if not line:
        return None, "probe produced no JSON:\n" + r.stdout[-1500:]
    return json.loads(line[-1]), None


# ------------------------------------------------------------------------------- legs

def legs(m):
    """Return list of (name, ok, detail). One leg per property, each asserting CONTENT."""
    res = []

    # L1 — the definition owns the safety, not the caller.
    r = m["renderers"]
    ok = all(v["markup"] and v["markup_on_empty"] and v["renders_code"] for v in r.values())
    res.append(("L1 definition-site: all 3 renderers return Markup (incl. empty input)",
                ok, ", ".join(f"{k}={'Markup' if v['markup'] else 'str'}" for k, v in r.items())))

    # L2 — the outcome an operator's browser receives on the decision surface.
    p = m["pages"]["/approvals"]
    ok = p["status"] == 200 and p["esc_code"] == 0 and p["esc_strong"] == 0 and p["real_code"] > 0
    res.append(("L2 /approvals serves rendered HTML, not entities", ok,
                f"esc_code={p['esc_code']} esc_strong={p['esc_strong']} real_code={p['real_code']}"))

    # L3 — the second consumer, which a lazy sample would have missed.
    bad = {t: m["pages"][f"/tasks/{t}"] for t in RICH
           if m["pages"][f"/tasks/{t}"]["esc_code"] or m["pages"][f"/tasks/{t}"]["esc_strong"]}
    anyreal = any(m["pages"][f"/tasks/{t}"]["real_code"] > 0 for t in RICH)
    res.append(("L3 /tasks/T-XXX (latent 2nd consumer) clean on AC-rich tasks",
                not bad and anyreal,
                "clean" if not bad else f"still escaping: {bad}"))

    # L4 — the change must move escaping in the SAFE direction.
    s = m["security"]
    ok = all((not v["raw_script"]) and (not v["raw_onerror"]) and v["escaped_script"]
             for v in s.values())
    res.append(("L4 SECURITY: raw <script>/onerror/javascript: stays escaped", ok,
                ", ".join(f"{k}:{'RAW HTML LEAKED' if v['raw_script'] else 'escaped'}"
                          for k, v in s.items())))

    # L4b — static guard on the exact mistake this task nearly made.
    offenders = []
    for f in sorted(TEMPLATES.glob("*.html")):
        for i, line in enumerate(f.read_text().split("\n"), 1):
            if re.search(r"ac\.text\s*\|\s*safe", line):
                offenders.append(f"{f.name}:{i}")
    res.append(("L4b no template marks ac.text `| safe` (it is RAW file content)",
                not offenders, "none" if not offenders else " ".join(offenders)))

    # L5 — control: a page that was already correct before the fix must be unaffected.
    p = m["pages"]["/review/T-597"]
    ok = p["status"] == 200 and p["esc_code"] == 0 and p["real_code"] > 0
    res.append(("L5 control: /review (already correct pre-fix) still correct", ok,
                f"esc_code={p['esc_code']} real_code={p['real_code']}"))

    return res


# ------------------------------------------------------------------------------- arms

def unwrap_in(func_name):
    """Unwrap the Markup() at the return of ONE named function.

    _render_md_inline and _render_md_block end in byte-identical lines, so a literal
    needle cannot address one without the other — and an arm that silently poisons the
    wrong function, or both, proves something other than what it claims. Scoping the
    edit to the function's own source slice is what makes arms A and B independent.
    """
    def _patch(src):
        i = src.index(f"def {func_name}(")
        j = src.index("\ndef ", i + 1)
        seg = src[i:j]
        new = seg.replace("return Markup(_auto_link_files(html))",
                          "return _auto_link_files(html)")
        if new == seg:
            return None
        return src[:i] + new + src[j:]
    return _patch


def replace_literal(old, new):
    def _patch(src):
        if old not in src:
            return None
        return src.replace(old, new)
    return _patch


ARMS = [
    ("A unwrap Markup in _render_md_inline (AC Steps)", TASKS_PY,
     unwrap_in("_render_md_inline"), ["L2", "L3"]),
    ("B unwrap Markup in _render_md_block (AC Expected / If-not)", TASKS_PY,
     unwrap_in("_render_md_block"), ["L2", "L3"]),
    ("C disable markdown2 safe_mode (hostile HTML would survive)", TASKS_PY,
     replace_literal("markdown2.markdown(text, safe_mode='escape')",
                     "markdown2.markdown(text)"), ["L4"]),
]


def apply_arm(path, patch):
    original = path.read_text()
    patched = patch(original)
    if patched is None:
        return original, False, "needle absent — arm would have probed UNPOISONED code"
    if patched == original:
        return original, False, "patch was a no-op"
    path.write_text(patched)
    return original, True, ""


def main():
    if "--probe" in sys.argv:
        return probe()

    print("T-606 — renderer output escaping\n" + "=" * 68)
    base, err = run_probe()
    if base is None:
        print("PROBE FAILED (nothing was verified):\n" + err)
        return 1

    results = legs(base)
    for name, ok, detail in results:
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}\n         {detail}")
    live = sum(1 for _, ok, _ in results if ok)
    failed = [n for n, ok, _ in results if not ok]

    print("\npoison arms (each restores the WHOLE pre-fix state afterwards)")
    proven = 0
    arm_notes = []
    for label, path, patch, expect in ARMS:
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        original, applied, why = apply_arm(path, patch)
        if not applied:
            print(f"  [SKIP] {label}\n         {why}")
            arm_notes.append((label, False, why))
            continue
        try:
            m, e = run_probe()
            if m is None:
                reddened, detail = ["probe-crash"], "probe crashed under poison"
            else:
                pl = {n.split()[0]: ok for n, ok, _ in legs(m)}
                reddened = [k for k in expect if not pl.get(k, True)]
                detail = f"expected {expect} to redden; reddened {reddened or 'NOTHING'}"
        finally:
            path.write_text(original)
        after = hashlib.sha256(path.read_bytes()).hexdigest()
        restored = after == before
        ok = bool(reddened) and restored
        proven += 1 if ok else 0
        print(f"  [{'PROVEN' if ok else 'NOT PROVEN'}] {label}\n"
              f"         {detail}; restored={'yes' if restored else 'NO — TREE LEFT DIRTY'}")
        arm_notes.append((label, ok, detail))

    print("=" * 68)
    verdict = "PASS" if not failed and proven == len(ARMS) else "FAIL"
    print(f"{verdict} — {live}/{len(results)} live leg(s); {proven}/{len(ARMS)} arm(s) proven failable")
    if failed:
        print("failed legs: " + ", ".join(failed))
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main() or 0)
