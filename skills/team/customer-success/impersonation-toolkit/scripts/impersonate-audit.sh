#!/usr/bin/env bash
#
# impersonate-audit.sh — orchestrate a customer impersonation audit via PostHog MCP
#
# Assumes the `posthog` plugin is already installed in Claude Code (one-time
# setup, done previously via `npx @posthog/wizard` or `claude plugin install`).
# This script just shepherds you through re-authing the plugin against a fresh
# impersonation session, runs the audit, and reminds you to clean up.
#
# Usage:
#   impersonate-audit.sh <customer-slug>
#
# Flow:
#   1. Create ~/impersonate/<customer-slug>/ (a place for notes/exports)
#   2. Remind you to impersonate the customer's user in Django Admin (manual)
#   3. Remind you to /mcp re-auth the posthog plugin inside Claude Code
#   4. Launch `claude` in the folder
#   5. On Claude exit, print cleanup reminders

set -euo pipefail

CUSTOMER="${1:-}"
if [[ -z "$CUSTOMER" ]]; then
  echo "Usage: $(basename "$0") <customer-slug>" >&2
  echo "Example: $(basename "$0") givebutter" >&2
  exit 1
fi

DIR="$HOME/impersonate/$CUSTOMER"

# The settings template ships alongside this script inside the plugin.
# $BASH_SOURCE resolves to the actual script path (the shim in ~/bin/
# `exec`s here, so we land at the plugin cache location).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_FILE="$PLUGIN_DIR/assets/settings.local.json"

mkdir -p "$DIR"
cd "$DIR"

# Refresh per-folder permission rules from the plugin's template every run,
# so plugin updates (`claude plugin update`) propagate to every customer
# folder on next launch.
if [[ -f "$TEMPLATE_FILE" ]]; then
  mkdir -p "$DIR/.claude"
  cp -f "$TEMPLATE_FILE" "$DIR/.claude/settings.local.json"
else
  echo "⚠️  Settings template not found at $TEMPLATE_FILE — skipping permissions setup." >&2
fi

cat <<EOF

============================================================
  Impersonation audit — $CUSTOMER
  Folder: $DIR  (use it for notes, exports, scratch files)
============================================================

STEP 1: Impersonate the customer's user in Django Admin
  - Open PostHog Django Admin in your browser
  - Find the user → click "Impersonate" → select read-only scope
    (read+write is only needed if you'll create something in their account
    during the audit — e.g. an example experiment or dashboard. Default
    to read-only.)
  - Keep that browser tab open through the whole audit

EOF

read -r -p "Press enter once impersonation is active in your browser..." _

cat <<EOF

STEP 2: Re-authenticate the posthog plugin in Claude Code
  - I'll launch Claude in this folder next
  - Inside Claude Code, type:  /mcp
  - Find 'posthog' → "Clear authentication" → then "Authenticate"
  - A browser tab opens; it'll pick up your active impersonation session
    and bind a fresh token. Takes ~10 seconds.
  - Sanity check: ask Claude "what project am I in?" — you should see
    the customer's project, NOT 'PostHog App + Website' (id 2). If you
    see project 2, the impersonation didn't carry — repeat /mcp re-auth
    with the impersonation tab actively focused.

STEP 3: Run the audit
  - Once the project check passes, just say:
      "audit <customer>'s experiment named '<experiment name>'"
  - The experiment-audit skill auto-loads and runs the playbook.

EOF

read -r -p "Press enter to launch Claude Code..." _

# Make sure the plugin is enabled before launching (it may have been
# disabled at the end of a previous run)
claude plugin enable posthog >/dev/null 2>&1 || true

claude || true

echo
echo "============================================================"
echo "  Teardown"
echo "============================================================"
echo

PLUGIN_STATUS=$(claude mcp list 2>/dev/null | grep "plugin:posthog" | head -1 || true)

if echo "$PLUGIN_STATUS" | grep -q "Connected"; then
  echo "⚠️  Impersonation MCP is still connected. Disabling now..."
  echo
  claude plugin disable posthog
  echo
  echo "✅ Plugin disabled."
  echo
  echo "One thing left for you: log out of Django Admin in your browser."
else
  echo "✅ Impersonation MCP is already disconnected."
  echo
  echo "One thing left for you: log out of Django Admin in your browser."
fi
echo
