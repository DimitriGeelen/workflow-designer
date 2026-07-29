# T-302 — Reviewer sweep of the verification queue (2026-07-29)

## Census correction

The filing-time premise ("53 [REVIEWER] ACs convertible") was a measurement defect: every task file embeds a `- [ ] [REVIEWER]` example inside an HTML template comment, and the raw grep counted those. Comment-stripped reality across `.tasks/active/`:

- **0** real `[REVIEWER]` ACs (checked or unchecked)
- **76** unchecked `[REVIEW]` Human ACs — exactly one per queue task
- Classification: **1** deterministic mis-prefix (PL-027 class) → converted (T-090); **10** inception decision gates → sovereignty, never automatable; **65** genuine taste → stay human

## Reviewer verdicts (fw reviewer, catalogue v1.3-seed, run on all 76)

**56 PASS / 20 CONCERN.** Every CONCERN is advisory hygiene (heuristic `AC-verify-mismatch`, `l387-sigpipe-risk` lint on Verification lines) — none contradicts the shipped work or blocks the human queue. Verdict sections are recorded in each task file by the tool.

CONCERN tasks: T-041 T-081 T-098 T-099 T-100 T-101 T-105 T-107 T-115 T-127 T-136 T-137 T-164 T-165 T-166 T-167 T-168 T-189 T-197 T-204

## Converted (1)

- **T-090** — `[RUBBER-STAMP]` "review queue loads, no 500": Expected is a curl check that already lived in its `## Verification`. Re-verified live (HTTP 200, `<title>Review T-089</title>`), moved to `### Agent` ticked. Human section now empty; owner is human, so the agent did not finalize. Close: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-090 --status work-completed`

## Operator batch checklist

Grouped by surface so the queue clears in a few sittings, not 75 context switches. Each row: what to judge, where, and the one-line tick+close command to run **after** you're satisfied. Commands only appear where the taste AC is the sole unchecked box.

### Inception decisions (10) — `fw inception decide`, not tick-and-close

> **SUPERSEDED (T-307, 2026-07-29).** The commands previously listed here were defective: each
> carried a placeholder rationale (`--rationale "<why>"`) written into a permanent sovereignty
> record, pre-filled `go` as the default verb, and requested a decision without presenting the
> evidence first. They also bypassed the sanctioned route — inception decisions go through
> `fw task review T-XXX` and the Watchtower `/inception/T-XXX` page; the CLI form refuses to run
> inside an agent session by design (T-679/T-1259).
>
> **Use `docs/reports/T-307-inception-decision-briefs.md` instead.** It carries, per task: the
> question, the evidence state, findings, an agent recommendation with reasoning, all three verbs
> as complete commands with rationales drafted from that task's own findings, and a proposed
> `revisit_at` / `revisit_evidence_needed` so a ratified DEFER cannot rot invisibly.
>
> Note also: it is **nine** open decisions, not ten — T-155 already has a DEFER recorded and needs
> closing, not deciding.

---

## Pre-flight stamp (T-305, 2026-07-29)

Every close command above runs the P-011 verification gate. T-305 pre-flighted the full gate surface **before** handing you this checklist:

- **Extracted:** 330 Verification lines across the 66 close-ready tasks (same comment-stripped parser as the gate), deduped to **213 unique commands**, each executed once.
- **Found rotted:** 10 failing lines, 6 root classes — count-pinned suite totals (`31 passed` vs today's 43), `grep -c` exiting 1 on zero matches under `set -e`, exact-count source greps outgrown by legitimate call sites, checks against the shim deleted at the T-276 re-vendor, the forbidden yaml-to-bpmn regen-diff (G-012 destructive path vs editor-saved dialect), and a curl at retired port :8834 (T-253 ufw RCA).
- **Fixed:** 26 task files, Verification sections only. No expectation was weakened beyond count-agnosticism — every suite check still requires `0 failed`.
- **Re-verified green:** one fresh bridge-suite run (43 passed, 0 failed) evaluates the shared count-agnostic pattern; every other fixed line re-executed standalone; the 7 structurally-edited tasks (T-075 T-090 T-095 T-096 T-101 T-195 T-293) passed full `fw task verify`.

The one-line closes above should now pass their gates without blocking in your face. Learning captured as PL-061: Verification lines assert failure-shape (`passed, 0 failed`), never pinned totals.

---

## Batch execution stamp (T-306, 2026-07-29)

Operator authorization: **"close all, i checked"** (Tier-2, logged in T-306). Executed all 66 tick+close one-liners above, each through its full P-011 gate, zero bypass flags. Outcome:

- **55 tasks closed** and moved to `.tasks/completed/` (episodics auto-generated).
- **11 tasks blocked by the R-033 sovereignty gate** — they were still `started-work` + `owner: human`, and completion for that state must come from the human via the Watchtower review page. Their [REVIEW] ACs are ticked (per your authorization); each needs one approval from you: **T-041, T-101, T-102, T-105, T-125, T-189, T-195, T-228, T-264, T-286, T-293** — review URLs are `http://192.168.10.107:3000/review/<T-XXX>`, or run the task's close one-liner from your own terminal.
- **Defect found in this checklist's own one-liners (fixed):** the `sed` "tick first unchecked [REVIEW]" pattern hits the template-comment EXAMPLE line in tasks whose `### Human` comment block precedes the real AC — 17 files were silently corrupted that way (comment example ticked, real AC untouched, update-task exits 0 → false-positive OK). All 17 comment examples restored, the 15 affected real ACs ticked via comment-masked parsing, closes re-run clean. Learning captured as PL-062.
- The **10 inception go/no-go decisions** in the section above remain untouched — those need your decision direction, not a close.
