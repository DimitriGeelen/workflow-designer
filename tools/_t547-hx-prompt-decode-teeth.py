#!/usr/bin/env python3
"""T-547 teeth — an operator's rationale must be stored as the operator wrote it.

Two Watchtower routes take a policy-decision rationale from the browser through
htmx's `hx-prompt` and store it as the audit record:

    web/blueprints/bvp.py  bvp_driver_remove   (SOVEREIGN — a policy edit)
    web/blueprints/bvp.py  bvp_driver_reject   (a queue decision)

XHR forbids non-ASCII header values, so htmx (htmx.min.js, `Cn`) retries a
rejected setRequestHeader with `encodeURIComponent` and sets a companion
`HX-Prompt-URI-AutoEncoded: true` to declare that it did. Reading `HX-Prompt`
raw therefore files `%E2%80%94` as the operator's words. Measured on the live
ledger before the fix, three rejections read:

    "rationale_decision": "Reject%20rationale%20(%E2%89%A530%20chars%20..."

One em-dash, curly apostrophe or accented letter is enough to trigger it, and a
pure-ASCII rationale round-trips fine — which is why it went unseen.

The probe pins BOTH directions, because fixing one half creates the other:

  A. encoded + companion header  -> stored DECODED (the defect)
  B. literal percent, no header  -> stored VERBATIM (the over-correction: an
     unconditional unquote() silently turns a rationale a human typed as
     "covers 50%20 of cases" into "covers 50  of cases")

and the ORDERING, because a decode applied after the length gate leaves the
gate measuring the inflated encoded form (leg 3).

HERMETIC BY CONSTRUCTION: the ledger writer and the proposal reader are stubbed
so no row is appended to `.context/bvp-driver-proposals.jsonl` and no `bin/fw`
subprocess runs. The decode path under test is the real one; only the I/O at
the far end is captured. A probe that writes to an append-only audit file to
prove the audit file is written correctly would be its own defect.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import sys
from pathlib import Path
from urllib.parse import quote

ROOT = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FW = ROOT / ".agentic-framework"
HTMX_JS = FW / "web" / "static" / "htmx.min.js"
BVP_PY = FW / "web" / "blueprints" / "bvp.py"

TOKEN = "t547-probe-token"

# A rationale an operator plausibly types, carrying the three characters that
# actually trigger htmx's encode path: em-dash, curly apostrophe, ≥.
UNICODE_RATIONALE = (
    "Superseded — the driver’s axis is already covered, and its weight "
    "is ≥ the chassis it competes with"
)
# Pure ASCII, so htmx sends it UNENCODED with no companion header. The percent
# escape here is the operator's literal text, not an encoding.
LITERAL_PERCENT = "covers 50%20 of cases in the current corpus sample"
# Decodes to 26 characters — under the R6 floor. Its ENCODED form is 44, so a
# gate that runs before the decode waves it through. Both figures are asserted
# below rather than trusted from this comment.
SHORT_WHEN_DECODED = "too terse — no real reason"


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def main():
    if not HTMX_JS.is_file():
        refuse("%s not found — the encode contract cannot be re-read" % HTMX_JS)

    # ── Leg 5 first: the premise. Everything below assumes htmx declares its
    #    own encoding via a companion header. If a future htmx drops that, the
    #    conditional decode is unreachable and every other leg would go green
    #    while the defect returned. That must REFUSE, not pass.
    htmx_src = HTMX_JS.read_text(encoding="utf-8", errors="replace")
    if "-URI-AutoEncoded" not in htmx_src or "encodeURIComponent" not in htmx_src:
        refuse("htmx.min.js no longer contains the `-URI-AutoEncoded` companion "
               "header mechanism this fix is built on. The conditional decode "
               "in _hx_prompt() may now be dead code and the routes may be "
               "storing raw bytes again — re-derive before trusting a green.")

    if len(SHORT_WHEN_DECODED) >= 30:
        refuse("SHORT_WHEN_DECODED is %d chars, not <30 — leg 3 would be "
               "vacuous" % len(SHORT_WHEN_DECODED))
    if len(quote(SHORT_WHEN_DECODED)) < 30:
        refuse("SHORT_WHEN_DECODED encodes to %d chars — leg 3 only "
               "discriminates if the ENCODED form clears the 30-char floor "
               "that the DECODED form fails"
               % len(quote(SHORT_WHEN_DECODED)))

    sys.path.insert(0, str(FW))
    os.environ["PROJECT_ROOT"] = str(ROOT)
    try:
        from web.app import create_app
        from web.blueprints import bvp as bvp_mod
    except Exception as exc:                                # noqa: BLE001
        refuse("could not import the app under test: %s" % exc)

    app = create_app()
    app.config["TESTING"] = True
    c = app.test_client()
    with c.session_transaction() as s:
        s["_csrf_token"] = TOKEN

    failures = []
    stored = {}          # what the route handed the ledger writer
    argv = {}            # what the route handed the fw CLI

    class _FakeRun:
        returncode = 0
        stdout = "driver removed"
        stderr = ""

    def fake_append(pid, state, rationale_decision=None):
        stored["id"], stored["state"] = pid, state
        stored["rationale"] = rationale_decision
        return True

    def fake_load(state_filter="pending"):
        return [{"id": "P-deadbeef", "name": "V_PROBE", "weight": 1,
                 "state": "pending"}]

    def fake_subprocess_run(cmd, **kw):
        argv["cmd"] = list(cmd)
        return _FakeRun()

    bvp_mod._append_proposal_state_change = fake_append
    bvp_mod._load_proposals = fake_load
    bvp_mod.subprocess.run = fake_subprocess_run

    def post_reject(rationale, encoded):
        stored.clear()
        h = {"X-CSRF-Token": TOKEN}
        h["HX-Prompt"] = quote(rationale) if encoded else rationale
        if encoded:
            h["HX-Prompt-URI-AutoEncoded"] = "true"
        return c.post("/api/bvp/driver/reject?id=P-deadbeef", headers=h)

    # ── Leg 1 — the defect: encoded in, operator's own text stored.
    r = post_reject(UNICODE_RATIONALE, encoded=True)
    if r.status_code != 200:
        refuse("reject route returned %d on a well-formed encoded rationale "
               "(%s) — the stimulus leg 1 depends on is gone, which is not a "
               "pass" % (r.status_code, r.get_data(as_text=True)[:120]))
    if stored.get("rationale") != UNICODE_RATIONALE:
        failures.append(
            "leg1 (reject, %s): stored %r, operator wrote %r. htmx declared "
            "the encoding via HX-Prompt-URI-AutoEncoded and the route filed "
            "the encoded bytes as the audit record."
            % ("SOVEREIGN-adjacent", stored.get("rationale"),
               UNICODE_RATIONALE))

    # ── Leg 2 — the over-correction: a literal percent must survive.
    r = post_reject(LITERAL_PERCENT, encoded=False)
    if r.status_code != 200:
        refuse("reject route returned %d on a plain ASCII rationale — leg 2 "
               "cannot distinguish decode-always from decode-when-declared"
               % r.status_code)
    if stored.get("rationale") != LITERAL_PERCENT:
        failures.append(
            "leg2: stored %r, operator wrote %r. htmx sent this UNENCODED (no "
            "companion header) because it is pure ASCII; decoding it anyway "
            "destroys a percent sign the operator typed."
            % (stored.get("rationale"), LITERAL_PERCENT))

    # ── Leg 3 — ordering: the R6 floor must measure the decoded rationale.
    r = post_reject(SHORT_WHEN_DECODED, encoded=True)
    if r.status_code != 400:
        failures.append(
            "leg3: a rationale that decodes to %d characters was accepted "
            "(HTTP %d, stored=%r). The ≥30 floor is measuring the %d-character "
            "ENCODED form, so percent-encoding inflates any rationale past the "
            "gate it exists to enforce."
            % (len(SHORT_WHEN_DECODED), r.status_code, stored.get("rationale"),
               len(quote(SHORT_WHEN_DECODED))))

    # ── Leg 4 — the Sovereign route. Same header, same defect class, and here
    #    the rationale is the record of an actual policy edit. The fw CLI is
    #    captured rather than run: this probe must not edit the driver register.
    argv.clear()
    r = c.post("/api/bvp/driver/remove?driver=F-PROBE",
               headers={"X-CSRF-Token": TOKEN,
                        "HX-Prompt": quote(UNICODE_RATIONALE),
                        "HX-Prompt-URI-AutoEncoded": "true"})
    if r.status_code != 200 or "cmd" not in argv:
        refuse("remove route returned %d and %s reach the CLI — leg 4 has no "
               "argv to inspect"
               % (r.status_code, "did not" if "cmd" not in argv else "did"))
    cmd = argv["cmd"]
    passed = cmd[cmd.index("--rationale") + 1] if "--rationale" in cmd else None
    if passed != UNICODE_RATIONALE:
        failures.append(
            "leg4 (remove, SOVEREIGN): the rationale reaching `fw bvp driver "
            "--remove` is %r, operator wrote %r. This is the audit record of a "
            "policy edit, written by the framework itself."
            % (passed, UNICODE_RATIONALE))

    # ── Leg 6 — population, not just the two sites known today. Legs 1 and 4
    #    prove the two current routes decode; they say nothing about a THIRD
    #    route added next month that reads the header raw. This is T-509's shape
    #    and the reason it keeps recurring: an exemption — or here a fix —
    #    granted to the cases that prompted it and never extended to the class.
    #    Every read of HX-Prompt must go through the helper; the helper itself
    #    is the one legitimate site.
    src = BVP_PY.read_text(encoding="utf-8")
    raw_reads = []
    for i, line in enumerate(src.splitlines(), 1):
        if 'request.headers.get("HX-Prompt")' in line and "-URI-AutoEncoded" not in line:
            raw_reads.append(i)
    if len(raw_reads) != 1:
        failures.append(
            "leg6: %d site(s) read the HX-Prompt header directly (lines %s); "
            "exactly one is expected — the read inside _hx_prompt(). Any other "
            "is a route that stores the operator's rationale without asking "
            "htmx whether it encoded it."
            % (len(raw_reads), ", ".join(str(n) for n in raw_reads) or "none"))
    elif "def _hx_prompt" not in src[:src.index('request.headers.get("HX-Prompt")')]:
        failures.append(
            "leg6: the single raw HX-Prompt read is not inside _hx_prompt() — "
            "the helper has been bypassed or removed.")

    if failures:
        print("T-547 TEETH: %d of 6 legs RED" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("T-547 TEETH: 6 legs green — hx-prompt rationales round-trip on both "
          "routes (decoded when htmx declares an encoding, verbatim when it "
          "does not), the R6 floor measures the decoded text, and every reader "
          "of the header goes through the one helper")
    return 0


if __name__ == "__main__":
    sys.exit(main())
