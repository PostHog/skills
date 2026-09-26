---
name: integration-react-react-router-6
description: PostHog integration for React Router v6 applications
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for React Router v6

This skill helps you add PostHog analytics to React Router v6 applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - React Router v6 example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/react-router-v6.md` - React router v6 - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
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

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
