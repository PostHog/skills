#!/usr/bin/env bash
#
# Discovers all plugins under skills/ and generates .claude-plugin/marketplace.json.
# Run from the repo root: ./scripts/generate-marketplace.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PLUGINS_JSON="[]"

while IFS= read -r plugin_json; do
  PLUGIN_DIR=$(dirname "$(dirname "$plugin_json")")
  REL_PATH="./${PLUGIN_DIR}"

  NAME=$(jq -r '.name // empty' "$plugin_json")
  DESC=$(jq -r '.description // ""' "$plugin_json")
  KEYWORDS=$(jq -c '.keywords // ["posthog"]' "$plugin_json")

  if [ -z "$NAME" ]; then
    echo "  [WARN] Skipping $plugin_json — missing 'name' field" >&2
    continue
  fi

  echo "  Found plugin: $NAME ($REL_PATH)"

  PLUGINS_JSON=$(echo "$PLUGINS_JSON" | jq \
    --arg name "$NAME" \
    --arg source "$REL_PATH" \
    --arg desc "$DESC" \
    --argjson keywords "$KEYWORDS" \
    '. + [{name: $name, source: $source, description: $desc, keywords: $keywords}]')
done < <(find skills -path '*/.claude-plugin/plugin.json' -type f | sort)

PLUGIN_COUNT=$(echo "$PLUGINS_JSON" | jq 'length')
echo "Discovered $PLUGIN_COUNT plugins"

if [ "$PLUGIN_COUNT" -eq 0 ]; then
  echo "No plugins found, skipping marketplace generation" >&2
  exit 0
fi

mkdir -p .claude-plugin
jq -n \
  --argjson plugins "$PLUGINS_JSON" \
  '{
    name: "PostHog-skills",
    owner: { name: "PostHog" },
    metadata: {
      description: "PostHog skills for Claude Code — analytics, feature flags, error tracking, and more"
    },
    plugins: $plugins
  }' > .claude-plugin/marketplace.json

echo "Generated .claude-plugin/marketplace.json with $PLUGIN_COUNT plugins"
