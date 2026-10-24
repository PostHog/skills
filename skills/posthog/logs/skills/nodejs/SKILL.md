---
name: logs-nodejs
description: PostHog logs for Node.js
metadata:
  author: PostHog
  version: dev
---

# PostHog logs for Node.js

This skill helps you add PostHog log ingestion to Node.js applications.

## Reference files

- `references/nodejs.md` - Node.js logs installation - docs
- `references/start-here.md` - Getting started with logs - docs
- `references/search.md` - Search logs - docs
- `references/best-practices.md` - Logging best practices - docs
- `references/troubleshooting.md` - Logs troubleshooting - docs
- `references/link-session-replay.md` - Link session replay - docs
- `references/mcp.md` - Use logs over PostHog mcp - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and OpenTelemetry endpoints. Never hardcode them.
- **Minimal changes**: Add log export alongside existing logging. Don't replace or restructure existing logging code.
- **OpenTelemetry**: PostHog logs use the OpenTelemetry protocol. Configure an OTLP exporter pointed at PostHog's ingest endpoint unless the platform SDK provides native log capture.
- **SDK-native logs**: For Android, React Native, and iOS, use the SDK logger/capture APIs from the platform reference instead of adding a separate OTLP exporter.
- **Structured logging**: Prefer structured log formats with key-value properties over plain text messages.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
