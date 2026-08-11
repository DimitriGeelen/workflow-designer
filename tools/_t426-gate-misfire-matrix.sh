#!/usr/bin/env bash
# _t426-gate-misfire-matrix.sh — the two-sided test for the T-420 rail-attribution gate.
#
# T-426 / OBS-017.
#
# WHY THIS EXISTS
# ---------------
# T-420 shipped with teeth that proved the gate FIRES: block a bad post, confirm nothing
# reached the hub, confirm a good post still lands. Every leg asked the same question in
# a different key — "does it catch a violator?" — and the answer was yes three times.
#
# That suite could not have detected either defect this file was written for:
#
#   FALSE POSITIVE  the gate blocked termlink_inject / remote_inject / emit, none of
#                   which put an envelope on a hub topic, AND printed a remedy naming
#                   `metadata` / `project` — parameters absent from all three schemas.
#                   An unfollowable remedy has only two exits, abandon or bypass, and
#                   neither is recorded anywhere. That is the laundering path OBS-017
#                   was opened to look for, found in my own instrument.
#
#   FALSE NEGATIVE  the gate allowed termlink_agent_contact, exit 0, in silence. It is a
#                   real producer (signed chat envelope, dm topic, retention=forever)
#                   with no from_project channel, carrying content under `message` /
#                   `body_file` — keys the gate does not look at.
#
# The asymmetry is the point: the FPs announced themselves the moment a tool was called,
# while the FN would have stayed green forever, because a gate that passes and a gate
# that never looked are the same observable (PL-109, PL-147).
#
# So this matrix asserts a verdict for BOTH answers on EVERY probed tool. A fix that
# flips an unrelated verdict fails here rather than in production — that is the whole
# reason it prints all rows and not just the failures.
#
# Rows marked LIMIT are the honest edge of the measurement, not passing tests.
#
# Exit 0 = every probed tool produced its expected verdict.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$ROOT/tools/_t420-rail-attribution-gate.py"
LABEL="$(basename "$ROOT")"

pass=0; fail=0

# probe <expected: ALLOW|BLOCK> <name> <json>
probe() {
    local want="$1" name="$2" json="$3" out rc got
    out="$(printf '%s' "$json" | python3 "$GATE" 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then got=ALLOW; else got=BLOCK; fi

    if [ "$got" = "$want" ]; then
        printf '  %-34s %-5s ok\n' "$name" "$got"; pass=$((pass+1))
    else
        printf '  %-34s %-5s FAIL (wanted %s)\n' "$name" "$got" "$want"; fail=$((fail+1))
        printf '%s\n' "$out" | sed 's/^/        | /'
    fi

    # A block whose remedy names a parameter the tool does not have is unfollowable.
    # Checked only on rows that are SUPPOSED to block, so the assertion is about remedy
    # quality rather than about blocking.
    if [ "$got" = BLOCK ] && [ "$want" = BLOCK ]; then
        case "$out" in
            *"Add ONE of:"*)
                case "$json" in
                    *'"metadata"'*|*'"project"'*|*channel_post*|*agent_post*|*agent_reply*) ;;
                    *) printf '        ^ NOTE: generic remedy on a tool that may lack those params\n' ;;
                esac ;;
        esac
    fi
}

echo "=== T-426 gate misfire matrix (label: $LABEL) ==="
echo
echo "class A — producers that CAN attribute (must block only when unattributed)"
probe BLOCK "channel_post no label"      '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"t","payload":"x"}}'
probe ALLOW "channel_post correct label" "{\"tool_name\":\"mcp__termlink__termlink_channel_post\",\"tool_input\":{\"topic\":\"t\",\"payload\":\"x\",\"metadata\":{\"from_project\":\"$LABEL\"}}}"
probe BLOCK "channel_post wrong label"   '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"t","payload":"x","metadata":{"from_project":"010-termlink"}}}'
probe BLOCK "channel_post case-variant"  "{\"tool_name\":\"mcp__termlink__termlink_channel_post\",\"tool_input\":{\"topic\":\"t\",\"payload\":\"x\",\"metadata\":{\"from_project\":\"$(printf '%s' "$LABEL" | tr '[:upper:]' '[:lower:]')\"}}}"
probe ALLOW "agent_post correct project" "{\"tool_name\":\"mcp__termlink__termlink_agent_post\",\"tool_input\":{\"text\":\"x\",\"project\":\"$LABEL\"}}"
probe BLOCK "agent_post no project"      '{"tool_name":"mcp__termlink__termlink_agent_post","tool_input":{"text":"x"}}'

echo
echo "class B — producers that CANNOT attribute (must block, with a followable remedy)"
probe BLOCK "channel_reply"              '{"tool_name":"mcp__termlink__termlink_channel_reply","tool_input":{"topic":"t","text":"x"}}'
probe BLOCK "channel_forward"            '{"tool_name":"mcp__termlink__termlink_channel_forward","tool_input":{"topic":"t","offset":1}}'
probe BLOCK "broadcast"                  '{"tool_name":"mcp__termlink__termlink_broadcast","tool_input":{"payload":"x"}}'
probe BLOCK "agent_contact (T-426 FN)"   '{"tool_name":"mcp__termlink__termlink_agent_contact","tool_input":{"target":"peer","message":"x"}}'
probe BLOCK "agent_contact body_file"    '{"tool_name":"mcp__termlink__termlink_agent_contact","tool_input":{"target":"peer","body_file":"/etc/hostname"}}'

echo
echo "class C — NOT producers (must allow; blocking these printed an unfollowable remedy)"
probe ALLOW "inject (T-426 FP)"          '{"tool_name":"mcp__termlink__termlink_inject","tool_input":{"target":"s","text":"x"}}'
probe ALLOW "remote_inject (T-426 FP)"   '{"tool_name":"mcp__termlink__termlink_remote_inject","tool_input":{"hub":"h:1","session":"s","text":"x"}}'
probe ALLOW "emit payload-as-string"     '{"tool_name":"mcp__termlink__termlink_emit","tool_input":{"target":"s","topic":"t","payload":"{}"}}'
probe ALLOW "emit payload-as-object"     '{"tool_name":"mcp__termlink__termlink_emit","tool_input":{"target":"s","topic":"t","payload":{"a":1}}}'
probe ALLOW "send (params, not content)" '{"tool_name":"mcp__termlink__termlink_send","tool_input":{"target":"s","method":"m","params":"{}"}}'
probe ALLOW "agent_ask (params)"         '{"tool_name":"mcp__termlink__termlink_agent_ask","tool_input":{"target":"s","action":"a","params":"{}"}}'
probe ALLOW "kv_set (value)"             '{"tool_name":"mcp__termlink__termlink_kv_set","tool_input":{"target":"s","key":"k","value":"v"}}'

echo
echo "read-side and non-termlink (must allow)"
probe ALLOW "channel_state_since"        '{"tool_name":"mcp__termlink__termlink_channel_state_since","tool_input":{"topic":"t","since_ms":0}}'
probe ALLOW "channel_list"               '{"tool_name":"mcp__termlink__termlink_channel_list","tool_input":{}}'
probe ALLOW "non-termlink tool"          '{"tool_name":"Bash","tool_input":{"command":"echo payload"}}'

echo
echo "fail-open contract (unparseable input must NOT wedge the session)"
probe ALLOW "empty stdin"                ''
probe ALLOW "malformed json"             '{not json'

echo
cat <<'LIMITS'
LIMIT — measured edges, not assertions:
  * Rule 0 / Rule 2 lists are DECLARED against schemas read 2026-08-11. Any termlink
    tool not probed above and carrying payload/payload_b64/text still BLOCKS. That is
    the deliberate direction: an unknown tool is treated as a possible producer.
  * agent_contact is caught by name (Rule 2), not by content key. A future tool using
    `message`/`body_file` would be a fresh false negative — the FN class is not closed,
    only this instance of it.
  * This matrix probes the gate's DECISION. It does not prove the hook is registered in
    .claude/settings.json; a green matrix over an unregistered gate is PL-147 exactly.
    Registration is asserted separately in T-426's Verification block.
LIMITS

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
