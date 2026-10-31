---
name: feature-flags-go
description: PostHog feature flags for Go applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for Go

This skill helps you add PostHog feature flags to Go applications.

## Reference files

- `references/go.md` - Go feature flags installation - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Best practices for production-ready flags - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

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
