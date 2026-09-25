source /opt/832-Workflow-designer/.agentic-framework/agents/context/lib/safe-commands.sh 2>/dev/null
type is_commit_checkpoint_command &>/dev/null || { echo "REFUSE: new predicate not found"; exit 3; }
t(){ if is_commit_checkpoint_command "$1"; then echo "  ALLOW  $2"; else echo "  BLOCK  $2"; fi; }
R=/opt/832-Workflow-designer; F=$R/.agentic-framework/bin/fw
echo "=== 1.7.68 is_commit_checkpoint_command() — same shapes as T-839 ==="
t "$F git commit -m \"T-1: x\""                      "bare fw git commit"
t "git commit -m \"T-1: x\""                          "bare git commit"
t "cd $R && $F git commit -m \"T-1: x\""              "cd && commit"
t "timeout 300 $F git commit -m \"T-1: x\""           "timeout wrapper  <-- the T-839 defect"
t "cd $R && timeout 300 $F git commit -m \"T-1: x\""  "cd && timeout    <-- the exact shape that stranded T-837/838"
t "env X=1 $F git commit -m \"T-1: x\""               "env wrapper"
t "nice $F git commit -m \"T-1: x\""                  "nice wrapper"
t "echo \"n=\$(wc -l < f)\"; $F git commit -m \"T-1: x\"" "\$(...) substitution"
t "rm -rf /"                                          "negative control (must BLOCK)"
