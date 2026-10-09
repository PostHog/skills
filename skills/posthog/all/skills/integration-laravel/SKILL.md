---
name: integration-laravel
description: PostHog integration for Laravel applications
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Laravel

This skill helps you add PostHog analytics to Laravel applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Laravel example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/laravel.md` - Laravel - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Create a dedicated PostHogService class in app/Services/ - do NOT scatter PostHog::capture calls throughout controllers
- Register PostHog configuration in config/posthog.php using env() for all settings (api_key, host, disabled)
- Do NOT use Laravel's event system or observers for analytics - call capture explicitly where actions occur
- Call PostHog::flush() after capture in queue jobs, Horizon, and Octane - a long-running worker never destructs, so its events sit in the SDK buffer until batch_size (default 100) is reached and are silently lost on restart
- Remember that source code is available in the vendor directory after composer install
- posthog/posthog-php is the PHP SDK package name
- Check composer.json for existing dependencies and autoload configuration before adding new files
- The PHP SDK uses static methods (PostHog::capture, PostHog::identify) - initialize once with PostHog::init()
- PHP SDK methods take associative arrays with 'distinctId', 'event', 'properties' keys - not positional arguments
- Any first-party loader or proxy script you add must load standalone — require its own config includes explicitly rather than assuming the app bootstrapped them

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
