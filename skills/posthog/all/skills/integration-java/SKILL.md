---
name: integration-java
description: >-
  PostHog integration for Java and Spring Boot applications using the
  posthog-server SDK
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Java (Spring Boot)

This skill helps you add PostHog analytics to Java (Spring Boot) applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Java (Spring Boot) example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/java.md` - Java - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-server is the PostHog Java server SDK; add the `com.posthog:posthog-server` dependency via Gradle or Maven and import from `com.posthog.server`
- Build one client per process with `PostHogConfig.builder(token).host(host).build()` then `PostHog.with(config)`; share the returned `PostHogInterface` (for example as a singleton Spring `@Bean`), never per request
- Read the project token and host from the environment or configuration; never hardcode PostHog secrets
- Flush and close on shutdown with `posthog.flush()` and `posthog.close()` (for a Spring `@Bean`, use `destroyMethod = "close"`) so queued events are delivered before exit
- Server-side captures must pass a stable `distinctId` as the first argument to `capture(...)` that matches frontend identify calls; avoid anonymous or literal IDs for business events
- Identify users by attaching person properties to a capture via `PostHogCaptureOptions.builder().userProperty(...)` / `.userPropertySetOnce(...)`; keep PII in person properties, not event properties
- For feature flags, call `posthog.evaluateFlags(distinctId)` once per request, then read values from the snapshot with `isEnabled("flag-key")` / `getFlagPayload("flag-key")`
- The Java server SDK has no automatic error tracking, surveys, or session replay; do not promise or scaffold those features

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
