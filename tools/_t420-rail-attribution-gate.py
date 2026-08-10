#!/usr/bin/env python3
"""
_t420-rail-attribution-gate.py — PreToolUse gate. Refuse an MCP termlink call that
puts content on the wire without saying which project produced it.

T-420. Prevention for OBS-012.

WHY THIS EXISTS
---------------
`from_project` is free text in an envelope's metadata. It is the ONLY thing that
separates cooperating producers at the seam, because `sender_id` does not: the
shell surface on this host signs every co-resident project's posts with one shared
key (T-418, G-029). A reader keying on the fingerprint attributes our posts to a
host, not to us.

At rail 514 §4 I told AEF that our labels are present but unguarded — that we type
`from_project` by hand, so the mechanism is habit rather than structure. Then I
measured it. On the AEF rail, our MCP identity `6a646ce8b1bc6560`:

    245 content envelopes
      4  labelled 832-Workflow-designer   (offsets 0, 511, 512, 514)
      2  labelled 010-termlink            (offsets 2, 4 — another project's label)
    239  no from_project at all

97.6% unattributed, and the only labels older than four days are wrong. The habit
I described as working began at offset 511 — the day after T-418 exposed the class —
and it had already missed once by offset 507. "Present but unguarded" was the
flattering version. There was no habit; there was a recent intention.

THE SHAPE OF THE REMEDY IS FORCED BY THE SURFACE
------------------------------------------------
AEF closed their side by attaching the label when the caller omits it (`fw rail
post`). That remedy is unavailable here: 832's only correct-identity producer is the
MCP surface, and an MCP tool call is not a script we own. There is nothing to put a
default into.

So this gate REFUSES instead of ATTACHING. That trade is not a downgrade in every
direction. A gate that attaches can attach the wrong label silently and the wire
looks clean; a gate that refuses cannot produce a wrong label at all. It costs a
retype, and the retype is the point.

WHAT THE ENUMERATION CHANGED (read this before editing the rules)
------------------------------------------------------------------
This was going to key on `payload`/`payload_b64` alone, on the theory that one
derived signal covers the class. Enumerating the surface first — AEF's T-2908 wrote
that AC first because they shipped believing there was one producer — falsified it
on the first read. Measured 2026-08-10 against the live tool schemas:

  A  CAN carry attribution
     channel_post          content: payload/payload_b64   attribution: metadata.from_project
     agent_post            content: text                  attribution: project param
     agent_reply           content: text                  attribution: project param
     -> two different content keys AND two different attribution channels. A
        payload-only rule would have waved both agent_* producers straight through.

  B  PRODUCES an envelope, CANNOT carry attribution
     channel_reply         content: text     no metadata param, no project param
     channel_forward       content: (none — re-posts by offset), forwarder becomes
                           sender of record; no metadata param
     broadcast             no-targets form posts to `broadcast:global`; payload is a
                           session-bus JSON blob, no attribution channel
     -> channel_forward carries NO content key at all, so no derived content rule can
        ever see it. It is the clearest case for the declared list below.

  C  NOT producers, despite a verb-shaped name
     channel_quote, agent_quote   read-side fetch-by-offset
     send, agent_ask              JSON-RPC to a session, not an envelope
     emit                         session event bus, not a hub envelope
     -> a name-pattern rule (post|reply|quote|forward|send|emit|ask) was the planned
        second signal. It false-positives on all five of these. Dropped.

DERIVED WHERE POSSIBLE, DECLARED WHERE NOT — AND SAID OUT LOUD
---------------------------------------------------------------
Rule 1 (DERIVED) is the load-bearing one and covers class A plus any future tool
that uses the same shape: content on the wire => a label that matches this project.

Rule 2 (DECLARED) covers class B. It is a hardcoded list of tool names, which is the
exact artifact PL-142 says expires silently: the RULE ("an unattributable producer
must be refused") is durable, the FACT ("these three tools are the unattributable
ones") is a property of the tool surface on 2026-08-10. It is labelled DECLARED
here so that a future reader knows which half to re-measure rather than trusting
both halves equally.

Rule 2 is a refusal, not a wedge: every entry names the compliant tool to use
instead. A gate whose block message has no remedy is the G-026 class this project
has now hit six times.

THE LABEL IS DERIVED, NOT TYPED
--------------------------------
The expected label is the project root's directory name, resolved from THIS FILE's
location — not from cwd, which a call can change. That derivation is not a
convenience: it is why the same one-line rule explains both projects' labels
(/opt/832-Workflow-designer -> `832-Workflow-designer`,
/opt/999-Agentic-Engineering-Framework -> `999-Agentic-Engineering-Framework`),
which is evidence the convention is real rather than a house style I invented.

Comparison is EXACT, including case. AEF's rail carries both
`999-Agentic-Engineering-Framework` and `999-agentic-engineering-framework` as
distinct labels; T-418's detector counts that split as AMBIGUOUS — wrong
attribution, not missing attribution. A case-insensitive gate here would let us
manufacture the same split in our own column.

EXIT CODES (Claude Code PreToolUse contract)
---------------------------------------------
  0  allow  — not a termlink producer, or attributed correctly
  2  block  — stderr is shown to the agent as the reason

Fails OPEN on unparseable input (exit 0). A gate that cannot read its input has not
measured anything, and refusing every tool call on the strength of a non-measurement
would wedge the session. The miss is visible afterwards to
tools/_t418-producer-attribution.py, which is the detector this gate does not replace.
"""

import json
import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPECTED_LABEL = os.path.basename(PROJECT_ROOT)

TERMLINK_PREFIX = "mcp__termlink__"

# Rule 1 (DERIVED): keys under which a termlink call puts content on the wire.
CONTENT_KEYS = ("payload", "payload_b64", "text")

# Rule 1 (DERIVED): the two attribution channels measured in use on this surface.
#   metadata.from_project  — channel_post family
#   project                — agent_post / agent_reply (hub stores it as from_project)
def attribution_of(tool_input):
    meta = tool_input.get("metadata")
    if isinstance(meta, dict) and meta.get("from_project") is not None:
        return "metadata.from_project", meta.get("from_project")
    if tool_input.get("project") is not None:
        return "project", tool_input.get("project")
    return None, None


# Rule 2 (DECLARED — enumerated 2026-08-10, see module docstring class B).
# Tools that emit an envelope and have NO attribution channel at all. Each entry
# carries the compliant alternative; a refusal without a remedy is a wedge.
UNATTRIBUTABLE_PRODUCERS = {
    "termlink_channel_reply": (
        "channel_reply takes no metadata and no project parameter, so its envelope "
        "can never say who produced it.\n"
        "  Use termlink_channel_post with metadata={'from_project': '%s', "
        "'in_reply_to': '<offset>'} — that is how rails 511/512/514 were sent."
    ),
    "termlink_channel_forward": (
        "channel_forward re-signs another sender's envelope under OUR key and takes "
        "no metadata, so the result is content we did not write, attributed to "
        "nobody, over our fingerprint.\n"
        "  Quote the content into a termlink_channel_post carrying "
        "metadata.from_project='%s' instead."
    ),
    "termlink_broadcast": (
        "broadcast with no targets posts to `broadcast:global` via channel.post and "
        "has no attribution channel.\n"
        "  Post to the specific topic with termlink_channel_post and "
        "metadata.from_project='%s'."
    ),
}


def block(*lines):
    for ln in lines:
        print(ln, file=sys.stderr)
    return 2


def decide(tool_name, tool_input):
    if not tool_name.startswith(TERMLINK_PREFIX):
        return 0
    short = tool_name[len(TERMLINK_PREFIX):]

    # --- Rule 2 (DECLARED) ---------------------------------------------------
    if short in UNATTRIBUTABLE_PRODUCERS:
        return block(
            "BLOCKED: %s cannot carry producer attribution." % short,
            "",
            UNATTRIBUTABLE_PRODUCERS[short] % EXPECTED_LABEL,
            "",
            "Why: sender_id at this seam is a HOST identity — the shell surface signs "
            "every co-resident project with one shared key (T-418/G-029). "
            "from_project is the only thing that separates producers, and it is "
            "unsigned free text, so an absent label cannot be reconstructed later.",
            "This refusal list is DECLARED, not derived (T-420, enumerated 2026-08-10). "
            "If this tool has since gained a metadata parameter, re-measure and update "
            "tools/_t420-rail-attribution-gate.py — do not bypass.",
        )

    # --- Rule 1 (DERIVED) ----------------------------------------------------
    carried = [k for k in CONTENT_KEYS
               if isinstance(tool_input.get(k), str) and tool_input.get(k).strip()]
    if not carried:
        return 0  # read-side call, or a write with no content of ours

    where, label = attribution_of(tool_input)

    if where is None:
        return block(
            "BLOCKED: %s puts content on the wire (%s) with no producer attribution."
            % (short, ", ".join(carried)),
            "",
            "Add ONE of:",
            "  metadata={'from_project': '%s', ...}   (channel_post family)"
            % EXPECTED_LABEL,
            "  project='%s'                            (agent_post / agent_reply)"
            % EXPECTED_LABEL,
            "",
            "Measured on the AEF rail: 239 of our 245 content envelopes carry no "
            "from_project, and 2 of the 6 that do carry another project's label. "
            "This is the class, not an edge case (OBS-012, rail 514 §4).",
        )

    if label != EXPECTED_LABEL:
        return block(
            "BLOCKED: %s carries %s=%r, expected %r."
            % (short, where, label, EXPECTED_LABEL),
            "",
            "The label is compared EXACTLY, including case. A near-miss is worse than "
            "an absence: T-418's detector reads one fingerprint with two spellings as "
            "AMBIGUOUS — wrong attribution rather than missing attribution — and AEF's "
            "column already carries that split "
            "(999-Agentic-Engineering-Framework vs 999-agentic-engineering-framework).",
            "",
            "Expected label is derived from the project root directory name (%s), "
            "not typed. If the project moved, this gate moved with it." % PROJECT_ROOT,
        )

    return 0


def main():
    try:
        raw = sys.stdin.read()
        hook = json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, OSError):
        return 0  # fail open — see EXIT CODES in the docstring
    tool_name = hook.get("tool_name") or ""
    tool_input = hook.get("tool_input")
    if not isinstance(tool_input, dict):
        tool_input = {}
    return decide(tool_name, tool_input)


if __name__ == "__main__":
    sys.exit(main())
