#!/bin/bash
# _t1187-aef-pin-lag.sh — is AEF serving 832's latest designer release? (832 T-1187)
#
# Operator 2026-10-17: AEF is the designer's main consumer and the loop must be tight; a release is done only when
# AEF serves it. On that day AEF's pin was 0.14.0, nine releases behind 0.20.0, and nothing in 832 had noticed:
# a release counted as done at the tag. This reads AEF's pin from their PUBLIC bleeding-edge (832 may not read
# AEF's working tree, T-559) and compares it with 832's latest designer tag.
#
#   exit 0  CURRENT   AEF's pin equals 832's latest designer release
#   exit 1  BEHIND    AEF's pin is older; prints how many releases and which
#   exit 2  REFUSED   AEF's pin could not be read (network, moved file, unparseable) — not a pass
#
# Versions compare with sort -V (PL-021: `git ls-remote --tags` sorts lexically, so 0.9.0 sorts after 0.10.0).
set -u
URL="${AEF_PIN_URL:-https://raw.githubusercontent.com/DimitriGeelen/agentic-engineering-framework/bleeding-edge/policy/designer-pin.yaml}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pin=$(curl -fsS --max-time 20 "$URL" 2>/dev/null) || { echo "REFUSED: could not fetch AEF's pin from $URL"; exit 2; }
aef=$(printf '%s\n' "$pin" | sed -n 's/^version: *"\{0,1\}\([0-9][0-9.]*\)"\{0,1\}.*/\1/p' | head -1)
[ -n "$aef" ] || { echo "REFUSED: no 'version:' line in AEF's pin ($URL)"; exit 2; }

ours=$(git -C "$ROOT" tag -l 'designer-v*' | sed 's/^designer-v//' | sort -V | tail -1)
[ -n "$ours" ] || { echo "REFUSED: no designer-v* tag in 832"; exit 2; }

if [ "$aef" = "$ours" ]; then
    echo "CURRENT: AEF serves designer $aef, 832's latest release"
    exit 0
fi
newest=$(printf '%s\n%s\n' "$aef" "$ours" | sort -V | tail -1)
if [ "$newest" = "$aef" ]; then
    echo "REFUSED: AEF pins $aef, newer than 832's latest tag $ours — check the tags"
    exit 2
fi
behind=$(git -C "$ROOT" tag -l 'designer-v*' | sed 's/^designer-v//' | sort -V \
         | awk -v a="$aef" 'f{print} $0==a{f=1}')
n=$(printf '%s\n' "$behind" | grep -c .)
echo "BEHIND: AEF serves designer $aef; 832 has released $n since: $(printf '%s ' $behind)"
exit 1
