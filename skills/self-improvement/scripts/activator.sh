#!/bin/bash
# Self-Improvement Activator Hook
# Triggers on UserPromptSubmit to remind Claude about learning capture
# Keep output minimal (~50-100 tokens) to minimize overhead

set -e

# Output reminder as system context
cat << 'EOF'
<self-improvement-reminder>
After completing this task, evaluate if extractable knowledge emerged:
- Non-obvious solution discovered through investigation?
- Workaround for unexpected behavior?
- Project-specific pattern learned?
- Error required debugging to resolve?

If yes: Derive a stable Pattern-Key and task key, search for an existing learning,
then update its recurrence metadata or create a uniquely identified entry.
If high-value (recurring, broadly applicable): Consider skill extraction.
</self-improvement-reminder>
EOF
