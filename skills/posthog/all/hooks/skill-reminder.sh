#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<IMPORTANT>\nBefore responding, check if any of your PostHog skills apply to this task. Your available skills are listed in your system context. If a skill is relevant and has not been activated in this session, use the Skill tool to activate it.\n</IMPORTANT>"
  }
}
EOF
