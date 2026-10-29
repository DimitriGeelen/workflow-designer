#!/usr/bin/env bash
# _t1340-builtin-pipe-sigpipe-probe.sh — T-1340: a captured MULTI-LINE value piped by bash's builtin printf/echo into
# `grep -q` can fail under pipefail, however small the value is. The builtin writes one line per write(2); grep -q exits
# at its first match, and a line still to be written takes SIGPIPE (141), which pipefail makes the pipeline's status.
# The "capture first, then echo "$out" | grep -q, safe below 64 KiB" rule is wrong for multi-line values. A here-string
# (grep -q PAT <<<"$out") hands grep a file, so nothing is written after grep exits.
#   bash tools/_t1340-builtin-pipe-sigpipe-probe.sh [N]    (default N=3000)
# Exit 0 = the builtin pipe failed at least once and the here-string never did (the cause is shown);
#      1 = the here-string failed (the explanation is wrong); 3 = no builtin failure in N (inconclusive, raise N).
set -uo pipefail
N="${1:-3000}"
multi=$(for i in $(seq 40); do echo "line $i of a captured multi-line value"; done)
pf=0; ec=0; hs=0
for _ in $(seq "$N"); do
    printf '%s' "$multi" | grep -q 'line 1 ' || pf=$((pf + 1))
    echo "$multi" | grep -q 'line 1 ' || ec=$((ec + 1))
    grep -q 'line 1 ' <<<"$multi" || hs=$((hs + 1))
done
echo "of $N runs, a 40-line value matched on its first line, under pipefail:"
echo "  printf '%s' \"\$v\" | grep -q   failed $pf"
echo "  echo \"\$v\" | grep -q          failed $ec"
echo "  grep -q PAT <<<\"\$v\"          failed $hs"
if [ "$hs" -ne 0 ]; then echo "FAIL: the here-string failed too; SIGPIPE is not the explanation"; exit 1; fi
if [ $((pf + ec)) -eq 0 ]; then echo "INCONCLUSIVE: no builtin failure in $N runs (a race; raise N)"; exit 3; fi
echo "CONFIRMED: the builtin pipe fails, the here-string does not"
