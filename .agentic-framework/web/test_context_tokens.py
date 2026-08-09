"""
Unit tests for lib/context_tokens.py — the session context-size gauge (T-401).

These are regression teeth, not coverage. The defect they pin let the PreToolUse
budget gate BLOCK every tool call in a session that had ~72% of its context free,
immediately after a /compact run to reclaim that context.

The central test is test_old_algorithm_still_fails_the_incident_fixture: it runs
the PRE-FIX algorithm against the same fixture and asserts it still produces the
false 341880. Without that, a later "simplification" could delete the model
scoping and every remaining test would stay green -- the fixture would no longer
be testing anything, and nothing would say so.

Run: pytest web/test_context_tokens.py -v
"""

import json
import os
import sys
import tempfile

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from lib.context_tokens import context_tokens, collect, MIN_ENTRIES_TO_JUDGE

SESSION_MODEL = "claude-opus-5"
FOREIGN_MODEL = "claude-opus-4-8"


# ── helpers ─────────────────────────────────────────────────────


def _usage_entry(ts, model, total, input_tokens=100):
    """An assistant turn whose prompt totalled `total` tokens."""
    return {
        "type": "assistant",
        "timestamp": ts,
        "message": {
            "role": "assistant",
            "model": model,
            "usage": {
                "input_tokens": input_tokens,
                "cache_read_input_tokens": max(total - input_tokens, 0),
                "cache_creation_input_tokens": 0,
            },
        },
    }


def _cache_priming_entry(ts, model, created):
    """The T-401 poisoning shape, reproduced field-for-field from the transcript.

    input_tokens=2 with a huge one-hour cache WRITE and empty content. Its prompt
    genuinely was ~`created` tokens, which is why no arithmetic check catches it.
    """
    return {
        "type": "assistant",
        "timestamp": ts,
        "isSidechain": False,
        "message": {
            "role": "assistant",
            "model": model,
            "content": [{"type": "text", "text": ""}],
            "usage": {
                "input_tokens": 2,
                "cache_creation_input_tokens": created,
                "cache_read_input_tokens": 19217,
                "output_tokens": 347,
            },
        },
    }


def _boundary(ts):
    return {"type": "system", "subtype": "compact_boundary", "timestamp": ts}


def _write(entries):
    fd, path = tempfile.mkstemp(suffix=".jsonl")
    with os.fdopen(fd, "w") as f:
        for e in entries:
            f.write(json.dumps(e) + "\n")
    return path


def _old_algorithm(path, session_start_ts=""):
    """The pre-T-401 implementation: last usage entry wins, no model scoping.

    Kept verbatim in behaviour so the fixtures can be shown to have teeth.
    """
    t = 0
    with open(path) as f:
        for line in f:
            try:
                e = json.loads(line)
            except Exception:
                continue
            if e.get("type") == "system" and e.get("subtype") == "compact_boundary":
                t = 0
                continue
            model = e.get("message", {}).get("model", "")
            if model == "<synthetic>" or model.startswith("<"):
                continue
            if session_start_ts:
                ts = e.get("timestamp", "")
                if ts and ts < session_start_ts:
                    continue
            u = e.get("message", {}).get("usage")
            if u and "input_tokens" in u:
                t = (u["input_tokens"] + u.get("cache_read_input_tokens", 0)
                     + u.get("cache_creation_input_tokens", 0))
    return t


# ── the incident fixture ────────────────────────────────────────


def _incident_transcript():
    """The log EXACTLY as the gate saw it at 07:36:33Z, when it wrote critical.

    Reconstructing this at the right instant took a correction. The first draft
    appended the 07:36+ opus-5 turns, and against that the pre-fix algorithm
    returns 84629 -- i.e. it looks correct. The bug is only visible in the log
    state that actually existed when the gate read: the foreign entry was the
    NEWEST post-boundary entry, because the conversation's own turns had not
    been flushed yet.

    That is what makes the sparse-data fail-open the load-bearing half of the
    fix rather than a safety margin: at the measured failure instant there was
    no conversation volume to scope against at all.
    """
    return _write([
        _usage_entry("2026-08-09T07:04:00.000Z", SESSION_MODEL, 341880),
        _boundary("2026-08-09T07:08:13.708Z"),
        # 18 minutes after the boundary, on a different model, and newest:
        _cache_priming_entry("2026-08-09T07:26:21.446Z", FOREIGN_MODEL, 322661),
    ])


def _incident_transcript_after_first_turns():
    """The same session moments later, once opus-5 turns have landed."""
    return _write([
        _usage_entry("2026-08-09T07:04:00.000Z", SESSION_MODEL, 341880),
        _boundary("2026-08-09T07:08:13.708Z"),
        _cache_priming_entry("2026-08-09T07:26:21.446Z", FOREIGN_MODEL, 322661),
        _usage_entry("2026-08-09T07:36:31.930Z", SESSION_MODEL, 72268),
        _usage_entry("2026-08-09T07:36:33.269Z", SESSION_MODEL, 72268),
        _usage_entry("2026-08-09T07:37:28.945Z", SESSION_MODEL, 84629),
    ])


def test_incident_fixture_does_not_report_critical():
    path = _incident_transcript()
    try:
        assert context_tokens(path, "2026-08-09T07:08:09.000Z") == 0
    finally:
        os.unlink(path)


def test_old_algorithm_still_fails_the_incident_fixture():
    """TEETH. If this ever passes, the fixture stopped reproducing the bug."""
    path = _incident_transcript()
    try:
        assert _old_algorithm(path, "2026-08-09T07:08:09.000Z") == 341880
    finally:
        os.unlink(path)


def test_incident_session_reads_correctly_once_turns_land():
    path = _incident_transcript_after_first_turns()
    try:
        assert context_tokens(path, "2026-08-09T07:08:09.000Z") == 84629
    finally:
        os.unlink(path)


def test_foreign_entry_is_ignored_even_when_it_is_the_newest():
    """The motivating case: the foreign call is the MOST RECENT entry.

    A scoping rule keyed on 'the model of the latest entry' would reproduce the
    original bug here, which is precisely why the implementation uses frequency.
    """
    path = _write([
        _usage_entry("2026-08-09T08:00:00.000Z", SESSION_MODEL, 50000),
        _usage_entry("2026-08-09T08:00:01.000Z", SESSION_MODEL, 51000),
        _cache_priming_entry("2026-08-09T08:00:02.000Z", FOREIGN_MODEL, 322661),
    ])
    try:
        assert context_tokens(path) == 51000
    finally:
        os.unlink(path)


# ── the gate must still be able to fire ─────────────────────────


def test_genuinely_oversized_session_still_reads_critical():
    """A fix that lowers every number has removed the gate, not repaired it."""
    entries = [
        _usage_entry(f"2026-08-09T09:00:{i:02d}.000Z", SESSION_MODEL, 281000 + i * 1000)
        for i in range(10)
    ]
    path = _write(entries)
    try:
        tokens = context_tokens(path)
        assert tokens == 290000
        assert tokens >= 300000 * 95 // 100  # critical threshold at default window
    finally:
        os.unlink(path)


def test_compact_boundary_still_discards_prior_history():
    """T-2322 must survive the refactor -- checkpoint.sh never had it before."""
    path = _write([
        _usage_entry("2026-08-09T09:00:00.000Z", SESSION_MODEL, 290000),
        _usage_entry("2026-08-09T09:00:01.000Z", SESSION_MODEL, 295000),
        _boundary("2026-08-09T09:10:00.000Z"),
        _usage_entry("2026-08-09T09:11:00.000Z", SESSION_MODEL, 12000),
        _usage_entry("2026-08-09T09:11:01.000Z", SESSION_MODEL, 13000),
    ])
    try:
        assert context_tokens(path) == 13000
    finally:
        os.unlink(path)


def test_session_start_ts_still_filters_pre_session_entries():
    """T-1088 must survive the refactor."""
    path = _write([
        _usage_entry("2026-08-09T06:00:00.000Z", SESSION_MODEL, 280000),
        _usage_entry("2026-08-09T06:00:01.000Z", SESSION_MODEL, 285000),
        _usage_entry("2026-08-09T08:00:00.000Z", SESSION_MODEL, 9000),
        _usage_entry("2026-08-09T08:00:01.000Z", SESSION_MODEL, 9500),
    ])
    try:
        assert context_tokens(path, "2026-08-09T07:00:00.000Z") == 9500
    finally:
        os.unlink(path)


def test_synthetic_entries_still_ignored():
    path = _write([
        _usage_entry("2026-08-09T08:00:00.000Z", SESSION_MODEL, 40000),
        _usage_entry("2026-08-09T08:00:01.000Z", SESSION_MODEL, 41000),
        _usage_entry("2026-08-09T08:00:02.000Z", "<synthetic>", 0),
    ])
    try:
        assert context_tokens(path) == 41000
    finally:
        os.unlink(path)


# ── the sparse-data fail-open ───────────────────────────────────


def test_lone_foreign_entry_does_not_block():
    """The opening calls of a resumed session, where frequency is a coin-flip.

    Deliberate fail-open: a session with fewer than two turns since the last
    boundary cannot have filled its context, so 0 is both the safe answer and
    the physically correct one.
    """
    path = _write([
        _cache_priming_entry("2026-08-09T07:26:21.446Z", FOREIGN_MODEL, 322661),
    ])
    try:
        assert context_tokens(path) == 0
    finally:
        os.unlink(path)


def test_min_entries_threshold_is_the_documented_value():
    assert MIN_ENTRIES_TO_JUDGE == 2


# ── robustness: this feeds a hook on every tool call ────────────


@pytest.mark.parametrize("bad", ["/nonexistent/path.jsonl", ""])
def test_unreadable_transcript_returns_zero_not_an_exception(bad):
    assert context_tokens(bad) == 0


def test_malformed_lines_are_skipped():
    fd, path = tempfile.mkstemp(suffix=".jsonl")
    with os.fdopen(fd, "w") as f:
        f.write("not json at all\n")
        f.write(json.dumps(_usage_entry("2026-08-09T08:00:00.000Z", SESSION_MODEL, 7000)) + "\n")
        f.write("{truncated\n")
        f.write(json.dumps(_usage_entry("2026-08-09T08:00:01.000Z", SESSION_MODEL, 7500)) + "\n")
    try:
        assert context_tokens(path) == 7500
    finally:
        os.unlink(path)


def test_collect_preserves_order_newest_last():
    path = _write([
        _usage_entry("2026-08-09T08:00:00.000Z", SESSION_MODEL, 100),
        _usage_entry("2026-08-09T08:00:01.000Z", SESSION_MODEL, 200),
    ])
    try:
        assert [t for _, t in collect(path)] == [100, 200]
    finally:
        os.unlink(path)
