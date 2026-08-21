#!/usr/bin/env bash
# Tells you when your copy of this skill is behind the published one.
# Checks at most once a day. Prints nothing when current, so it is safe to call every run.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_MANIFEST="$SKILL_DIR/.claude-plugin/plugin.json"
REMOTE_URL="https://raw.githubusercontent.com/PostHog/skills/main/skills/team/onboarding/posthog-customer-deep-dive/.claude-plugin/plugin.json"
STAMP="${TMPDIR:-/tmp}/posthog-deep-dive-version-check"

[ "$(cat "$STAMP" 2>/dev/null)" = "$(date +%F)" ] && exit 0
date +%F > "$STAMP" 2>/dev/null || true

read_version() { python3 -c "import json,sys; print(json.load(sys.stdin).get('version',''))" 2>/dev/null; }

[ -f "$LOCAL_MANIFEST" ] || exit 0
LOCAL="$(read_version < "$LOCAL_MANIFEST")"
REMOTE="$(curl -fsS --max-time 5 "$REMOTE_URL" 2>/dev/null | read_version)"

# No answer means offline or the path moved. Silence beats a false alarm.
[ -n "$LOCAL" ] && [ -n "$REMOTE" ] || exit 0
[ "$LOCAL" = "$REMOTE" ] && exit 0

# Sort tells us which way the difference runs; a local copy ahead of main is the author mid-edit.
NEWEST="$(printf '%s\n%s\n' "$LOCAL" "$REMOTE" | sort -V | tail -1)"
[ "$NEWEST" = "$LOCAL" ] && exit 0

cat <<MSG
This skill is on $LOCAL; the published version is $REMOTE.

  claude plugin marketplace update PostHog-skills
  claude plugin update posthog-customer-deep-dive@PostHog-skills

Restart Claude Code afterwards. Installed by copying the folder instead? Re-copy it
from https://github.com/PostHog/skills, or git pull in your checkout.
MSG
