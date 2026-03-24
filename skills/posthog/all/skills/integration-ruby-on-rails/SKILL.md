---
name: integration-ruby-on-rails
description: PostHog integration for Ruby on Rails applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog integration for Ruby on Rails

This skill helps you add PostHog analytics to Ruby on Rails applications.

## Workflow

Follow these steps in order to complete the integration:

1. `basic-integration-1.0-begin.md` - PostHog Setup - Begin ← **Start here**
2. `basic-integration-1.1-edit.md` - PostHog Setup - Edit
3. `basic-integration-1.2-revise.md` - PostHog Setup - Revise
4. `basic-integration-1.3-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Ruby on Rails example project code
- `references/ruby-on-rails.md` - Ruby on rails - docs
- `references/ruby.md` - Ruby - docs
- `references/identify-users.md` - Identify users - docs
- `references/basic-integration-1.0-begin.md` - PostHog setup - begin
- `references/basic-integration-1.1-edit.md` - PostHog setup - edit
- `references/basic-integration-1.2-revise.md` - PostHog setup - revise
- `references/basic-integration-1.3-conclude.md` - PostHog setup - conclusion

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

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

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
