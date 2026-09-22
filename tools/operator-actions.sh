#!/usr/bin/env bash
# operator-actions.sh — the decisions only a human can make, with the long commands
# pre-written so they do not have to be pasted from a conversation.
#
# WHY THIS EXISTS: several pending items are Tier 0 or sovereignty-gated. The agent is
# structurally blocked from running them — which is correct — but the commands themselves are
# long, and a long command pasted out of a chat log is a command nobody reads before running.
#
# DESIGN, deliberately: bare invocation LISTS and does nothing. Each action says WHY a human is
# required, not just what it runs. Consequential actions confirm before acting. A queue of
# opaque one-liners would train exactly the reflex the gates exist to prevent.
#
#   ./tools/operator-actions.sh              list what is pending
#   ./tools/operator-actions.sh <id>         run one, after showing it and confirming
#   ./tools/operator-actions.sh <id> --show  print the command without running it
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FW="$ROOT/.agentic-framework/bin/fw"

b() { printf '\033[1m%s\033[0m\n' "$*"; }
dim() { printf '\033[2m%s\033[0m\n' "$*"; }

# ── T-788: correct a recorded inception decision ─────────────────────────────────────────────
T788_WHY="Tier 0. fw inception decide requires human authority and agents must not invoke it at
  all. The current record reads Decision: GO with a rationale that argues DEFER — the filing
  rationale was carried into the Decision block whatever verdict was picked (see T-799 RCA).
  This rewrites the Decision block; the original GO survives in the Updates history."
T788_CMD=( "$FW" inception decide T-788 no-go --rationale
"NO-GO on 832 building any part of the workflow-to-application executor. CORRECTS an earlier GO whose stored rationale was the DEFER text from filing and argued the opposite of its own verdict. The decisive fact arrived after filing: AEF at agent-chat-arc offset 1631 answered that Child-2 is shipped and pinned, not a spike - wired as the CLI verb fw bpmn compile, on master, contained in release tag v1.6.768, maintained, with no planned break in the seam. Their expectation of 832 is one artefact, the .bpmn file, and explicitly NOT a translator, compile document, staging area or task writer, because the .tasks/ write never leaves their task-gate perimeter. Building any part of it here would duplicate shipped maintained code, contradict the frozen standard's No translator is built here, and fork governance across two projects against a yardstick that puts AEF integration at 9. Measured on receipt: aef:uid present in 24 of 24 rendered maps, aef:laneMeta in 24 of 24, inception subProcess 0 of 24 and therefore untested rather than absent-by-defect. Evidence: docs/reports/T-788-executor-ownership-inception.md sections 7.2 and 8. THE OPERATOR'S GO INSTINCT WAS NOT WRONG, IT WAS AIMED AT A DIFFERENT LAYER: T-797 measured that nothing anywhere models a workflow RUN, and T-798 found those runs already exist unmodelled - roughly 1500 across 7 designs, with workflow_type already carrying the class name as a bare string that never resolves, unlike arc_id which does. That question is now with AEF at sidecar offset 6 and is a SEPARATE decision. This NO-GO closes the compiler question only." )

# ── T-353: the evidence behind the SQ-2 ruling. READ-ONLY. ───────────────────────────────────
T353_WHY="Read-only. Runs the repair probe that T-353's Human AC points at, so the ruling rests
  on a number you watched rather than one you were told. Expect: probe: 23 passed, 0 failed.
  (The AC still says 16/16 — that citation decayed and was repaired in T-787; the probe gained
  7 legs, so the honest count changed.)"
T353_CMD=( bash "$ROOT/tools/_t353-repair-probe.sh" )

CONSEQUENTIAL_t788=1
CONSEQUENTIAL_t353=0

list() {
  b "Pending operator actions — $(date +%Y-%m-%d)"
  echo
  b "  t788-redecide   [CONSEQUENTIAL — Tier 0]"
  echo "$T788_WHY" | sed 's/^/  /'
  echo
  b "  t353-probe      [read-only]"
  echo "$T353_WHY" | sed 's/^/  /'
  echo
  b "NOT RUNNABLE FROM HERE — these need judgement, not a command:"
  cat <<'EOT'

  SQ-2 / T-353 — "may an agent edit ## Verification blocks inside .tasks/completed/?"
    This is an unchecked [REVIEW] Human AC. NEVER tick a ### Human AC on someone's behalf —
    not the agent's to do, and not this script's either. Record yes or no in
    .tasks/active/T-353-prepare-the-corpus-for-the-p-011-errexit.md under ### Human, then:
        fw task update T-353 --status work-completed
    What turns on it: the _t560 ratchet reads 113 against a baseline of 78, and 96 of those
    113 live in .tasks/completed/. Only 17 are in active/. 113 - 17 = 96 > 78, so the
    instrument CANNOT return to baseline by any edit an agent is currently permitted to make.

  IW-3 — does the README's "usable without fw workflow run" non-goal survive the confirmed
    yardstick? A published commitment; retiring one is the operator's call, not an inference.

EOT
  dim "Run one:  ./tools/operator-actions.sh <id>        (confirms first if consequential)"
  dim "Inspect:  ./tools/operator-actions.sh <id> --show (prints it, runs nothing)"
}

# Readable, one argument per line. NOT %q-escaped: the point of showing a command is that a
# human READS it before approving, and %q turns a paragraph of rationale into a wall of
# backslashes nobody reads — the exact reflex this script exists to avoid. It is not meant to
# be copy-pasted; the script runs it.
show_cmd() {
  local first=1 a
  for a in "$@"; do
    if [ $first = 1 ]; then
      printf '  %s' "$a"; first=0
    elif [ "${#a}" -gt 80 ]; then
      printf ' \\\n'
      echo "$a" | fold -s -w 92 | sed 's/^/    /'
    else
      printf ' %s' "$a"
    fi
  done
  [ $first = 0 ] && echo
  return 0
}

run_action() {
  local id="$1" show="${2:-}"
  local -n cmd_ref="$3" why_ref="$4"
  local consequential="$5"

  b "$id"
  echo "$why_ref" | sed 's/^/  /'
  echo
  b "Command:"
  show_cmd "${cmd_ref[@]}"
  echo

  if [ "$show" = "--show" ]; then
    dim "(--show: nothing was run)"
    return 0
  fi

  if [ "$consequential" = "1" ]; then
    # A consequential action gets an explicit, typed confirmation. y/N is too easy to
    # fat-finger for something that writes a sovereignty record.
    printf 'Type the action id to confirm (%s), anything else to abort: ' "$id"
    read -r reply
    if [ "$reply" != "$id" ]; then
      echo "aborted — nothing was run."
      return 1
    fi
  fi

  "${cmd_ref[@]}"
}

case "${1:-}" in
  ""|list|--list|-l) list ;;
  t788-redecide) run_action t788-redecide "${2:-}" T788_CMD T788_WHY "$CONSEQUENTIAL_t788" ;;
  t353-probe)    run_action t353-probe    "${2:-}" T353_CMD T353_WHY "$CONSEQUENTIAL_t353" ;;
  -h|--help) list ;;
  *) echo "unknown action: $1" >&2; echo >&2; list >&2; exit 2 ;;
esac
