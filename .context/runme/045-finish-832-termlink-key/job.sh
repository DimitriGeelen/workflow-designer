# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Finish 832's TermLink key (T-1203): verify it, back it up, record the public fingerprint (job 044's steps 2-3)"
JOB_TASK="T-1203"
JOB_WHY="Job 044 created the key correctly (fingerprint 05c467b46a0bdf5e, mode 600, no extended ACL) and then stopped
on a bug in the agent's own ACL check, before the backup and the fingerprint record. This job does those two steps,
after re-verifying the key with the corrected check. It creates no key: if the key is missing it stops. Nothing is
posted to the hub and no session switches to the key yet (the rollout is a later job). The backup goes to
/root/.termlink-project-keys/ (mode 700); you may want an off-host copy of it too."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
BK_DIR=/root/.termlink-project-keys
BK="$BK_DIR/832-Workflow-designer.key"
FPF="$ROOT/.context/termlink-identity.fingerprint"
HOST_FP=d1993c2c3ec44c94
FP=05c467b46a0bdf5e

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the key exists at $K" '[ -f "$K" ]'
    check "the key is mode 600" '[ "$(stat -c %a "$K")" = 600 ]'
    check "the key has no extended (named) ACL entry" '! getfacl -p "$K" 2>/dev/null | grep -qE "^(user|group):[^:]"'
    check "the key resolves to $FP without creating anything" 'TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check "the key is gitignored and untracked" 'git check-ignore -q "$K" && ! git ls-files --error-unmatch "$K" >/dev/null 2>&1'
    check "no backup exists yet at $BK" '[ ! -e "$BK" ]'
    check "this shell still resolves the shared host key $HOST_FP" 'termlink identity show --resolve --no-create 2>/dev/null | grep -q "$HOST_FP"'
}

steps() {
    step "Back the key up to $BK (dir mode 700) and verify the copy is identical" 'do_backup'
    step "Record the public fingerprint in .context/termlink-identity.fingerprint" 'do_record'
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
    grep -q "$FP" "$FPF" || { echo "recorded fingerprint is not $FP"; return 1; }
    echo "ok  fingerprint recorded; the key stays ignored and untracked"
}
