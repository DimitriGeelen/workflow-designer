# tests/fixtures/aef-inbound

Fixtures **authored by AEF**, received from AEF, unmodified. The directory name asserts a
provenance these files actually have — deliberately, because T-365 is the open defect that
`tests/fixtures/aef-bpmn` asserts one it does not. Nothing we synthesize goes in here.

## Provenance

| file | source | bytes | sha256 |
|---|---|---|---|
| `t406-clean-leading-boilerplate.bpmn` | AEF commit `4f9a42926`, `tests/fixtures/832-outbound/` | 8918 | `bbc6269dacc06991c5ab8df6e7231f7e58f5882605d7475dbdd81d4c27befd9c` |
| `t406-incidental-leading-boilerplate.bpmn` | AEF commit `4f9a42926`, `tests/fixtures/832-outbound/` | 15172 | `04ae662f09ef27d19bbf4968219e3a4cf5beb7b4e94209c086928ae043f26c41` |

**Delivery channel:** rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offsets **504** and **505**,
as `payload_b64`. Not `file_send` — OBS-108 shuts the file channel between the two projects,
and these are the one case where the artifact *is* the bytes, so a ref could not carry it.

**Landed by:** `tools/_t413-land-fixtures.py`, which takes the sha256 **on the decoded
buffer before writing** and writes nothing at all on mismatch. Hashing the file afterwards
would prove the write, which nobody doubted; the transfer is what needed proving.

## What each one distinguishes

Both open with the same eight words — `BPMN DI (visual layout) omitted` — which is the
false trailer we shipped for 11 releases and also, byte-identically, a string AEF's own
documents legitimately carry. No test on the content of those eight words can separate
them; that is the whole difficulty of T-406.

- **clean** — the leading comment is *nothing but* the trailer. Not synthesized: this is
  AEF's `aef-audit-cron/v1.bpmn` as it stood at their `2d3013929`, before their T-2683
  restored its authored doc comment. Real corruption that reached their promoted corpus.
  Suppressing it is correct and loses nothing.

- **incidental** — their real, current `aef-task-lifecycle/v1.bpmn` with the trailer
  prepended to the front of its genuine leading doc comment, same `<!-- -->` block. The
  seven lines after it are real rationale (`designer-corpus D1 (arc-014, T-2555)…`).
  Suppressing this destroys content nobody can recover.

## Measured on the received bytes, not taken from the report

`exporter=` occurs **0 times in each file**. AEF's rail 506 §2 says the same holds for 0 of
37 `.bpmn` in their live corpus and 0 on any `.bpmn` on their disk: the `exporter=
"aef-corpus-spec"` stamp they shipped for us at rail 494 lives in their emitter
(`tools/corpus_spec.py:407`, inside `generate()`) and has never reached an artifact,
because nothing round-trips a stored map through `generate --save`.

We re-measured rather than accepting it, which is their own 506 §3 point: *a producer's
report that a stamp shipped is a claim about the emitter; the consumer needs a claim about
the artifact.*

## First run, kept as evidence

`_t413-first-run.txt` is the verbatim output of `tools/_t406-doc-comment-provenance-cdp.mjs`
the first time these two documents went through it, before any fix. The incidental leg is
red there. It is committed rather than described because a fix makes the live probe green
and the finding otherwise survives only as prose.
