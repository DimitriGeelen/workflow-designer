#!/usr/bin/env python3
"""Single source of truth for "how big is this session's context right now?".

Usage:
    python3 context_tokens.py <transcript.jsonl> [<session-start-ts-file>]

Prints one integer (token count) to stdout. Prints 0 when it cannot measure.

WHY THIS FILE EXISTS (T-401)
----------------------------
This algorithm previously existed as two hand-copied inline scripts, in
budget-gate.sh (PreToolUse, the BLOCKING gauge) and checkpoint.sh (PostToolUse,
the warning gauge). They drifted: budget-gate gained the T-2322 compact_boundary
reset and checkpoint never did. Two copies of one algorithm, one of them silently
a version behind, both feeding the same enforcement decision.

Cost accounting (lib/costs.sh, web/blueprints/costs.py) sums the SAME three usage
fields and must NOT be routed through here. For cost, a cache-priming call on
another model genuinely did cost money and belongs in the total. For context size
it is noise. Same arithmetic, opposite correct answer — do not "unify" them.

WHAT WENT WRONG (T-401)
-----------------------
On the first tool call of a post-compact session, the gauge scored 341880 tokens
(critical -> BLOCK) for a session whose real size was 84629 (~28%). The gate
refused all work in a session with ~72% headroom, immediately after a /compact
run to reclaim exactly that context.

The poisoning entry, verbatim from the transcript:

    timestamp   2026-08-09T07:26:21.446Z   (18 min AFTER the compact_boundary)
    model       claude-opus-4-8            (the session runs claude-opus-5)
    isSidechain False                      (not a subagent)
    sessionId   <this session>             (genuinely in our own file)
    usage       input_tokens=2,
                cache_creation_input_tokens=322661,
                cache_read_input_tokens=19217
    content[0]  ''                         (empty)

input_tokens=2 with a 322k one-hour cache WRITE: a cache-priming call on a
different model, logged into this session's transcript. Its prompt really was
341880 tokens, so the arithmetic was never wrong -- the ENTRY SELECTION was.
That is why the fix is scoping, not a formula tweak.

Three defenses already existed and all three missed it, because all three filter
by POSITION IN THE LOG and this entry is legitimately positioned:
  - T-2322 compact_boundary reset  -> entry is 18 min AFTER the boundary
  - T-1088 .session-start-ts filter-> entry is AFTER session start
  - <synthetic> model filter       -> entry is a real model, not synthetic

The only thing that separates it from the conversation is MODEL IDENTITY, so
that is what this file adds. Position tells you when a call happened; it cannot
tell you whose conversation it belonged to.
"""

import json
import os
import sys
from collections import Counter

# Match the byte window the previous inline implementations used, so this change
# cannot alter results by widening/narrowing history.
TAIL_BYTES = 10_000_000

# Below this many conversational entries we refuse to guess (see _pick below).
MIN_ENTRIES_TO_JUDGE = 2


def _iter_entries(path):
    """Yield parsed JSON objects from the last TAIL_BYTES of the transcript."""
    try:
        size = os.path.getsize(path)
    except OSError:
        return
    try:
        with open(path, "r", errors="replace") as f:
            if size > TAIL_BYTES:
                f.seek(size - TAIL_BYTES)
                f.readline()  # discard the partial line the seek landed inside
            for line in f:
                try:
                    yield json.loads(line)
                except Exception:
                    continue
    except OSError:
        return


def _usage_total(usage):
    """Full prompt size for one API call.

    Kept identical to the previous inline formula on purpose. Every field here
    is genuinely part of the prompt that was sent; the bug was never arithmetic.
    """
    return (
        usage["input_tokens"]
        + usage.get("cache_read_input_tokens", 0)
        + usage.get("cache_creation_input_tokens", 0)
    )


def collect(transcript, session_start_ts=""):
    """Return [(model, tokens)] for candidate entries, newest last."""
    entries = []
    for e in _iter_entries(transcript):
        # T-2322: a compact boundary discards everything before it. The live
        # context after a compaction starts near zero regardless of history.
        if e.get("type") == "system" and e.get("subtype") == "compact_boundary":
            entries = []
            continue

        message = e.get("message") or {}
        model = message.get("model", "")

        # Claude Code writes <synthetic> entries (0 tokens) around compaction.
        if model == "<synthetic>" or model.startswith("<"):
            continue

        # T-1088: `claude -c` continues the same JSONL, so entries from before
        # this session began are still in the file. ISO-8601 Z sorts lexically.
        if session_start_ts:
            ts = e.get("timestamp", "")
            if ts and ts < session_start_ts:
                continue

        usage = message.get("usage")
        if usage and "input_tokens" in usage:
            entries.append((model, _usage_total(usage)))
    return entries


def _pick(entries):
    """Pick the last entry belonging to THIS session's conversation.

    Scoping rule (T-401): the conversation is whichever model produced the most
    entries. A foreign call -- cache priming, a background feature, a differently
    modelled helper -- contributes a handful of entries; the conversation
    contributes one per turn and always wins on volume.

    Deliberately NOT "the model of the most recent entry": in the incident that
    motivated this file, the foreign entry WAS the most recent one. A rule that
    trusts the newest entry to identify the conversation reproduces the bug.

    Sparse-data rule: below MIN_ENTRIES_TO_JUDGE we return 0 rather than guess.
    This is the load-bearing half of the fix, not a rounding detail. At the
    measured failure instant (07:36:33Z) the conversation had produced only one
    or two entries against the foreign one, so frequency alone is a coin-flip
    exactly when it matters most -- the opening calls of a resumed session.

    Returning 0 there is a deliberate FAIL-OPEN. The cost of a false 'ok' is a
    few unblocked calls that self-correct on the next read; the cost of a false
    'critical' is a session that cannot work at all at the very moment it is
    trying to resume. A session that has produced fewer than two assistant turns
    since the last boundary cannot plausibly have filled its context, so the
    fail-open direction is also the physically correct one.
    """
    if len(entries) < MIN_ENTRIES_TO_JUDGE:
        return 0
    counts = Counter(model for model, _ in entries)
    # Ties: prefer the model whose entry appears latest, so a genuine mid-session
    # model switch converges to the new model instead of pinning to the old one.
    best = max(counts, key=lambda m: (counts[m], _last_index(entries, m)))
    for model, tokens in reversed(entries):
        if model == best:
            return tokens
    return 0


def _last_index(entries, model):
    for i in range(len(entries) - 1, -1, -1):
        if entries[i][0] == model:
            return i
    return -1


def context_tokens(transcript, session_start_ts=""):
    return _pick(collect(transcript, session_start_ts))


def main(argv):
    if len(argv) < 2:
        print(0)
        return 0
    transcript = argv[1]
    session_start_ts = ""
    if len(argv) > 2 and argv[2] and os.path.exists(argv[2]):
        try:
            with open(argv[2]) as f:
                session_start_ts = f.read().strip()
        except OSError:
            pass
    try:
        print(context_tokens(transcript, session_start_ts))
    except Exception:
        # This feeds a gate that runs on EVERY tool call. It must never raise:
        # a traceback here would either block every tool or blind the gauge.
        print(0)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
