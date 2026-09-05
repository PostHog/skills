---
name: feature-flags-rust
description: PostHog feature flags for Rust applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for Rust

This skill helps you add PostHog feature flags to Rust applications.

## Reference files

- `references/rust.md` - Rust feature flags installation - docs
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
- posthog-rs is the Rust SDK crate; add it with `cargo add posthog-rs` and construct the client with `posthog_rs::client(options).await`
- Create one client per process and share it (for example an `Arc` in your app state or a `OnceCell`); do not build a new client per request or task
- Configure the project token and host from environment variables via `ClientOptions` (the `(api_key, host)` tuple); never hardcode PostHog secrets
- Because `capture` is fire-and-forget, call `client.flush().await` then `client.shutdown().await` before the process exits — where the server future resolves. An app with no shutdown path still needs this; add the calls there rather than skipping them so queued events are delivered before exit
- Server-side captures must set a stable `distinct_id` on `Event::new(event, distinct_id)` that matches frontend identify calls; avoid anonymous or literal IDs for business events
- The SDK has no `identify` or `alias` helper; set person properties by inserting a `$set` property on an event
- For feature flags, call `client.evaluate_flags(distinct_id, EvaluateFlagsOptions::default()).await` once per user/request, then read values from the returned snapshot with `is_enabled(...)`
- For error tracking, use `client.capture_exception_with(&err, CaptureExceptionOptions::new()...)`; the `error-tracking` feature is enabled by default in recent versions
- The Rust SDK has no surveys or session replay support; do not promise or scaffold those features
