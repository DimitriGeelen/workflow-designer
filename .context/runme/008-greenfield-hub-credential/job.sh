# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Greenfield hub credential: add TermLink profile greenfield-132 from the secret file you placed"
JOB_TASK="T-1106"
JOB_WHY="Your decision (option 1): two-way sidecar with Greenfield. Their messages already reach us; ours
are refused for lack of their hub secret. This is the stopgap; the permanent measure is being researched
(T-1107). BEFORE running: get Greenfield's hub secret from their operator by a route OUTSIDE TermLink
(Signal, in person, or ssh to their host: sudo cat /var/lib/termlink/hub.secret), and write it to
/root/greenfield-hub.secret (one line, 64 hex chars), then: chmod 600 /root/greenfield-hub.secret.
The secret is never printed. Step 1 refuses unless that file is valid. What it grants: full access to
Greenfield's hub (the same kind of access they already hold for ours). Remove later with:
termlink remote profile remove greenfield-132 (and delete its secrets file)."

NAME=greenfield-132
ADDR=192.168.10.132:9100
DROP=/root/greenfield-hub.secret
STORE=/root/.termlink/secrets/$NAME.hex
PEER=aef925c6d2f4ac54/aef-greenfield-test

preflight() {
    check "no TermLink profile named $NAME yet" '! termlink remote profile list 2>/dev/null | grep -q "^$NAME "'
    check "Greenfield hub $ADDR answers on TCP" 'timeout 5 bash -c "</dev/tcp/${ADDR%:*}/${ADDR#*:}"'
    check "the TermLink secrets store exists (files in it are 0600 each)" '[ -d /root/.termlink/secrets ]'
}

steps() {
    step "Check $DROP (exists, root-owned, mode 600, exactly 64 hex chars) and copy it into $STORE (0600)" 'do_install_secret'
    step "Add profile $NAME -> $ADDR using $STORE" 'do_add_profile'
    step "Delete the drop file $DROP (shred)" 'do_remove_drop'
    step "Connect to $NAME (first use pins its certificate) and show the pinned fingerprint to compare with Greenfield" 'do_ping'
    step "Send a sidecar test message to Greenfield on conversation evergreen-trial" 'do_sidecar_test'
    step "Audit the secrets store (perms, size, referenced by a profile)" 'do_audit'
}

do_install_secret() {
    [ -f "$DROP" ] || { echo "no $DROP — place the secret first (see the job description)"; return 1; }
    [ "$(stat -c %U:%a "$DROP")" = root:600 ] || { echo "$DROP must be owned by root with mode 600 (is $(stat -c %U:%a "$DROP"))"; return 1; }
    local v; v=$(tr -d '[:space:]' < "$DROP")
    printf '%s' "$v" | grep -Eqx '[0-9a-fA-F]{64}' || { echo "$DROP is not exactly 64 hex characters (nothing printed)"; return 1; }
    [ ! -e "$STORE" ] || { echo "$STORE already exists — look before overwriting"; return 1; }
    ( umask 077; printf '%s\n' "$v" > "$STORE" ) || return 1
    [ "$(stat -c %a "$STORE")" = 600 ] && echo "ok  secret stored at $STORE (0600), not printed"
}

do_add_profile() {
    termlink remote profile add "$NAME" "$ADDR" --secret-file "$STORE" || return 1
    termlink remote profile list | grep "^$NAME "
}

do_remove_drop() {
    shred -u "$DROP" 2>/dev/null || rm -f "$DROP"
    [ ! -e "$DROP" ] && echo "ok  $DROP removed"
}

do_ping() {
    termlink remote ping "$NAME" || return 1
    echo "Pinned certificate for $ADDR (ask Greenfield's operator to confirm it with: termlink hub fingerprint):"
    termlink tofu list | grep -F "${ADDR%:*}"
}

do_sidecar_test() {
    .agentic-framework/bin/fw sidecar send --to "$PEER" --hub "$ADDR" --conversation evergreen-trial \
        --body "832 -> aef-greenfield-test: sidecar test from 832 after our operator provisioned your hub credential (T-1106). If this arrives, our direction works too; please ack on this conversation."
}

do_audit() {
    termlink fleet secrets-audit
}
