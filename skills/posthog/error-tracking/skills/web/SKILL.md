---
name: error-tracking-web
description: PostHog error tracking for Web (JavaScript)
metadata:
  author: PostHog
  version: dev
---

# PostHog error tracking for Web (JavaScript)

This skill helps you add PostHog error tracking to Web (JavaScript) applications.

## Reference files

- `references/web.md` - Web error tracking installation - docs
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
- When a reverse proxy is configured, both /static/* AND /array/* must route to the assets origin (us-assets.i.posthog.com or eu-assets.i.posthog.com).
- posthog-js is the JavaScript SDK package name
- posthog.init() MUST be called before any other PostHog methods (capture, identify, etc.)
- posthog-js is browser-only — do NOT import it in Node.js or server-side contexts (use posthog-node instead)
- Autocapture is ON by default with posthog-js (tracks clicks, form submissions, pageviews). Keep autocapture enabled unless the user explicitly asks to turn it off.
- NEVER send PII in posthog.capture() event properties — no emails, full names, phone numbers, physical addresses, IP addresses, or user-generated content
- PII belongs in posthog.identify() person properties (email, name, role), NOT in capture() event properties
- Call posthog.identify(userId, { email, name, role }) on login AND on page refresh if the user is already logged in
- Call posthog.reset() on logout — the transition out of an identified session, never an initially anonymous page load (that discards the anonymous id and its history) — and before identify() when switching directly between accounts
- For SPAs without a framework router, capture pageviews with posthog.capture($pageview) or use the capture_pageview history_change option in init for History API routing
- When verifying with an automated browser (Playwright, Puppeteer, Selenium), posthog-js's bot filter silently drops every capture while flags and asset loads still succeed. Override navigator.webdriver, the user agent, AND navigator.userAgentData before concluding events do not send. Diagnose with ?__posthog_debug=true ("likely bot" in the console).
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
