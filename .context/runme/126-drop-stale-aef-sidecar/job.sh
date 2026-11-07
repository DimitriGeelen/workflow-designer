# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY.
# The operator's choice (2026-11-07, "Yeah, those two"): drop the two overdue inbound AEF sidecar items. Both are
# acknowledgements from 2026-10-26 that need no answer and have been overtaken: AEF now serves designer 0.39.0 (pin
# probe CURRENT). `fw sidecar drop` is operator-only (it refuses under CLAUDECODE=1), so both steps are step_operator.
JOB_TITLE="Drop two overdue AEF sidecar acknowledgements (0.29.0 repin, T-4777) that need no answer"
JOB_TASK="T-1297"
JOB_WHY="The handover lists two inbound AEF messages from 2026-10-26 as 'unhandled, overdue':
  889608d4  'Received, thanks: designer 0.29.0 ... we will repin'  (AEF has since moved on and now serves 0.39.0)
  a34acbff  'Thanks, filed as AEF T-4777 ...'                       (a notice; nothing to answer)
Neither needs a reply. Dropping them records the reason and takes them out of the overdue list.
Our own outbound fac4316a (the T-1151 identity thread) is left alone, as you chose. Answer y at each step."

preflight() {
    # The receiver's message store is not committed, so it is not checked here (a clone has none); `fw sidecar drop`
    # itself refuses an id it does not know.
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
}

steps() {
    step_operator "Drop 889608d4 (AEF ack of the 0.29.0 repin, overtaken by 0.39.0)" '.agentic-framework/bin/fw sidecar drop 889608d4-b4dc-40f6-8a96-425b4c6fcec6 --reason "ack of the 0.29.0 repin; overtaken: AEF serves 0.39.0 (pin probe CURRENT, 2026-11-07); no reply needed"'
    step_operator "Drop a34acbff (AEF notice: filed T-4777)" '.agentic-framework/bin/fw sidecar drop a34acbff-7fec-4c70-b4d2-f360a5ce49a1 --reason "notice only: AEF filed T-4777; no reply needed"'
}
