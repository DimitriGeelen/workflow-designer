# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Mint 832's own TermLink signing key (T-1203, your T-1151 GO): create once, lock down, back up, record the fingerprint"
JOB_TASK="T-1203"
JOB_WHY="Your T-1151 GO, step 2. The spike (job 043) proved the hub and AEF accept a non-host key. This creates 832's
real key ONCE at .context/secrets/termlink-identity.key (gitignored), LOCALLY: nothing is posted to the hub and no
session switches to it yet (that is the rollout, a later job). The key is created by TermLink's own resolver pointed at
that absolute path; 'termlink identity init' is NOT used because it writes the shared host key. The directory carries
a default ACL that names user dimitri-mint-dev; the job strips extended ACLs from the key so only root can read it,
and copies it to /root/.termlink-project-keys/ (mode 700) as a backup. Losing the key means a new fingerprint and a
second announcement, so you may want an off-host copy of that backup too. The fingerprint (public) is written to a
tracked file; the key itself never enters git."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
BK_DIR=/root/.termlink-project-keys
BK="$BK_DIR/832-Workflow-designer.key"
FPF="$ROOT/.context/termlink-identity.fingerprint"
HOST_FP=d1993c2c3ec44c94

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the key path is gitignored" 'git check-ignore -q "$K"'
    check "no key exists yet at $K" '[ ! -e "$K" ]'
    check "no backup exists yet at $BK" '[ ! -e "$BK" ]'
    check "no identity override is set in this shell" '[ -z "${TERMLINK_IDENTITY_FILE:-}${TERMLINK_AGENT_ID:-}${TERMLINK_IDENTITY_DIR:-}" ]'
    check "this shell resolves the shared host key $HOST_FP (read-only)" 'termlink identity show --resolve --no-create 2>/dev/null | grep -q "$HOST_FP"'
    check "setfacl and getfacl are available" 'command -v setfacl >/dev/null && command -v getfacl >/dev/null'
}

steps() {
    step "Create the key at $K (TermLink resolver, local only) and lock it down (mode 600, no extended ACL)" 'do_mint'
    step "Back it up to $BK (dir mode 700) and verify the copy is identical" 'do_backup'
    step "Record the public fingerprint in .context/termlink-identity.fingerprint; confirm git sees no key" 'do_record'
}

do_mint() {
    TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve | tee /dev/stderr | grep -q 'Fingerprint' || return 1
    [ -f "$K" ] || { echo "no key was created at $K"; return 1; }
    setfacl -b "$K" && chmod 600 "$K" || return 1
    [ "$(stat -c %a "$K")" = 600 ] || { echo "mode is $(stat -c %a "$K"), not 600"; return 1; }
    getfacl -p "$K" 2>/dev/null | grep -q '^user:' && { echo "an extended ACL entry is still present"; return 1; }
    TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create | grep -q "$HOST_FP" && { echo "it resolved to the HOST key"; return 1; }
    echo "ok  key created, mode 600, no extended ACL, not the host key"
}

do_backup() {
    install -d -m 700 "$BK_DIR" || return 1
    install -m 600 "$K" "$BK" || return 1
    cmp -s "$K" "$BK" || { echo "backup differs from the key"; return 1; }
    echo "ok  backup at $BK (mode $(stat -c %a "$BK")), identical"
}

do_record() {
    TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create \
        | grep -E 'Fingerprint|Public key' > "$FPF" || return 1
    cat "$FPF"
    git status --porcelain --ignored -- "$K" | grep -q '^!!' || { echo "git does not report the key as ignored"; return 1; }
    git ls-files --error-unmatch "$K" >/dev/null 2>&1 && { echo "the key is TRACKED"; return 1; }
    termlink identity show --resolve --no-create | grep -q "$HOST_FP" || { echo "this shell no longer resolves the host key"; return 1; }
    echo "ok  fingerprint recorded; key ignored, untracked; this shell still signs with the host key until the rollout"
}
