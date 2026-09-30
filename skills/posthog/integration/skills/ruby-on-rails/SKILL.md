---
name: integration-ruby-on-rails
description: PostHog integration for Ruby on Rails applications
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Ruby on Rails

This skill helps you add PostHog analytics to Ruby on Rails applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Ruby on Rails example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/ruby-on-rails.md` - Ruby on rails - docs
- `references/ruby.md` - Ruby - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
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
- Store the project token in Rails credentials or environment variables, never hardcode
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
