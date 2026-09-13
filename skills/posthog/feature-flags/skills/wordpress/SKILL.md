---
name: feature-flags-wordpress
description: PostHog feature flags for WordPress applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for WordPress

This skill helps you add PostHog feature flags to WordPress applications.

## Reference files

- `references/php.md` - Php feature flags installation - docs
- `references/wordpress.md` - How to set up wordpress analytics with PostHog - docs
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
- Ship the integration as a standalone plugin in wp-content/plugins - do NOT edit a theme's functions.php, which is lost on theme switch or theme update
- Guard every plugin entry file with `if (!defined('ABSPATH')) { exit; }` before any other code
- Print the client snippet from a wp_head hook and escape the interpolated token with esc_js() - never echo a raw token into markup
- Read the project token from a wp-config.php constant or a WordPress option - do NOT hardcode it in plugin source
- Capture pageviews with the client SDK and reserve PostHog::capture for real server-side WordPress actions (comment_post, woocommerce_thankyou, user_register)
- Call PostHog::flush() at the end of a capture - a web request has no single exit point like a CLI script does
- Evaluate feature flags client-side on pages served by full-page caching (Varnish, batcache, WP Super Cache) - server-side flag checks are baked into the cached HTML for every visitor
- WordPress catches fatals with its own WP_Fatal_Error_Handler and renders the recovery-mode page, so a fatal can be swallowed before a PHP handler reports it - capture exceptions explicitly with PostHog::captureException in a try/catch, and do not rely on WP_DEBUG being on in production to surface them
- Remember that source code is available in the vendor directory after composer install
- posthog/posthog-php is the PHP SDK package name
- Check composer.json for existing dependencies and autoload configuration before adding new files
- The PHP SDK uses static methods (PostHog::capture, PostHog::identify) - initialize once with PostHog::init()
- PHP SDK methods take associative arrays with 'distinctId', 'event', 'properties' keys - not positional arguments
- Any first-party loader or proxy script you add must load standalone — require its own config includes explicitly rather than assuming the app bootstrapped them
