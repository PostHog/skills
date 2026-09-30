---
name: integration-go
description: PostHog integration for Go applications using the posthog-go SDK
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Go

This skill helps you add PostHog analytics to Go applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Go example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/go.md` - Go - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

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

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
