# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-server is the PostHog Java server SDK; add the `com.posthog:posthog-server` dependency via Gradle or Maven and import from `com.posthog.server`
- Build one client per process with `PostHogConfig.builder(token).host(host).build()` then `PostHog.with(config)`; share the returned `PostHogInterface` (for example as a singleton Spring `@Bean`), never per request
- Read the project token and host from the environment or configuration; never hardcode PostHog secrets
- Flush and close on shutdown with `posthog.flush()` and `posthog.close()` (for a Spring `@Bean`, use `destroyMethod = "close"`) so queued events are delivered before exit
- Server-side captures must pass a stable `distinctId` as the first argument to `capture(...)` that matches frontend identify calls; avoid anonymous or literal IDs for business events
- Identify users by attaching person properties to a capture via `PostHogCaptureOptions.builder().userProperty(...)` / `.userPropertySetOnce(...)`; keep PII in person properties, not event properties
- For feature flags, call `posthog.evaluateFlags(distinctId)` once per request, then read values from the snapshot with `isEnabled("flag-key")` / `getFlagPayload("flag-key")`
- The Java server SDK has no automatic error tracking, surveys, or session replay; do not promise or scaffold those features
