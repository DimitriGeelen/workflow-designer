# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Hands T-358 and T-1219 back to the agent so the agent can close them. Both have NO open Human criterion left; the
# framework's own rule (lib/verdict_ledger.py: when none is open the owner goes back to the agent) did not fire for
# them because their last tick did not come through a reviewer verdict. A human-owned task can only be handed over by
# the operator (R-033), so these are operator steps. Nothing is judged here: the operator asked not to be sent
# rubber-stamp closes (2026-11-11); the agent closes both afterwards and runs their verification.
JOB_TITLE="Hand T-358 and T-1219 back to the agent (no open criteria left), so the agent closes them"
JOB_TASK="T-1297"
JOB_WHY="T-358 (no invented lanes or pool, shipped in 0.41.0) and T-1219 have every criterion ticked; nothing is left to
judge. They are still marked as yours only because the framework's hand-back rule fires on a reviewer verdict, and their
last ticks came another way. Only you can hand a human-owned task over (R-033). These two steps do exactly that and
nothing else; the agent then closes both, runs their checks and commits. The gap itself goes to AEF as a proposal.
Answer y at each step."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "T-358 is active, yours, and readable by you" 'f=$(ls .tasks/active/T-358-*.md) && [ -r "$f" ] && grep -q "^owner: human" "$f"'
    check "T-1219 is active, yours, and readable by you" 'f=$(ls .tasks/active/T-1219-*.md) && [ -r "$f" ] && grep -q "^owner: human" "$f"'
    check "neither has an open Human criterion" '! awk "/^### Human/{h=1} /^## /{h=0} h && /^- \\[ \\]/" .tasks/active/T-358-*.md .tasks/active/T-1219-*.md | grep -q .'
}

steps() {
    step_operator "Hand T-358 to the agent (owner: agent)" '.agentic-framework/bin/fw task update T-358 --owner agent --i-am-human'
    step_operator "Hand T-1219 to the agent (owner: agent)" '.agentic-framework/bin/fw task update T-1219 --owner agent --i-am-human'
}
