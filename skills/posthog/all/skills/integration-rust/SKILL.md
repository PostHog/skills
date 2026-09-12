---
name: integration-rust
description: PostHog integration for Rust applications using the posthog-rs SDK
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Rust

This skill helps you add PostHog analytics to Rust applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Rust example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/rust.md` - Rust - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-rs is the Rust SDK crate; add it with `cargo add posthog-rs` and construct the client with `posthog_rs::client(options).await`
- Create one client per process and share it (for example an `Arc` in your app state or a `OnceCell`); do not build a new client per request or task
- Configure the project token and host from environment variables via `ClientOptions` (the `(api_key, host)` tuple); never hardcode PostHog secrets
- Because `capture` is fire-and-forget, call `client.flush().await` then `client.shutdown().await` before the process exits — where the server future resolves. An app with no shutdown path still needs this; add the calls there rather than skipping them so queued events are delivered before exit
- Server-side captures must set a stable `distinct_id` on `Event::new(event, distinct_id)` that matches frontend identify calls; avoid anonymous or literal IDs for business events
- The SDK has no `identify` or `alias` helper; set person properties by inserting a `$set` property on an event
- For feature flags, call `client.evaluate_flags(distinct_id, EvaluateFlagsOptions::default()).await` once per user/request, then read values from the returned snapshot with `is_enabled(...)`
- For error tracking, use `client.capture_exception_with(&err, CaptureExceptionOptions::new()...)`; the `error-tracking` feature is enabled by default in recent versions
- The Rust SDK has no surveys or session replay support; do not promise or scaffold those features

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
