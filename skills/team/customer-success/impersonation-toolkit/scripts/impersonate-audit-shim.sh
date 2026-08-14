#!/usr/bin/env bash
#
# Launcher for the impersonation-toolkit plugin's wrapper script.
#
# Two independent checks, so a stale copy never gets reported as a missing one:
#   1. installed?  hard error, tells you how to install
#   2. fresh?      warning only (at most once per window), tells you how to update
#
# Knobs:
#   CSM_IMPERSONATE_STALE_DAYS   warn when the plugin cache is older than this
#                                many days (default 1; 0 or empty disables)

set -euo pipefail

CACHE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache/PostHog-skills/impersonation-toolkit"
STALE_DAYS="${CSM_IMPERSONATE_STALE_DAYS-1}"
STAMP="${XDG_STATE_HOME:-$HOME/.local/state}/impersonate-audit/last-stale-warning"

mtime_of() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}

days_since() {
  local mtime
  mtime="$(mtime_of "$1")" || return 1
  [[ -n "$mtime" ]] || return 1
  echo $(( ( $(date +%s) - mtime ) / 86400 ))
}

# 1. Is it installed?
LATEST=""
if [[ -d "$CACHE_DIR" ]]; then
  LATEST="$(find "$CACHE_DIR" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)"
fi

if [[ -z "$LATEST" ]]; then
  echo "impersonation-toolkit is not installed." >&2
  echo "  Inside Claude Code:" >&2
  echo "    /plugin marketplace add PostHog/skills" >&2
  echo "    /plugin install impersonation-toolkit@PostHog-skills" >&2
  exit 1
fi

SCRIPT="$LATEST/scripts/impersonate-audit.sh"
if [[ ! -f "$SCRIPT" ]]; then
  echo "impersonation-toolkit $(basename "$LATEST") is installed but has no wrapper script." >&2
  echo "  Expected: $SCRIPT" >&2
  echo "  Reinstall with: /plugin install impersonation-toolkit@PostHog-skills" >&2
  exit 1
fi

# 2. Is it fresh? Never fatal — you can always run an older copy.
if [[ -n "$STALE_DAYS" && "$STALE_DAYS" != "0" ]]; then
  age="$(days_since "$LATEST" || echo 0)"
  warn_age="$(days_since "$STAMP" 2>/dev/null || echo "")"
  if (( age > STALE_DAYS )) && [[ -z "$warn_age" || "$warn_age" -gt "$STALE_DAYS" ]]; then
    echo "⚠️  impersonation-toolkit $(basename "$LATEST") was installed ${age} day(s) ago." >&2
    echo "    Run '/plugin update' inside Claude Code if you want the latest playbook." >&2
    echo "    (Silence this with CSM_IMPERSONATE_STALE_DAYS=0.)" >&2
    echo >&2
    mkdir -p "$(dirname "$STAMP")"
    touch "$STAMP"
  fi
fi

exec "$SCRIPT" "$@"
