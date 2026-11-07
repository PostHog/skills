---
name: error-tracking-elixir
description: PostHog error tracking for Elixir
metadata:
  author: PostHog
  version: dev
---

# PostHog error tracking for Elixir

This skill helps you add PostHog error tracking to Elixir applications.

## Reference files

- `references/elixir.md` - Elixir error tracking installation - docs
- `references/fingerprints.md` - Fingerprints - docs
- `references/alerts.md` - Send error tracking alerts - docs
- `references/monitoring.md` - Monitor and search issues - docs
- `references/assigning-issues.md` - Assign issues to teammates - docs
- `references/upload-source-maps.md` - Upload source maps - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and host URLs. Never hardcode them.
- **Minimal changes**: Add error tracking alongside existing error handling. Don't replace or restructure existing error handling code.
- **Autocapture first**: Enable exception autocapture in the SDK initialization before adding manual captures.
- **Source maps**: Upload source maps so stack traces resolve to original source code, not minified bundles.
- **Manual capture for boundaries**: Use `captureException()` at error boundaries and catch blocks for errors that don't propagate to the global handler.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-elixir is installed as the `posthog` Hex package; add `{:posthog, "~> 2.0"}` to `mix.exs` and run `mix deps.get`
- Configure PostHog in application config using `api_host`, `api_key`, and `in_app_otp_apps`; read secrets from environment or runtime config, never hardcode them
- In tests, set `test_mode` to true so events are dropped instead of sent to PostHog
- For Phoenix or Plug apps, add `PostHog.Integrations.Plug` before the router so request context is attached to captured events and errors
- Server-side captures must include a stable `distinct_id` matching frontend identify calls, or set it once per process/request with `PostHog.set_context/1`
- Remember `PostHog.set_context/1` uses Logger metadata and is process-scoped; set context in the request, job, or Task process that captures the event
- For new feature flag code, prefer `PostHog.FeatureFlags.evaluate_flags/1` once per user/request, then read values from `PostHog.FeatureFlags.Evaluations`
- To attribute captures to feature flags, call `PostHog.FeatureFlags.set_in_context/1` with the evaluated snapshot, optionally filtered with `only_accessed/1` or `only/2`
- Avoid deprecated feature flag helpers such as `check/2`, `check!/2`, `get_feature_flag_result/2`, and `get_feature_flag_result!/2` in new code
- Error tracking is enabled by default through Logger; set `in_app_otp_apps`, `capture_level`, and `metadata` to improve error grouping and context
- For source context in releases, enable source code context and run `mix posthog.package_source_code` before `mix release`
