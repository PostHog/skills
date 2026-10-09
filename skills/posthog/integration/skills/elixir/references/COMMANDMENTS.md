# Framework rules

Follow these when integrating PostHog into this framework.

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
