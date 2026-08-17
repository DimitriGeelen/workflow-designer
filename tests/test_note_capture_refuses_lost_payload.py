#!/usr/bin/env python3
"""T-557: `fw note` must refuse a call whose payload it would otherwise discard.

WHAT THIS PINS
--------------
`agents/observe/observe.sh` dispatches any unrecognised first word to the capture
path, where it becomes the observation TEXT and everything after it is dropped by the
flag loop's `*) shift ;;`. Two shapes lose data, both at exit 0 with `OBS-NNN captured`:

    fw note add "<900 chars>"      -> text becomes "add",  payload discarded
    fw note this is a finding      -> text becomes "this", rest discarded

Eleven observations were destroyed this way between 2026-08-09 and 2026-08-17
(OBS-006/011/022/028/032/035/044/241/262/274/285 — ten "add", one "inbox").
OBS-274 was T-556's central finding and sat `pending` + `urgent` for nine hours as
the literal string "add" while being cited in three commit messages.

WHY THE GUARD IS SHAPE-BASED
----------------------------
The fix counts POSITIONAL arguments rather than matching a list of subcommand words.
A word list ("add", "inbox", ...) would have caught all eleven husks and missed the
twelfth. `fw note` takes exactly one positional — the text — so "more than one
positional" is the general statement of "your payload is about to vanish".

ISOLATION
---------
Every case runs against a throwaway PROJECT_ROOT (paths.sh honours a pre-set
PROJECT_ROOT, lib/paths.sh:39), so the real .context/inbox.yaml is never touched.
Leg 0 asserts that isolation holds before any other leg is trusted — a suite that
silently wrote to the live register would be a worse version of the bug it tests.
"""

import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# T557_OBSERVE_SH lets a mutant be driven without swapping the live script in and out of
# the tree. Mutation-testing by moving the real file is how a suite ends up running
# against a mutant it forgot to restore.
OBSERVE = os.environ.get(
    "T557_OBSERVE_SH",
    os.path.join(REPO, ".agentic-framework", "agents", "observe", "observe.sh"),
)
LIVE_INBOX = os.path.join(REPO, ".context", "inbox.yaml")


def run_note(root, args):
    """Invoke observe.sh with an isolated PROJECT_ROOT. Returns (rc, stdout, stderr)."""
    env = dict(os.environ)
    env["PROJECT_ROOT"] = root
    env.pop("_FW_PATHS_DERIVED_BY", None)
    env.pop("CONTEXT_DIR", None)
    env.pop("TASKS_DIR", None)
    p = subprocess.run(
        ["bash", OBSERVE] + args,
        env=env, cwd=root, capture_output=True, text=True,
    )
    return p.returncode, p.stdout, p.stderr


def inbox_text(root):
    path = os.path.join(root, ".context", "inbox.yaml")
    if not os.path.exists(path):
        return ""
    with open(path) as fh:
        return fh.read()


def fail(msg):
    print("FAIL: " + msg, file=sys.stderr)
    sys.exit(1)


def main():
    if not os.path.exists(OBSERVE):
        fail("observe.sh not found at %s" % OBSERVE)

    live_before = None
    if os.path.exists(LIVE_INBOX):
        with open(LIVE_INBOX) as fh:
            live_before = fh.read()

    root = tempfile.mkdtemp(prefix="t557-")
    try:
        os.makedirs(os.path.join(root, ".context"), exist_ok=True)

        # ── Leg 1: the exact call that destroyed OBS-274 is REFUSED ──────────────
        rc, out, err = run_note(root, ["add", "the real payload, 900 characters worth"])
        if rc == 0:
            fail("leg 1: `note add \"...\"` exited 0 — the swallow path is still open")
        body = inbox_text(root)
        if "add" in body and "text:" in body:
            fail("leg 1: a husk was written to the inbox despite refusal")
        if "observations:" in body and "OBS-" in body:
            fail("leg 1: refusal still created an observation row")

        # ── Leg 2: unquoted prose is REFUSED, not truncated to its first word ────
        rc, out, err = run_note(root, ["this", "is", "an", "observation"])
        if rc == 0:
            fail("leg 2: unquoted multi-word note exited 0 — it would capture only 'this'")

        # ── Leg 3: the refusal explains itself and names the correct form ────────
        msg = out + err
        if "fw note" not in msg:
            fail("leg 3: refusal does not show the correct invocation")
        if "Nothing was written" not in msg:
            fail("leg 3: refusal does not state that nothing was written — the whole "
                 "point is that the caller must not believe a capture happened")

        # ── Leg 4: DISCRIMINATION — a legitimate single-string note still works ──
        # Without this leg, "refuse everything" would pass legs 1-3. This is the arm
        # that stops the repair from trading silent loss for silent refusal.
        rc, out, err = run_note(root, ["port 3012 is wrong in the handover"])
        if rc != 0:
            fail("leg 4: a legitimate one-argument note was refused (rc=%d): %s"
                 % (rc, (out + err)[:300]))
        body = inbox_text(root)
        if "port 3012 is wrong" not in body:
            fail("leg 4: legitimate note was not persisted to the inbox")

        # ── Leg 5: flags are not miscounted as positionals ───────────────────────
        rc, out, err = run_note(
            root, ["a real finding with flags", "--task", "T-557", "--tag", "tooling", "--urgent"]
        )
        if rc != 0:
            fail("leg 5: one text argument plus flags was refused (rc=%d) — the counter "
                 "is treating flag VALUES as positionals: %s" % (rc, (out + err)[:300]))
        body = inbox_text(root)
        if "a real finding with flags" not in body:
            fail("leg 5: flagged note was not persisted")
        if "urgent: true" not in body:
            fail("leg 5: --urgent was dropped while the text survived")

        # ── Leg 6: real subcommands still dispatch, not refused as positionals ───
        rc, out, err = run_note(root, ["count"])
        if rc != 0:
            fail("leg 6: `note count` was refused (rc=%d) — the guard is eating real "
                 "subcommands: %s" % (rc, (out + err)[:300]))

        # ── Leg 0 (asserted last, over the whole run): the live register is untouched ──
        if live_before is not None:
            with open(LIVE_INBOX) as fh:
                if fh.read() != live_before:
                    fail("leg 0: the REAL .context/inbox.yaml changed during this test — "
                         "isolation failed and every other leg above is untrustworthy")

        print("OK: fw note refuses payload-losing calls — "
              "6 legs (swallowed subcommand, unquoted prose, explained refusal, "
              "legitimate note still captured, flags not miscounted, subcommands still "
              "dispatch) + live-inbox isolation asserted")
        return 0
    finally:
        shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
