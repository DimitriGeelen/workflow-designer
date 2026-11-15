# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-968: greenfield is a WINDOWS machine — look (read only) where its TermLink hub is: Windows, WSL, port, firewall"
JOB_TASK="T-968"
JOB_WHY="Job 143 showed the greenfield machine answers ssh as 'dimitri' with a Windows cmd.exe shell, so its Linux
commands never ran (its steps 1-2 said ok on ssh's exit code alone; that is fixed here: the step fails unless the
remote script's own end marker comes back). This job only LOOKS, through PowerShell: is termlink installed, is a hub
process running, does anything listen on 9100, which WSL distros exist and whether a hub runs inside them, any
termlink service, and the firewall rules for 9100. Nothing is started or changed. Its output tells the agent how to
start the hub there (next job). Login: the user you gave in job 143 (dimitri), kept in gitignored build/."

PROFILE="greenfield"
USERFILE=/opt/832-Workflow-designer/build/greenfield-ssh-user   # absolute: untracked, so a rehearsal clone has none
OUT=.context/runme/144-greenfield-windows-look/look.txt

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the greenfield hub has an address in ~/.termlink/hubs.toml" '[ -n "$(hub_host)" ]'
    check "the login user from job 143 is recorded (build/greenfield-ssh-user)" '[ -s $USERFILE ]'
}

steps() {
    step_outward "Look (read only, PowerShell over ssh): termlink, hub process, port 9100, WSL, service, firewall" 'look'
}

hub_host() {
    awk -v p="[hubs.$PROFILE]" '$0==p{f=1;next} /^\[/{f=0} f && /^address/{gsub(/[" ]/,"",$0); split($0,a,"="); split(a[2],b,":"); print b[1]; exit}' "$HOME/.termlink/hubs.toml"
}

ps_script() {
    cat <<'PS'
$ErrorActionPreference = 'Continue'
"== whoami: $(whoami) on $env:COMPUTERNAME ($([Environment]::OSVersion.VersionString))"
"== termlink on PATH:"; (Get-Command termlink -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source) ; if (-not (Get-Command termlink -ErrorAction SilentlyContinue)) { "  none" }
"== termlink processes:"; Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*termlink*' } | Format-Table Id, ProcessName, Path -AutoSize | Out-String -Width 200
"== listening on 9100:"; Get-NetTCPConnection -State Listen -LocalPort 9100 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize | Out-String -Width 200
"== services named *termlink*:"; Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*termlink*' -or $_.DisplayName -like '*termlink*' } | Format-Table Name, Status, StartType -AutoSize | Out-String -Width 200
"== scheduled tasks named *termlink*:"; Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*termlink*' } | Format-Table TaskName, State -AutoSize | Out-String -Width 200
"== WSL distros:"; wsl.exe -l -v 2>&1 | ForEach-Object { $_ -replace "`0", "" }
"== inside the default WSL distro (termlink hub process, port 9100):"; wsl.exe -e sh -c 'command -v termlink; pgrep -a -f "termlink.*hub" || echo "  no hub process"; (ss -tln 2>/dev/null || netstat -tln) | grep 9100 || echo "  nothing on 9100"' 2>&1
"== port proxies (netsh portproxy):"; netsh interface portproxy show all
"== firewall rules mentioning 9100 or termlink:"; Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*termlink*' -or $_.DisplayName -like '*9100*' } | Format-Table DisplayName, Direction, Action -AutoSize | Out-String -Width 200
"== END-OF-LOOK"
PS
}

look() {
    local enc
    enc=$(ps_script | iconv -f UTF-8 -t UTF-16LE | base64 -w0) || return 1
    ssh -o ConnectTimeout=15 "$(cat "$USERFILE")@$(hub_host)" "powershell -NoProfile -NonInteractive -EncodedCommand $enc" 2>&1 \
        | tr -d '\r' | tee "$OUT"
    grep -q "== END-OF-LOOK" "$OUT" || { echo "The remote script did not run to its end; see $OUT"; return 1; }
    echo "saved to $OUT"
}
