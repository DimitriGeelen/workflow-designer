# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Spike for T-1203: one throwaway TermLink key — does the hub accept it, and does AEF mail still arrive?"
JOB_TASK="T-1203"
JOB_WHY="Your T-1151 GO, step 1. Before 832 gets its real key, prove the two things the research could only read from
docs: (a) the hub accepts a post signed with a key other than the shared host key (hub auth is hub.secret, not the
key), and (b) a sidecar message to AEF still arrives when signed with it. A SCRATCH key is created in
/tmp/t1203-spike (mode 700 dir, key mode 600), used for one probe post on a new topic spike:832-t1203 and one sidecar
message to AEF that says it is a probe, then deleted. This registers a throwaway identity on the shared hub once.
The host key and 832's normal sessions are not touched. Results land in this job's directory for the agent."

D=/tmp/t1203-spike
K="$D/scratch.key"
OUT=.context/runme/043-spike-own-termlink-key
TOPIC="spike:832-t1203"
HOST_FP=d1993c2c3ec44c94
AEF=cacc73ea32b121dd/999-Agentic-Engineering-Framework

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed" 'command -v termlink >/dev/null'
    check "no identity override is set in this shell (the spike sets its own)" '[ -z "${TERMLINK_IDENTITY_FILE:-}${TERMLINK_AGENT_ID:-}${TERMLINK_IDENTITY_DIR:-}" ]'
    check "this shell resolves the shared host key $HOST_FP (read-only resolver)" 'termlink identity show --resolve --no-create 2>/dev/null | grep -q "$HOST_FP"'
    check "no leftover spike dir at $D" '[ ! -e "$D" ]'
}

steps() {
    step "Create the scratch key by posting one probe to $TOPIC (key auto-created at $K, mode 600)" 'do_probe'
    step "Read the probe back: the hub accepted it, signed with the scratch fingerprint" 'do_readback'
    step "Send one sidecar message to AEF signed with the scratch key (it says it is a probe)" 'do_sidecar'
    step "Delete the scratch key and confirm this shell still resolves the host key" 'do_cleanup'
}

do_probe() {
    mkdir -m 700 "$D" || return 1
    TERMLINK_IDENTITY_FILE="$K" termlink channel post "$TOPIC" --ensure-topic --json \
        --payload "832 T-1203 spike probe: a scratch identity testing hub acceptance. Safe to ignore." \
        --metadata from_project=832-Workflow-designer | tee "$OUT/probe-post.json" || return 1
    [ -f "$K" ] || { echo "no key was created at $K"; return 1; }
    echo "key mode: $(stat -c %a "$K")"
    TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create | tee "$OUT/scratch-identity.txt"
    grep -q "$HOST_FP" "$OUT/scratch-identity.txt" && { echo "the scratch key resolved to the HOST fingerprint"; return 1; }
    echo "ok  scratch fingerprint differs from the host key"
}

do_readback() {
    termlink channel subscribe "$TOPIC" --tail 1 --json | tee "$OUT/probe-readback.json" || return 1
    local fp; fp=$(grep -o 'Fingerprint: *[0-9a-f]*' "$OUT/scratch-identity.txt" | awk '{print $2}')
    grep -q "\"sender_id\": *\"$fp\"" "$OUT/probe-readback.json" || { echo "the stored post is not signed by $fp"; return 1; }
    echo "ok  the hub stored the probe signed by the scratch key $fp"
}

do_sidecar() {
    TERMLINK_IDENTITY_FILE="$K" .agentic-framework/bin/fw sidecar send --to "$AEF" \
        --conversation 832-t1151-termlink-identity --json \
        --body "832 T-1203 SPIKE PROBE: this message is signed with a throwaway TermLink key, testing that sidecar mail still arrives before 832 mints its real one. No action needed; please just say whether it reached you and what fingerprint you saw." \
        | tee "$OUT/sidecar-send.json" || return 1
    grep -q '"delivered": *true' "$OUT/sidecar-send.json" && echo "ok  delivered" || { echo "not confirmed delivered (see $OUT/sidecar-send.json)"; return 1; }
}

do_cleanup() {
    rm -f "$K" && rmdir "$D" || { echo "could not remove $D"; return 1; }
    termlink identity show --resolve --no-create | grep -q "$HOST_FP" || { echo "this shell no longer resolves the host key"; return 1; }
    echo "ok  scratch key deleted; host key untouched"
}
