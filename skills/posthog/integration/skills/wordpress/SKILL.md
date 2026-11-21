---
name: integration-wordpress
description: >-
  PostHog integration for self-hosted WordPress sites and plugins, combining
  client-side autocapture with server-side PHP SDK capture
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for WordPress

This skill helps you add PostHog analytics to WordPress applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - WordPress example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/wordpress.md` - How to set up wordpress analytics with PostHog - docs
- `references/php.md` - Php - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

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

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
