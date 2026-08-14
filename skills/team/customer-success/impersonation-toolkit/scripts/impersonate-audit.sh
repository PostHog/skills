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
#   impersonate-audit.sh [options] <account name>
#
# Options:
#   -d, --dir <path>     Override the impersonation root for this run
#       --migrate        Normalise existing folders/files to the current layout
#       --reset-settings Overwrite the shared permissions file from the template
#   -h, --help           Show usage
#
# Configuration (first match wins):
#   --dir flag  >  $CSM_IMPERSONATE_HOME  >  config file  >  ~/impersonate
#
# Every knob is CSM_-prefixed, so you can keep them in your own env file
# (csm.env, ~/.zshrc, whatever) instead of the config file. Defaults reproduce
# the behaviour this script had before these knobs existed:
#   CSM_IMPERSONATE_HOME        default ~/impersonate
#   CSM_CUSTOMER_CONTEXT_DIR    default ~/Documents/Obsidian Vault/Customers,
#                               used only if that directory actually exists
#   CSM_IMPERSONATE_CONFIG      default ${XDG_CONFIG_HOME:-~/.config}/impersonate-audit/config
#
# The config file is created (fully commented out) on first run.
#
# Layout — Claude runs at the root, so one settings file covers every account:
#   $CSM_IMPERSONATE_HOME/                 working directory for every session
#   ├── .claude/settings.local.json        shared permissions, merged not clobbered
#   └── <account-slug>/YYYY-MM-DD.md       one audit per account per day
#
# Flow:
#   1. Resolve config, slugify the account name, create its folder
#   2. Remind you to impersonate the customer's user in Django Admin (manual)
#   3. Remind you to /mcp re-auth the posthog plugin inside Claude Code
#   4. Launch `claude` at the root, with the account's folder ready for output
#   5. On Claude exit, print cleanup reminders

set -euo pipefail

CONFIG_FILE="${CSM_IMPERSONATE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/impersonate-audit/config}"

# Where per-account notes lived before this was configurable. Still the default,
# but only honoured if the directory is actually there.
DEFAULT_CONTEXT_DIR="$HOME/Documents/Obsidian Vault/Customers"

# The settings template ships alongside this script inside the plugin.
# $BASH_SOURCE resolves to the actual script path (the shim in ~/bin/
# `exec`s here, so we land at the plugin cache location).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_FILE="$PLUGIN_DIR/assets/settings.local.json"

usage() {
  cat <<'EOF'
Usage: impersonate-audit [options] <account name>

  impersonate-audit globex
  impersonate-audit "Acme Inc"          -> ~/impersonate/acme-inc/
  impersonate-audit --dir ~/work/audits acme

Options:
  -d, --dir <path>     Impersonation root for this run (overrides config + env)
      --migrate        Normalise existing folders/files to the current layout
      --reset-settings Overwrite the shared permissions file from the template
  -h, --help           Show this help

Config file: ${XDG_CONFIG_HOME:-~/.config}/impersonate-audit/config
Anything you export in your own env file (csm.env, ~/.zshrc, ...) wins over it:
  CSM_IMPERSONATE_HOME=...       account folders live here (default ~/impersonate)
  CSM_CUSTOMER_CONTEXT_DIR=...   your per-account notes live here (default
                                 ~/Documents/Obsidian Vault/Customers if present,
                                 otherwise the notes step is skipped)
EOF
}

# ---------------------------------------------------------------- arguments

CLI_HOME=""
MODE="run"
RESET_SETTINGS=0
POSITIONAL=()

while (($#)); do
  case "$1" in
    -d|--dir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --dir needs a path" >&2
        exit 1
      fi
      CLI_HOME="$2"
      shift 2
      ;;
    --migrate)
      MODE="migrate"
      shift
      ;;
    --reset-settings)
      RESET_SETTINGS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while (($#)); do
        POSITIONAL+=("$1")
        shift
      done
      ;;
    -*)
      echo "Error: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# Unquoted multi-word names ("Acme Inc") arrive as separate arguments — join
# them back so you don't have to remember the quotes.
ACCOUNT_NAME=""
if ((${#POSITIONAL[@]})); then
  ACCOUNT_NAME="${POSITIONAL[*]}"
fi

# ------------------------------------------------------------------- config

# Env wins over the config file, so snapshot it before sourcing.
ENV_HOME="${CSM_IMPERSONATE_HOME:-}"
ENV_CONTEXT_DIR="${CSM_CUSTOMER_CONTEXT_DIR:-}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" <<'EOF'
# impersonate-audit configuration — plain KEY=VALUE, sourced by the wrapper.
# Uncomment and edit what you want to change. Anything exported in your shell
# (csm.env, ~/.zshrc, ...) wins over this file.

# Where per-account impersonation folders live.
# CSM_IMPERSONATE_HOME="$HOME/impersonate"

# Where your per-account notes live, if you keep any. The audit skill reads the
# matching account's notes from here before writing findings.
# Defaults to "$HOME/Documents/Obsidian Vault/Customers" when that directory
# exists. If it doesn't and you don't set this, the skill skips notes entirely
# rather than hunting around your filesystem.
# CSM_CUSTOMER_CONTEXT_DIR="$HOME/notes/customers"
EOF
  echo "Created config: $CONFIG_FILE"
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

if [[ -n "$ENV_HOME" ]]; then
  CSM_IMPERSONATE_HOME="$ENV_HOME"
fi
if [[ -n "$CLI_HOME" ]]; then
  CSM_IMPERSONATE_HOME="$CLI_HOME"
fi
if [[ -n "$ENV_CONTEXT_DIR" ]]; then
  CSM_CUSTOMER_CONTEXT_DIR="$ENV_CONTEXT_DIR"
fi

CSM_IMPERSONATE_HOME="${CSM_IMPERSONATE_HOME:-$HOME/impersonate}"
CSM_IMPERSONATE_HOME="${CSM_IMPERSONATE_HOME%/}"

# Unset falls back to the old Obsidian location, but only when it's really
# there — otherwise it stays empty and the skill skips the notes step.
CSM_CUSTOMER_CONTEXT_DIR="${CSM_CUSTOMER_CONTEXT_DIR:-}"
if [[ -z "$CSM_CUSTOMER_CONTEXT_DIR" && -d "$DEFAULT_CONTEXT_DIR" ]]; then
  CSM_CUSTOMER_CONTEXT_DIR="$DEFAULT_CONTEXT_DIR"
fi
CSM_CUSTOMER_CONTEXT_DIR="${CSM_CUSTOMER_CONTEXT_DIR%/}"

if [[ "$CSM_IMPERSONATE_HOME" == "$HOME" ]]; then
  echo "Error: CSM_IMPERSONATE_HOME cannot be your home directory." >&2
  echo "       Claude Code won't share one settings file from there. Pick a subfolder." >&2
  exit 1
fi

# ----------------------------------------------------------------- helpers

# Lowercase; accents folded to their base letter; every run of non-alphanumeric
# characters becomes a single hyphen. "Café Söda, Inc." -> cafe-soda-inc
slugify() {
  local s="$1" folded

  # Decompose then drop the combining marks (macOS); fall back to iconv's own
  # transliteration (glibc); fall back to leaving the string alone.
  if folded="$(printf '%s' "$s" | iconv -f UTF-8 -t UTF-8-MAC 2>/dev/null | LC_ALL=C sed $'s/[\xcc\xcd][\x80-\xbf]//g')" && [[ -n "$folded" ]]; then
    s="$folded"
  elif folded="$(printf '%s' "$s" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null)" && [[ -n "$folded" ]]; then
    s="$folded"
  fi

  printf '%s' "$s" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Merge $1 (template or legacy settings) into $2, preserving anything Claude
# Code learned in $2. Entries the template moved between allow/ask follow the
# template. Without jq we leave an existing file alone rather than clobber it.
merge_settings() {
  local src="$1" dst="$2" tmp

  if [[ ! -f "$src" ]]; then
    return 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️  jq not found — leaving $dst as-is. Use --reset-settings to overwrite it." >&2
    return 0
  fi

  tmp="$(mktemp "${dst}.XXXXXX")"
  if jq -s '
        .[0] as $tpl | .[1] as $cur
        | (($cur.permissions.allow // []) - ($tpl.permissions.ask   // []) + ($tpl.permissions.allow // []) | unique) as $allow
        | (($cur.permissions.ask   // []) - ($tpl.permissions.allow // []) + ($tpl.permissions.ask   // []) | unique) as $ask
        | $cur * { permissions: (($cur.permissions // {}) + { allow: $allow, ask: $ask }) }
      ' "$src" "$dst" > "$tmp"; then
    mv "$tmp" "$dst"
  else
    rm -f "$tmp"
    echo "⚠️  Could not merge permissions into $dst (invalid JSON?). Left untouched." >&2
  fi
}

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy] ]]
}

# Rename $1 to $2. Returns 2 on a genuine collision. On case-insensitive
# filesystems "InitechCo" and "initechco" are the same path, so a case-only
# rename has to bounce through a temporary name.
rename_path() {
  local from="$1" to="$2" tmp
  if [[ "$from" == "$to" ]]; then
    return 0
  fi
  if [[ -e "$to" ]]; then
    if [[ ! "$from" -ef "$to" ]]; then
      return 2
    fi
    tmp="${from}.rename-$$"
    mv "$from" "$tmp"
    mv "$tmp" "$to"
    return 0
  fi
  mv "$from" "$to"
}

# ------------------------------------------------------------ settings root

# Claude launches at the impersonation root, so one .claude/settings.local.json
# there covers every account — including the permissions you approve
# mid-session. Account folders are output, not workspaces.
#
# One wrinkle: if the root sits inside a git repo (someone keeping audits in
# their notes repo, say), Claude Code resolves project settings to that repo's
# root instead. Follow it rather than writing a file that would be ignored.
SETTINGS_ROOT="$CSM_IMPERSONATE_HOME"
GIT_TOP=""

mkdir -p "$CSM_IMPERSONATE_HOME"

if command -v git >/dev/null 2>&1; then
  if GIT_TOP="$(git -C "$CSM_IMPERSONATE_HOME" rev-parse --show-toplevel 2>/dev/null)" \
     && [[ -n "$GIT_TOP" && "$GIT_TOP" != "$HOME" ]]; then
    SETTINGS_ROOT="$GIT_TOP"
  fi
fi

# ---------------------------------------------------------------- migration

# Fold a legacy layout into the current one: "Acme Inc" -> acme-inc,
# audit-2026-08-11.md -> 2026-08-11.md, per-account permissions -> shared file.
migrate_all() {
  local entry base slug target legacy_settings moved=0 renamed=0 folded=0

  shopt -s nullglob
  for entry in "$CSM_IMPERSONATE_HOME"/*/; do
    entry="${entry%/}"
    base="$(basename "$entry")"
    [[ "$base" == ".claude" ]] && continue
    slug="$(slugify "$base")"
    target="$CSM_IMPERSONATE_HOME/$slug"

    if [[ "$base" != "$slug" ]]; then
      if rename_path "$entry" "$target"; then
        echo "  move  $base -> $slug"
        entry="$target"
        moved=$((moved + 1))
      else
        echo "  skip  $base -> $slug (a different folder already uses that name)"
      fi
    fi

    local audit
    for audit in "$entry"/audit-*.md; do
      local newname
      newname="$(basename "$audit")"
      newname="${newname#audit-}"
      if rename_path "$audit" "$entry/$newname"; then
        echo "  file  $(basename "$entry")/$(basename "$audit") -> $newname"
        renamed=$((renamed + 1))
      else
        echo "  skip  $(basename "$audit") -> $newname (target already exists)"
      fi
    done

    legacy_settings="$entry/.claude/settings.local.json"
    if [[ -n "$SETTINGS_ROOT" && -f "$legacy_settings" && "$entry" != "$SETTINGS_ROOT" ]]; then
      merge_settings "$legacy_settings" "$SETTINGS_ROOT/.claude/settings.local.json"
      rm -f "$legacy_settings"
      rmdir "$entry/.claude" 2>/dev/null || true
      echo "  perms $(basename "$entry")/.claude/settings.local.json -> shared file"
      folded=$((folded + 1))
    fi
  done
  shopt -u nullglob

  echo
  echo "Migrated: $moved folder(s) renamed, $renamed audit file(s) renamed, $folded permissions file(s) folded in."
}

if [[ "$MODE" == "migrate" ]]; then
  echo "Migrating $CSM_IMPERSONATE_HOME to the current layout."
  echo "Folders become lowercase-hyphenated, audit-<date>.md becomes <date>.md, and"
  echo "per-account permissions merge into the shared file at the root."
  echo
  if confirm "Proceed?"; then
    migrate_all
  else
    echo "Nothing changed."
  fi
  exit 0
fi

# --------------------------------------------------------------- run set-up

if [[ -z "$ACCOUNT_NAME" ]]; then
  usage >&2
  exit 1
fi

ACCOUNT_SLUG="$(slugify "$ACCOUNT_NAME")"
if [[ -z "$ACCOUNT_SLUG" ]]; then
  echo "Error: '$ACCOUNT_NAME' has no usable characters for a folder name." >&2
  exit 1
fi

ACCOUNT_DIR="$CSM_IMPERSONATE_HOME/$ACCOUNT_SLUG"

# Offer to pick up a pre-slug folder for this same account rather than starting
# an empty one next to it. Case-only differences count: on a case-insensitive
# filesystem "InitechCo" already answers to "initechco", but the folder still
# shows up mixed-case until it's renamed.
shopt -s nullglob
for candidate in "$CSM_IMPERSONATE_HOME"/*/; do
  candidate="${candidate%/}"
  if [[ "$(basename "$candidate")" != "$ACCOUNT_SLUG" && "$(slugify "$(basename "$candidate")")" == "$ACCOUNT_SLUG" ]]; then
    echo "Found an older folder for this account: $(basename "$candidate")"
    if confirm "Rename it to '$ACCOUNT_SLUG'?"; then
      if rename_path "$candidate" "$ACCOUNT_DIR"; then
        echo "Renamed. (Run --migrate to normalise every other account too.)"
      else
        echo "⚠️  A different folder already uses '$ACCOUNT_SLUG' — left as-is." >&2
      fi
    fi
    break
  fi
done
shopt -u nullglob

mkdir -p "$ACCOUNT_DIR"

SETTINGS_FILE="$SETTINGS_ROOT/.claude/settings.local.json"

# A leftover per-account permissions file from the old layout is dead weight now
# that settings live at the root — fold whatever it learned into the shared
# file so those approvals aren't lost, then get rid of it.
LEGACY_SETTINGS="$ACCOUNT_DIR/.claude/settings.local.json"
if [[ "$SETTINGS_ROOT" != "$ACCOUNT_DIR" && -f "$LEGACY_SETTINGS" ]]; then
  merge_settings "$LEGACY_SETTINGS" "$SETTINGS_FILE"
  rm -f "$LEGACY_SETTINGS"
  rmdir "$ACCOUNT_DIR/.claude" 2>/dev/null || true
  echo "Folded this account's old permissions file into the shared one."
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "⚠️  Settings template not found at $TEMPLATE_FILE — skipping permissions setup." >&2
elif ((RESET_SETTINGS)); then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  cp -f "$TEMPLATE_FILE" "$SETTINGS_FILE"
  echo "Permissions reset from the plugin template: $SETTINGS_FILE"
else
  merge_settings "$TEMPLATE_FILE" "$SETTINGS_FILE"
fi

AUDIT_FILE="$ACCOUNT_DIR/$(date +%Y-%m-%d).md"

# Derived from the account name you passed — none of these are yours to set.
# The audit skill reads them instead of guessing paths or searching for notes.
export CSM_IMPERSONATE_HOME
export CSM_IMPERSONATE_ACCOUNT="$ACCOUNT_SLUG"
export CSM_IMPERSONATE_ACCOUNT_NAME="$ACCOUNT_NAME"
export CSM_IMPERSONATE_ACCOUNT_DIR="$ACCOUNT_DIR"
export CSM_IMPERSONATE_AUDIT_FILE="$AUDIT_FILE"
export CSM_CUSTOMER_CONTEXT_DIR

# Session ID lets you correlate refusal-log entries with the raw-error debug
# log — `jq 'select(.session_id == "...")'` across both files.
if command -v uuidgen >/dev/null 2>&1; then
  CSM_IMPERSONATE_SESSION_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
else
  CSM_IMPERSONATE_SESSION_ID="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
fi
export CSM_IMPERSONATE_SESSION_ID

# Cross-session refusal log. The skill appends one JSONL entry when it can't
# complete an audit — grep / jq across it to see what's failing over time.
CSM_IMPERSONATE_REFUSAL_LOG="${CSM_IMPERSONATE_REFUSAL_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/impersonate-audit/refusals.log}"
mkdir -p "$(dirname "$CSM_IMPERSONATE_REFUSAL_LOG")"
export CSM_IMPERSONATE_REFUSAL_LOG

# Raw-error debug log. Verbose companion to refusals.log — the skill appends
# raw MCP tool responses, HTTP status, and error class here. Cross-reference
# via session_id.
CSM_IMPERSONATE_DEBUG_LOG="${CSM_IMPERSONATE_DEBUG_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/impersonate-audit/debug.log}"
mkdir -p "$(dirname "$CSM_IMPERSONATE_DEBUG_LOG")"
export CSM_IMPERSONATE_DEBUG_LOG

# Deterministic redactor. Free-text fields written to either log are piped
# through this before write, so token-shaped strings can't survive to disk
# even if the skill mis-classifies them. Ships with the plugin.
CSM_IMPERSONATE_REDACT="${CSM_IMPERSONATE_REDACT:-$SCRIPT_DIR/redact.sh}"
export CSM_IMPERSONATE_REDACT

cd "$CSM_IMPERSONATE_HOME"

cat <<EOF

============================================================
  Impersonation audit — $ACCOUNT_NAME
  Working dir: $CSM_IMPERSONATE_HOME
  Folder:      $ACCOUNT_SLUG/  (notes, exports, scratch files)
  Audit:       $ACCOUNT_SLUG/$(basename "$AUDIT_FILE")
  Perms:       $SETTINGS_FILE
  Session:     $CSM_IMPERSONATE_SESSION_ID
  Refusals:    $CSM_IMPERSONATE_REFUSAL_LOG
  Debug log:   $CSM_IMPERSONATE_DEBUG_LOG
  Redactor:    $CSM_IMPERSONATE_REDACT
EOF

if [[ -n "$CSM_CUSTOMER_CONTEXT_DIR" ]]; then
  echo "  Notes:       $CSM_CUSTOMER_CONTEXT_DIR"
fi

cat <<EOF
============================================================

STEP 1: Impersonate the customer's user in Django Admin
  - Open PostHog Django Admin in your browser
  - Find the user → click "Impersonate" → give a reason
  - Read-only is the default and is what an audit needs. PostHog strips
    write scopes from the token it mints and rejects mutating requests,
    so nothing this session does can change their project.
  - Keep that browser tab open through the whole audit

EOF

read -r -p "Press enter once impersonation is active in your browser..." _

cat <<EOF

STEP 2: Re-authenticate the posthog plugin in Claude Code
  - I'll launch Claude next, in $CSM_IMPERSONATE_HOME
    (audit output lands in $ACCOUNT_SLUG/)
  - Inside Claude Code, type:  /mcp
  - Find 'posthog' → "Clear authentication" → then "Authenticate"
  - A browser tab opens with the PostHog OAuth consent screen. Pick:
      · Scope:        read-only  (an audit reads; it never writes)
      · Organization: the customer's org
      · Project:      the customer's project
    Your Django impersonation session already scopes the token read-only
    regardless of what you click here — the point is to avoid building
    muscle memory of granting write scopes while impersonating.
  - Takes ~10 seconds.
  - Sanity check: ask Claude "what project am I in?" — you should see
    the customer's project, NOT 'PostHog App + Website' (id 2). If you
    see project 2, the impersonation didn't carry — repeat /mcp re-auth
    with the impersonation tab actively focused.

STEP 3: Run the audit
  - Once the project check passes, just say:
      "audit $ACCOUNT_NAME's experiment named '<experiment name>'"
    or, for the whole instance:
      "run an account audit on $ACCOUNT_NAME"
  - The audit skill auto-loads and runs the playbook.

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

if [[ -f "$AUDIT_FILE" ]]; then
  echo "📄 Audit written to $AUDIT_FILE"
  echo
fi

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
