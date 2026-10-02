#!/usr/bin/env bash
# T-1006: re-run the evidence for one learning-ledger entry against the SHIPPED kit (0.15.2).
# Exit 0 = the lesson's claim reproduces now; non-zero = it does not (the lesson is wrong or stale).
# Usage: bash tools/_t1006-lesson-evidence.sh L19
# Partner notes (Evergreen) live under build/ and are never committed; cases that quote them say
# so and fail loudly when they are absent.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KIT="$ROOT/dist/aef-authoring-kit-0.15.2"
V="$KIT/validate-workflow.py"
CAL="$KIT/calibration"
NOTES="$ROOT/build/evergreen-intake/r1/unpacked/evergreen-iter1/NOTES.md"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
say() { printf '%s\n' "$*"; }
need_notes() { [ -f "$NOTES" ] || { say "partner notes absent: $NOTES"; exit 2; }; }
notes_say() { need_notes; grep -n -- "$1" "$NOTES" | cut -c1-240 | head -3; grep -q -- "$1" "$NOTES"; }
count() { python3 "$V" "$1" 2>&1 | grep -c "$2"; }

# map header shared by the reachability fixtures (YAML form of the validator's input)
hdr() { cat <<'Y'
workflowMeta: {id: t, version: 1, schemaVersion: 2}
pool: {id: Pool_t, name: t}
lanes:
  - {id: a, name: Ops, abbr: ops, authority: initiative, height: 400}
Y
}

case "${1:-}" in
L16)  # a rule shipped in the 0.15.2 inputs that the clean map broke; only the real calibration caught it
  say "-- the rubric line as first drafted (-) and as corrected (+) in 4db14034:"
  git -C "$ROOT" show 4db14034 -- docs/authoring-kit/RUBRIC.md | grep '^[-+] ' | sed 's/^/   /'
  say "-- what the clean control draws there (the construct the draft called 'invented'):"
  grep -o '<bpmn:parallelGateway id="[^"]*"[^>]*>' "$CAL/clean.bpmn" | sed 's/^/   /'
  say "-- the release notes' account of the calibration:"
  grep -n -i -A2 'real calibration' "$ROOT/docs/releases/RELEASE-NOTES-0.15.2.md" | head -6 | sed 's/^/   /'
  say "-- was any rule check against clean.bpmn part of the release path before calibration? kit tests naming clean.bpmn:"
  say "   $(grep -rl 'clean.bpmn' "$ROOT/tests" 2>/dev/null | wc -l) test file(s); release runme mentions calibrate: $(git -C "$ROOT" show 9999dcd2:runme.sh 2>/dev/null | grep -c -i calibrat)"
  git -C "$ROOT" show 4db14034 -- docs/authoring-kit/RUBRIC.md | grep -q '^-.*gateway added there IS invented' ;;
L17)  # loop.sh's agent() appends the prompt as the LAST argv element of KIT_*_CMD
  printf '#!/bin/sh\nfor a; do last=$a; done\nprintf "argv: %%s | last: %%.30s\\n" "$*" "$last"\n' > "$W/agent"; chmod +x "$W/agent"
  eval "$(sed -n '/^agent() {/,/^}/p' "$KIT/loop.sh")"   # loop.sh's own function, verbatim
  ( cd "$W" && agent "$W/agent -p --allowedTools Read Write" "THE-PROMPT" ); out=$(cat "$W/agents.log"); say "$out"
  # a CLI that declares --allowedTools variadic (<tools...>) takes THE-PROMPT as one more tool name
  if command -v claude >/dev/null; then claude --help 2>&1 | grep -E -- '--allowed-?[tT]ools.*\.\.\.' | head -1; fi
  echo "$out" | grep -q 'allowedTools Read Write THE-PROMPT' \
    && ! grep -q -i 'variadic\|must end where' "$KIT/loop.sh" \
    && say "the prompt lands right after a variadic option's values, and loop.sh's header does not warn about it" \
    && say "-- field observation, Evergreen (claude -p as reviewer, kit 0.15.1), their notes and their run log:" \
    && notes_say 'variadic' \
    && { grep -h 'COULD NOT MEASURE' "$(dirname "$NOTES")/calibration/calibrate-r1.log" | sed 's/^/   log: /'; true; } \
    && say "   and after they moved --allowedTools before a single-value flag, the same reviewer measured 3/3 (offset 22)" ;;
L18)  # the clean map's 'accepted orders' branch answers 'Credit limit exceeded?' though the override path also yields accepted orders
  grep -n 'name="accepted orders"' "$CAL/clean.bpmn" | cut -c1-160
  grep -n 'Credit limit exceeded?' "$CAL/clean.bpmn" | cut -c1-120
  grep -n 'accept the order anyway' "$CAL/SOURCE.md"
  say "-- both branches of that gateway (the other one carries the source's words):"
  grep -o 'sourceRef="credit-limit-exceeded" targetRef="[^"]*" name="[^"]*"' "$CAL/clean.bpmn"
  say "-- gateway default attribute present? $(grep -c 'exclusiveGateway id="credit-limit-exceeded"[^>]*default=' "$CAL/clean.bpmn")"
  say "-- the kit's branch-label rule:"; grep -n -A1 'Do not invent conditions' "$KIT/AUTHORING.md" | cut -c1-200
  say "-- the full source text:"; sed 's/^/   | /' "$CAL/SOURCE.md"
  grep -q 'name="accepted orders"' "$CAL/clean.bpmn" && grep -q 'accept the order anyway' "$CAL/SOURCE.md" ;;
L19)  # one link catch turns an event-less map's stated chains into per-node UNREACHABLE + DEADEND
  { hdr; cat <<'Y'
nodes:
  - {uid: a1, type: task, name: A1, lane: a, x: 100, y: 100}
  - {uid: a2, type: task, name: A2, lane: a, x: 200, y: 100}
  - {uid: a3, type: task, name: A3, lane: a, x: 300, y: 100}
  - {uid: b1, type: task, name: B1, lane: a, x: 100, y: 200}
  - {uid: b2, type: task, name: B2, lane: a, x: 200, y: 200}
edges:
  - {uid: e1, source: a1, target: a2}
  - {uid: e2, source: a2, target: a3}
  - {uid: e3, source: b1, target: b2}
Y
  } > "$W/before.yaml"
  { cat "$W/before.yaml"; } | python3 -c '
import sys,yaml; d=yaml.safe_load(sys.stdin)
d["nodes"]+= [{"uid":"in1","type":"linkEventCatch","name":"from P","lane":"a","x":100,"y":300},
              {"uid":"c1","type":"task","name":"C1","lane":"a","x":200,"y":300},
              {"uid":"out1","type":"linkEventThrow","name":"to Q","lane":"a","x":300,"y":300}]
d["edges"]+= [{"uid":"e4","source":"in1","target":"c1"},{"uid":"e5","source":"c1","target":"out1"}]
yaml.safe_dump(d, sys.stdout)' > "$W/after.yaml"
  bu=$(count "$W/before.yaml" "UNREACHABLE"); bd=$(count "$W/before.yaml" "DEADEND")
  au=$(count "$W/after.yaml" "UNREACHABLE"); ad=$(count "$W/after.yaml" "DEADEND")
  say "two stated chains (a1>a2>a3, b1>b2), no events: UNREACHABLE=$bu DEADEND=$bd"
  say "same map + one hand-over catch>C1>throw:          UNREACHABLE=$au DEADEND=$ad (per node, incl. stated chains)"
  [ "$bu" -eq 0 ] && [ "$bd" -eq 0 ] && [ "$au" -ge 5 ] && [ "$ad" -ge 5 ] ;;
L20)  # a catch in front of a step with an unrecorded successor: the step AND the catch each get DEADEND
  { hdr; cat <<'Y'
nodes:
  - {uid: s, type: startEvent, name: S, lane: a, x: 50, y: 100}
  - {uid: t1, type: task, name: T1, lane: a, x: 150, y: 100}
  - {uid: e, type: endEvent, name: E, lane: a, x: 250, y: 100}
  - {uid: in1, type: linkEventCatch, name: from P, lane: a, x: 50, y: 200}
  - {uid: x1, type: task, name: X1, lane: a, x: 150, y: 200}
edges:
  - {uid: f1, source: s, target: t1}
  - {uid: f2, source: t1, target: e}
  - {uid: f3, source: in1, target: x1}
Y
  } > "$W/k11.yaml"
  python3 "$V" "$W/k11.yaml" 2>&1 | grep DEADEND
  out=$(python3 "$V" "$W/k11.yaml" 2>&1)
  echo "$out" | grep -q "DEADEND.*in1" && echo "$out" | grep -q "DEADEND.*x1" \
    && say "one unrecorded successor (after X1) is reported twice: on X1 and on the catch in1" \
    && grep -n 'a catch as an entry, so neither draws a reachability warning' "$KIT/AUTHORING.md" | cut -c1-140 \
    && say "...while AUTHORING.md says a catch draws no reachability warning: guide and validator disagree" ;;
L21)  # the clean control names an end result the source never states, which the kit's own K3 rule forbids
  grep -n -A1 'name="Accepted order delivered and invoiced"' "$CAL/clean.bpmn" | cut -c1-220
  say "-- the kit's K3 rule, in full:"; sed -n '/Do not invent start and end events/,/^- \*\*One step precedes/p' "$KIT/AUTHORING.md" | sed '$d'
  say "-- the full source text (does it state a final result?):"; sed 's/^/   | /' "$CAL/SOURCE.md"
  say "-- 0.15.2 shipped (499c2896) after the K3 rule landed (9999dcd2); was clean.bpmn's end event touched in between?"
  git -C "$ROOT" log --oneline 9999dcd2^..499c2896 -- docs/authoring-kit/calibration/clean.bpmn | sed 's/^/   /'; say "   (no lines = not touched)"
  grep -A1 'name="Accepted order delivered and invoiced"' "$CAL/clean.bpmn" | grep -q 'source: unstated' \
    && ! grep -q -i 'delivered and invoiced' "$CAL/SOURCE.md" && grep -q -i 'Do not invent start and end events' "$KIT/AUTHORING.md" ;;
L22)  # partner hit 'is detailed in process X'; the guide has no rule for it
  notes_say 'K14' && ! grep -q -i -E 'callActivity|calledElement|detailed in' "$KIT/AUTHORING.md" \
    && say "AUTHORING.md (0.15.2) mentions neither callActivity/calledElement nor 'detailed in'" ;;
L23)  # duplicate display names of distinct steps: guide covers duplicate keys only
  notes_say 'K15' && grep -n -i 'duplicate' "$KIT/AUTHORING.md" | cut -c1-160 | head -3
  ! grep -q -i -E 'same (display )?name|duplicate (display )?name' "$KIT/AUTHORING.md" \
    && say "AUTHORING.md (0.15.2) has no rule for two distinct steps sharing a display name" ;;
L24)  # K2 (one step precedes two, relation unstated) speaks of sequence-flow successors only
  say "-- the kit's K2 rule, verbatim:"; sed -n '/One step precedes two, and the source says nothing/,/it is not an invention\./p' "$KIT/AUTHORING.md"
  say "-- L27 (the cross-process form of a hand-over), current wording:"
  python3 -c "import yaml;d=yaml.safe_load(open('$ROOT/docs/learning-ledger.yaml'));x=[e for e in d['learnings'] if e['id']=='L27'][0];print('   ',x['proposed_change'])"
  say "-- the partner's report:"
  notes_say 'K16' && grep -n -i 'both or either\|either or both' "$KIT/AUTHORING.md" | cut -c1-160 | head -3
  ! grep -i 'both or either\|either or both' "$KIT/AUTHORING.md" | grep -q -i 'hand-over\|handover\|link' \
    && say "the both-or-either rule in AUTHORING.md never mentions hand-overs/link events" ;;
L25)  # no citation format for several source lines
  notes_say 'K17' && ! grep -q -i -E 'several (source )?lines|multiple quotes|more than one (line|quote)|quotes? (are )?joined' "$KIT/AUTHORING.md" \
    && say "AUTHORING.md (0.15.2) gives no format for a citation quoting several source lines" ;;
L26)  # 0.15.2 says a parallel fork AND JOIN 'says the same as the plain flows'; true of the fork only
  grep -n -B1 -A1 'A parallel fork (and its join) says the same' "$KIT/AUTHORING.md" | cut -c1-200
  say "-- what clean.bpmn draws there:"
  grep -o '<bpmn:parallelGateway id="[^"]*"[^>]*>' "$CAL/clean.bpmn"
  grep -q 'A parallel fork (and its join) says the same' "$KIT/AUTHORING.md" ;;
L27)  # hand-overs between MAPS are drawn as link events; BPMN 2.0.2 link events connect sections of ONE process
  sed -n '/A hand-over to a step in another map/,/citation\./p' "$KIT/AUTHORING.md"
  say "-- in this product one map file = one bpmn:process (+ its workflowMeta id); the exemplar:"
  grep -c '<bpmn:process ' "$KIT/exemplar.bpmn" | sed 's/^/   bpmn:process elements in exemplar.bpmn: /'
  grep -o '<aef:workflowMeta id="[^"]*"' "$KIT/exemplar.bpmn" | head -1 | sed 's/^/   /'
  say "   targetWorkflow names ANOTHER map's workflowMeta id, i.e. another file and another bpmn:process"
  say "-- does CONFORMANCE.md declare cross-map links as an AEF extension beyond BPMN? matches: $(grep -c -i 'link.*\(extension\|beyond\|not bpmn\|non-standard\)' "$KIT/CONFORMANCE.md")"
  grep -q 'A hand-over to a step in another map' "$KIT/AUTHORING.md" \
    && [ "$(grep -c -i 'link.*\(extension\|beyond\|not bpmn\|non-standard\)' "$KIT/CONFORMANCE.md")" -eq 0 ] ;;
*) say "usage: $0 L16..L27"; exit 64 ;;
esac
