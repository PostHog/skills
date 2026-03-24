---
name: logs-nextjs
description: PostHog logs for Next.js
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog logs for Next.js

This skill helps you add PostHog log ingestion to Next.js applications.

## Reference files

- `references/nextjs.md` - Next.js logs installation - docs
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

- For Next.js 15.3+, initialize PostHog in instrumentation-client.ts for the simplest setup
