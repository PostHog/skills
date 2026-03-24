---
name: logs-python
description: PostHog logs for Python
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog logs for Python

This skill helps you add PostHog log ingestion to Python applications.

## Reference files

- `references/python.md` - Python logs installation - docs
- `references/start-here.md` - Getting started with logs - docs
- `references/search.md` - Search logs - docs
- `references/best-practices.md` - Logging best practices - docs
- `references/troubleshooting.md` - Logs troubleshooting - docs
- `references/link-session-replay.md` - Link session replay - docs
- `references/debug-logs-mcp.md` - Debug logs with mcp - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and OpenTelemetry endpoints. Never hardcode them.
- **Minimal changes**: Add log export alongside existing logging. Don't replace or restructure existing logging code.
- **OpenTelemetry**: PostHog logs use the OpenTelemetry protocol. Configure an OTLP exporter pointed at PostHog's ingest endpoint.
- **Structured logging**: Prefer structured log formats with key-value properties over plain text messages.

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
