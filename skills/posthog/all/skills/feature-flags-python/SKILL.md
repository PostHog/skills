---
name: feature-flags-python
description: PostHog feature flags for Python applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog feature flags for Python

This skill helps you add PostHog feature flags to Python applications.

## Reference files

- `references/python.md` - Python feature flags installation - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Feature flag best practices - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

## Framework guidelines

- Remember that source code is available in the venv/site-packages directory
- posthog is the Python SDK package name
- Install dependencies with `pip install posthog` or `pip install -r requirements.txt` and do NOT use unquoted version specifiers like `>=` directly in shell commands
- In CLIs and scripts: MUST call posthog.shutdown() before exit or all events are lost
- Always use the Posthog() class constructor (instance-based API) instead of module-level posthog.api_key config
- Always include enable_exception_autocapture=True in the Posthog() constructor to automatically track exceptions
- NEVER send PII in capture() event properties — no emails, full names, phone numbers, physical addresses, IP addresses, or user-generated content
- PII belongs in identify() person properties, NOT in capture() event properties. Safe event properties are metadata like message_length, form_type, boolean flags.
- Register posthog_client.shutdown with atexit.register() to ensure all events are flushed on exit
- The Python SDK has NO identify() method — use posthog_client.set(distinct_id=user_id, properties={...}) to set person properties, or use identify_context(user_id) within a context
