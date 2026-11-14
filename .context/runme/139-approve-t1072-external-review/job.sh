# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# `fw review approve` is the operator's act (paid backends need an approved proposal; the agent may not use
# --i-am-human), so it is `step_operator`: listed, never rehearsed, run for real like any step.
JOB_TITLE="Approve one paid external review (about \$0.50) of the revised project objectives (T-1072)"
JOB_TASK="T-1072"
JOB_WHY="You ruled 1a-4a on the objectives today; the revised draft now goes to an outside panel before you ratify it
(T-1072's last criterion). The panel is paid (OpenRouter), so it needs your approval of proposal RP-2a8817eb:
5 models (gpt-4o, gemini-2.5-pro, grok-4.7, deepseek-chat, qwen-2.5-72b), one brief each, about 20,000 tokens in all,
estimated under \$0.50. The brief is docs/reports/T-1072-external-review-brief.md: your own words, AEF's input and the
draft; no secrets, addresses or host names. Answer y to approve; n leaves it unapproved and nothing is sent."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the brief exists" 'test -s docs/reports/T-1072-external-review-brief.md'
}

steps() {
    step_operator "Approve RP-2a8817eb (openrouter, T-1072, est. \$0.50)" '.agentic-framework/bin/fw review approve RP-2a8817eb --i-am-human --reason "Operator approves one external cross-vendor review of the revised objectives (T-1072), est. \$0.50, job 139"'
}
