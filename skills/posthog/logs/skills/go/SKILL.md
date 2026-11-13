---
name: logs-go
description: PostHog logs for Go
metadata:
  author: PostHog
  version: dev
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
- posthog-go is the Go SDK package; install it with `go get github.com/posthog/posthog-go` and import `github.com/posthog/posthog-go`
- Create one PostHog client per process with `posthog.NewWithConfig(...)`; do not create a new client per request or job
- Always close the client during graceful shutdown with `client.Close()` so queued events flush before the process exits
- Configure the project token, endpoint, and optional personal API key from environment variables; never hardcode PostHog secrets
- Server-side captures must set `DistinctId` to a stable user ID that matches frontend identify calls; avoid anonymous or literal IDs for business events
- Use `posthog.NewProperties().Set(...)` for event properties and keep PII in person properties via `$set`, not in event properties
- For new feature flag code, prefer `client.EvaluateFlags(...)` once per user/request, then use the returned snapshot's `IsEnabled` or `GetFlag` methods
- When capturing events related to feature-gated code, attach the evaluated flag snapshot with `Flags`, optionally filtered with `OnlyAccessed()` or `Only(...)`
- Avoid deprecated feature flag helpers such as `IsFeatureEnabled`, `GetFeatureFlag`, `GetFeatureFlagPayload`, and `Capture.SendFeatureFlags` in new code
- For error tracking, use `posthog.NewDefaultException(...)` for direct captures or wrap `log/slog` with `posthog.NewSlogCaptureHandler(...)` for automatic warning-and-above exception capture
