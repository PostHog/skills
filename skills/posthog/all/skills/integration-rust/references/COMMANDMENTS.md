# Framework rules

Follow these when integrating PostHog into this framework.

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
