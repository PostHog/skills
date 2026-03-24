---
name: error-tracking-ruby-on-rails
description: PostHog error tracking for Ruby on Rails
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for Ruby on Rails

This skill helps you add PostHog error tracking to Ruby on Rails applications.

## Reference files

- `references/ruby-on-rails.md` - Ruby on rails error tracking installation - docs
- `references/fingerprints.md` - Fingerprints - docs
- `references/alerts.md` - Send error tracking alerts - docs
- `references/monitoring.md` - Monitor and search issues - docs
- `references/assigning-issues.md` - Assign issues to teammates - docs
- `references/upload-source-maps.md` - Upload source maps - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and host URLs. Never hardcode them.
- **Minimal changes**: Add error tracking alongside existing error handling. Don't replace or restructure existing error handling code.
- **Autocapture first**: Enable exception autocapture in the SDK initialization before adding manual captures.
- **Source maps**: Upload source maps so stack traces resolve to original source code, not minified bundles.
- **Manual capture for boundaries**: Use `captureException()` at error boundaries and catch blocks for errors that don't propagate to the global handler.

## Framework guidelines

- Use posthog-rails gem alongside posthog-ruby for automatic exception capture and ActiveJob instrumentation
- Run `rails generate posthog:install` to create the initializer, or manually create config/initializers/posthog.rb
- Configure auto_capture_exceptions: true to automatically track unhandled exceptions in controllers
- Configure report_rescued_exceptions: true to also capture exceptions that Rails rescues (e.g. with rescue_from)
- Configure auto_instrument_active_job: true to track background job failures with job class, queue, and arguments
- Use PostHog.capture() and PostHog.identify() class-level methods (NOT instance methods) — the posthog-rails gem manages the client lifecycle via PostHog.init
- Do NOT manually create PostHog::Client instances in Rails — use PostHog.init in the initializer and PostHog.capture/identify everywhere else
- capture_exception takes POSITIONAL args: PostHog.capture_exception(exception, distinct_id, additional_properties) — do NOT use keyword args
- Define posthog_distinct_id on the User model for automatic user association in error reports — posthog-rails auto-detects by trying: posthog_distinct_id, distinct_id, id, pk, uuid (in order)
- For ActiveJob user association, use the class-level DSL `posthog_distinct_id ->(user) { user.email }` or pass user_id: in a hash argument
- Store API key in Rails credentials or environment variables, never hardcode
- For frontend tracking alongside posthog-rails, add the posthog-js snippet to the layout template — posthog-js handles pageviews, session replay, and client-side errors while posthog-ruby handles backend events, server errors, feature flags, and background jobs
- posthog-ruby is the Ruby SDK gem name (add `gem 'posthog-ruby'` to Gemfile) but require it with `require 'posthog'` (NOT `require 'posthog-ruby'`)
- Use PostHog::Client.new(api_key: key, host: host) for instance-based initialization in scripts and CLIs
- In CLIs and scripts: MUST call client.shutdown before exit or all events are lost
- Use begin/rescue/ensure with shutdown in the ensure block for proper cleanup
- capture and identify take a single hash argument: client.capture(distinct_id: 'user_123', event: 'my_event', properties: { key: 'value' })
- capture_exception takes POSITIONAL args (not keyword): client.capture_exception(exception, distinct_id, additional_properties) — do NOT use `distinct_id:` keyword syntax
