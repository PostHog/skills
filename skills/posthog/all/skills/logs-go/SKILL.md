---
name: logs-go
description: PostHog logs for Go
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog logs for Go

This skill helps you add PostHog log ingestion to Go applications.

## Reference files

- `references/go.md` - Go logs installation - docs
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

_No specific framework guidelines._
