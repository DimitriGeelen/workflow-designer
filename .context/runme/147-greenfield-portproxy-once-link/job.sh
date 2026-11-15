# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-968: set Greenfield's 9100 portproxy once (the step its own task cannot do since 11-05), then link 832 to the hub"
JOB_TASK="T-968"
JOB_WHY="Ring20 (msg c1f74189) found why Greenfield's task '\\AEF TermLink reachable' fails: it reads WSL's address from
/root/aef-greenfield-test/.context/working/logs/wsl-ip.txt through \\\\wsl.localhost, which opens files as WSL's default
user. Since 2026-11-05 that is 'dimitri', who cannot enter /root, so every run since has failed ('Access is denied').
The WSL side still works: the file is fresh (rewritten 18:56Z) and the hub runs on 0.0.0.0:9100 inside WSL.
This job does ONCE what that task would do, without editing Greenfield's script (that fix is theirs; the agent tells
them over the link this job opens):
  1 read the address from their own file as WSL root (wsl.exe -d Ubuntu -u root cat), and set the SAME row their
    task sets: portproxy 0.0.0.0:9100 -> <WSL address>:9100. The check reads the LISTEN port only (job 146's check
    matched 9100 inside ring20's 9110 row).
  2 check from here; 3 fetch the hub key from WSL (validated, stored 0600, never printed); 4 prove the link.
Undo for step 1: netsh interface portproxy delete v4tov4 listenport=9100 listenaddress=0.0.0.0
After a reboot the row may be lost again until Greenfield fixes their task."

PROFILE="greenfield"
USERFILE=/opt/832-Workflow-designer/build/greenfield-ssh-user   # absolute: untracked, so a rehearsal clone has none
LOG=.context/runme/147-greenfield-portproxy-once-link

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "termlink is installed here" 'command -v termlink >/dev/null'
    check "the greenfield hub has an address in ~/.termlink/hubs.toml" '[ -n "$(hub_host)" ]'
    check "the login user is recorded (build/greenfield-ssh-user)" '[ -s $USERFILE ]'
}

steps() {
    step_outward "CHANGE: portproxy 0.0.0.0:9100 -> WSL address from Greenfield's own wsl-ip.txt (read as WSL root)" 'pwsh_remote proxy ps_proxy'
    step_outward "Check from here that the greenfield hub answers" 'hub_up'
    step_outward "Fetch the hub key from WSL, validate (64 hex), store it 0600 in TermLink's store (never printed)" 'fetch_secret'
    step_outward "Prove the link: remote doctor and the session list on greenfield" 'prove'
}

hub_host() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^address/{gsub(/[" ]/,"",$0); split($0,a,"="); split(a[2],b,":"); print b[1]; exit}' "$HOME/.termlink/hubs.toml"
}
secret_file() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^secret_file/{sub(/^[^=]*=[ ]*/,"",$0); gsub(/"/,"",$0); print; exit}' "$HOME/.termlink/hubs.toml"
}
login() { echo "$(cat "$USERFILE")@$(hub_host)"; }

# pwsh_remote <name> <script-fn>: PowerShell on the laptop; the step fails unless the script's own end marker returns.
pwsh_remote() {
    local enc out="$LOG/$1.txt"
    enc=$("$2" | iconv -f UTF-8 -t UTF-16LE | base64 -w0) || return 1
    ssh -o ConnectTimeout=15 "$(login)" "powershell -NoProfile -NonInteractive -EncodedCommand $enc" 2>&1 | tr -d '\r' \
        | grep -v -E '^#< CLIXML|^<Objs ' | tee "$out"
    grep -q "^== END OK" "$out" || { echo "The remote script did not finish OK; see $out"; return 1; }
}

ps_proxy() {
    cat <<'PS'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$raw = wsl.exe -d Ubuntu -u root -e cat /root/aef-greenfield-test/.context/working/logs/wsl-ip.txt
$ip = (($raw | Out-String) -split '\s+' | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
if (-not $ip) { "no IPv4 address in Greenfield's wsl-ip.txt"; exit 1 }
"WSL address from Greenfield's own file: $ip"
netsh interface portproxy delete v4tov4 listenport=9100 listenaddress=0.0.0.0 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenport=9100 listenaddress=0.0.0.0 connectport=9100 connectaddress=$ip
if ($LASTEXITCODE -ne 0) { "netsh refused"; exit 1 }
$rows = netsh interface portproxy show v4tov4 | Out-String
$rows
# LISTEN port only: a row whose first two columns are 0.0.0.0 and 9100
if (-not ($rows -match '(?m)^0\.0\.0\.0\s+9100\s')) { "no row listening on 0.0.0.0:9100"; exit 1 }
"== END OK"
PS
}

hub_up() {
    local out
    out=$(timeout 30 termlink fleet status 2>&1 | grep -E "^\s*\S*\s+$PROFILE\s")
    echo "$out"
    case "$out" in *UP*|*auth*|*AUTH*) return 0 ;; esac
    echo "Still not reachable from here (the firewall rule 'TermLink hub 9100: only .107' is the next suspect); tell the agent."
    return 1
}

fetch_secret() {
    local v f; f=$(secret_file)
    [ -n "$f" ] || { echo "no secret_file for [hubs.$PROFILE] in ~/.termlink/hubs.toml"; return 1; }
    v=$(ssh -o ConnectTimeout=15 "$(login)" "wsl.exe -d Ubuntu -u root -e cat /var/lib/termlink/hub.secret" 2>/dev/null | tr -d '\r\n\0 ')
    printf '%s' "$v" | grep -Eqx '[0-9a-fA-F]{64}' || { v=; echo "what came back is not 64 hex characters (nothing printed, nothing stored)"; return 1; }
    mkdir -p "$(dirname "$f")" && ( umask 077; printf '%s\n' "$v" > "$f.new" ) && mv "$f.new" "$f" && chmod 600 "$f"
    v=
    echo "stored in $f (0600, $(wc -c < "$f") bytes; value not printed)"
}

prove() {
    timeout 60 termlink remote doctor "$PROFILE" && timeout 60 termlink remote list "$PROFILE"
}
