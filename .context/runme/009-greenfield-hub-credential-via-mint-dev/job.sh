# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Greenfield hub credential: fetch it AS dimitri-mint-dev over ssh, straight into TermLink's store"
JOB_TASK="T-1106"
JOB_WHY="Replaces job 008, which needed a key file you place by hand. Your direction (2026-10-09): use the
local account dimitri-mint-dev. Step 1 shows Greenfield's ssh host-key fingerprint and records it for
dimitri-mint-dev (first run stopped on 'Host key verification failed': that account had never connected).
Step 2 checks, without fetching anything, that dimitri-mint-dev can ssh to
Greenfield's machine (192.168.10.132) with no password prompt and run sudo there without one; if not, the
job stops and nothing has changed. Step 3 reads /var/lib/termlink/hub.secret over that ssh and writes it
directly into root's TermLink secrets store (0600): never printed, never in a shared or temporary file,
never through TermLink. Then: add profile greenfield-132, connect (pins and shows their hub certificate
fingerprint: ask Greenfield to confirm it), send a sidecar test, audit the store.
What it grants: full access to Greenfield's hub, the same kind they already hold for ours. Greenfield's
owner said the hand-over was parked: run this only if that owner agrees (or is you).
Undo: termlink remote profile remove greenfield-132 and delete /root/.termlink/secrets/greenfield-132.hex."

NAME=greenfield-132
ADDR=192.168.10.132:9100
HOST=192.168.10.132
VIA=dimitri-mint-dev
REMOTE_SECRET=/var/lib/termlink/hub.secret
STORE=/root/.termlink/secrets/$NAME.hex
PEER=aef925c6d2f4ac54/aef-greenfield-test

preflight() {
    check "local account $VIA exists" 'id -u "$VIA" >/dev/null 2>&1'
    check "no TermLink profile named $NAME yet" '! termlink remote profile list 2>/dev/null | grep -q "^$NAME "'
    check "nothing stored for $NAME yet" '[ ! -e "$STORE" ]'
    check "Greenfield hub $ADDR answers on TCP" 'timeout 5 bash -c "</dev/tcp/${ADDR%:*}/${ADDR#*:}"'
    check "the TermLink secrets store exists" '[ -d /root/.termlink/secrets ]'
}

steps() {
    step "Trust Greenfield's machine for ssh: show $HOST's ssh host-key fingerprints, record them in $VIA's known_hosts (your y is the trust decision)" 'do_trust_host'
    step "Check (fetch nothing): $VIA can ssh to $HOST without a password and read $REMOTE_SECRET there with sudo -n" 'do_probe'
    step "Fetch the key as $VIA over ssh, validate it (64 hex chars) and write it straight to $STORE (0600)" 'do_fetch'
    step "Add profile $NAME -> $ADDR using $STORE" 'do_add_profile'
    step "Connect to $NAME (first use pins its certificate) and show the fingerprint to compare with Greenfield" 'do_ping'
    step "Send a sidecar test message to Greenfield on conversation evergreen-trial" 'do_sidecar_test'
    step "Audit the secrets store (perms, size, referenced by a profile)" 'do_audit'
}

do_trust_host() {
    local home kh tmp
    home=$(getent passwd "$VIA" | cut -d: -f6); kh="$home/.ssh/known_hosts"
    if sudo -n -u "$VIA" -H ssh-keygen -F "$HOST" -f "$kh" >/dev/null 2>&1; then echo "ok  $HOST already in $kh"; return 0; fi
    tmp=$(mktemp) || return 1
    ssh-keyscan -T 10 "$HOST" 2>/dev/null > "$tmp"
    [ -s "$tmp" ] || { rm -f "$tmp"; echo "no ssh host key from $HOST (is sshd running there?)"; return 1; }
    echo "ssh host-key fingerprints of $HOST (ask Greenfield's owner to confirm with: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub):"
    ssh-keygen -lf "$tmp"
    sudo -n -u "$VIA" -H mkdir -p "$home/.ssh" && sudo -n -u "$VIA" -H chmod 700 "$home/.ssh" || { rm -f "$tmp"; return 1; }
    sudo -n -u "$VIA" -H tee -a "$kh" < "$tmp" > /dev/null || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    echo "ok  recorded in $kh"
}

as_via() { sudo -n -u "$VIA" -H ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" "$@" </dev/null; }

do_probe() {
    as_via true || { echo "$VIA cannot ssh to $HOST without a password (BatchMode). Nothing fetched."; return 1; }
    echo "ok  $VIA reaches $HOST by ssh"
    as_via "sudo -n test -r $REMOTE_SECRET" || { echo "on $HOST, $VIA cannot read $REMOTE_SECRET with sudo -n (no passwordless sudo, or no such file). Nothing fetched."; return 1; }
    echo "ok  $REMOTE_SECRET is readable there with sudo -n (not read yet)"
}

do_fetch() {
    [ ! -e "$STORE" ] || { echo "$STORE already exists — look before overwriting"; return 1; }
    local v
    v=$(as_via "sudo -n cat $REMOTE_SECRET" | tr -d '[:space:]') || { echo "fetch failed"; return 1; }
    printf '%s' "$v" | grep -Eqx '[0-9a-fA-F]{64}' || { v=; echo "what came back is not 64 hex characters (nothing printed, nothing stored)"; return 1; }
    ( umask 077; printf '%s\n' "$v" > "$STORE" ) || { v=; return 1; }
    v=
    [ "$(stat -c %a "$STORE")" = 600 ] && echo "ok  key stored at $STORE (0600), not printed"
}

do_add_profile() {
    termlink remote profile add "$NAME" "$ADDR" --secret-file "$STORE" || return 1
    termlink remote profile list | grep "^$NAME "
}

do_ping() {
    termlink remote ping "$NAME" || return 1
    echo "Pinned certificate for $ADDR (ask Greenfield to confirm it with: termlink hub fingerprint):"
    termlink tofu list | grep -F "$HOST"
}

do_sidecar_test() {
    .agentic-framework/bin/fw sidecar send --to "$PEER" --hub "$ADDR" --conversation evergreen-trial \
        --body "832 -> aef-greenfield-test: sidecar test from 832 now that our operator installed your hub credential (T-1106). If this arrives, our direction works too; please ack on this conversation."
}

do_audit() {
    termlink fleet secrets-audit
}
