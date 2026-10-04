#!/usr/bin/env bash
# session-start-alerts.sh — what needs attention at /resume, BY NAME (832 T-1046; the /resume
# skill's step 7, AEF T-3327). Local stopgap until AEF vendors theirs. This project has no canary
# runner, so it reports peer mail only; see tools/session-start-alerts.py for what counts as mail.
exec python3 "$(dirname "$0")/../tools/session-start-alerts.py" "$@"
