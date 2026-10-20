# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Set TERMLINK_IDENTITY_NO_CREATE=1 in .claude/settings.json env and the .mcp.json termlink env (T-1203)"
JOB_TASK="T-1203"
JOB_WHY="TermLink 0.12.786 (deployed 2026-10-20, their T-3467) can refuse to mint a key: with
TERMLINK_IDENTITY_NO_CREATE=1 every load-or-create path (CLI posts, session register, the MCP signing key) fails with
'no identity key at <path>' instead of quietly creating one; an existing key loads exactly as before. 832 has been
guarding against an accidental mint by discipline only. This adds the one variable next to TERMLINK_IDENTITY_FILE in the
two files that are yours to change (B-005), and commits them. The runme launcher already sets it for every step.
Best run right AFTER job 057 (the upgrade), as one batch '057 then 058', so the upgrade cannot write the
settings over it. Takes effect for sessions and
the TermLink MCP server started after this; nothing is restarted here. Nothing is pushed."

KEY=/opt/832-Workflow-designer/.context/secrets/termlink-identity.key

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "termlink on PATH is 0.12.786 or newer (knows NO_CREATE)" 'termlink_new_enough'
    check "the project key file exists" '[ -f "$KEY" ]'
    check "both files point TERMLINK_IDENTITY_FILE at the project key" 'settings_point_at_key'
    check "no uncommitted edits to the two files" 'git diff --quiet -- .claude/settings.json .mcp.json'
}

steps() {
    step "Add TERMLINK_IDENTITY_NO_CREATE=1 next to TERMLINK_IDENTITY_FILE in both files (nothing else changes)" 'add_no_create'
    step "Check: both files parse, both carry the key path and NO_CREATE=1, the diff touches only that one key per file" 'check_result'
    step "Commit the two files" 'git add -- .claude/settings.json .mcp.json && git commit -q -m "T-1203: TERMLINK_IDENTITY_NO_CREATE=1 in settings env and .mcp.json termlink env (operator job 058; termlink 0.12.786, 010 T-3467)" && git log --oneline -1'
}

termlink_new_enough() {
    local v
    v=$(termlink --version 2>/dev/null | awk '{print $2}')
    [ -n "$v" ] && [ "$(printf '%s\n%s\n' 0.12.786 "$v" | sort -V | head -1)" = 0.12.786 ]
}

settings_point_at_key() {
    python3 - "$KEY" <<'PY'
import json, sys
k = sys.argv[1]
s = (json.load(open(".claude/settings.json")).get("env") or {}).get("TERMLINK_IDENTITY_FILE")
m = ((json.load(open(".mcp.json"))["mcpServers"].get("termlink") or {}).get("env") or {}).get("TERMLINK_IDENTITY_FILE")
sys.exit(0 if s == k and m == k else 1)
PY
}

add_no_create() {  # a text insert, not a JSON rewrite: .mcp.json's own formatting does not survive json.dump
    python3 - "$KEY" <<'PY'
import re, sys
k = sys.argv[1]
for path in (".claude/settings.json", ".mcp.json"):
    lines = open(path).read().split("\n")
    hits = [i for i, l in enumerate(lines) if re.match(r'\s*"TERMLINK_IDENTITY_FILE": "%s",?\s*$' % re.escape(k), l)]
    if len(hits) != 1:
        sys.exit("%s: expected exactly one TERMLINK_IDENTITY_FILE line, found %d; nothing changed" % (path, len(hits)))
    i = hits[0]
    line = lines[i].rstrip()
    indent = line[:len(line) - len(line.lstrip())]
    trailing = line.endswith(",")
    lines[i] = line if trailing else line + ","
    lines.insert(i + 1, indent + '"TERMLINK_IDENTITY_NO_CREATE": "1"' + ("," if trailing else ""))
    open(path, "w").write("\n".join(lines))
    print("set in", path)
PY
}

check_result() {
    python3 - "$KEY" <<'PY' || return 1
import json, sys
k = sys.argv[1]
s = json.load(open(".claude/settings.json")).get("env") or {}
m = json.load(open(".mcp.json"))["mcpServers"]["termlink"].get("env") or {}
ok = s.get("TERMLINK_IDENTITY_FILE") == k and m.get("TERMLINK_IDENTITY_FILE") == k \
     and s.get("TERMLINK_IDENTITY_NO_CREATE") == "1" and m.get("TERMLINK_IDENTITY_NO_CREATE") == "1"
print("both files: key path and NO_CREATE=1 present" if ok else "MISSING a value")
sys.exit(0 if ok else 1)
PY
    local added removed
    added=$(git diff --numstat -- .claude/settings.json .mcp.json | awk '{a += $1} END {print a + 0}')
    removed=$(git diff --numstat -- .claude/settings.json .mcp.json | awk '{r += $2} END {print r + 0}')
    echo "diff: +$added -$removed"
    [ "$added" -le 4 ] && [ "$removed" -le 2 ] || { echo "the rewrite changed more than the one key per file; nothing committed"; git diff --stat -- .claude/settings.json .mcp.json; return 1; }
}
