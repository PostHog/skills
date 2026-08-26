---
name: feature-flags-laravel
description: PostHog feature flags for Laravel applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for Laravel

This skill helps you add PostHog feature flags to Laravel applications.

## Reference files

- `references/php.md` - Php feature flags installation - docs
- `references/laravel.md` - Laravel - docs
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
