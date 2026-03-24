---
name: integration-tanstack-start
description: PostHog integration for TanStack Start full-stack applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog integration for TanStack Start

This skill helps you add PostHog analytics to TanStack Start applications.

## Workflow

Follow these steps in order to complete the integration:

1. `basic-integration-1.0-begin.md` - PostHog Setup - Begin ← **Start here**
2. `basic-integration-1.1-edit.md` - PostHog Setup - Edit
3. `basic-integration-1.2-revise.md` - PostHog Setup - Revise
4. `basic-integration-1.3-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - TanStack Start example project code
- `references/tanstack-start.md` - Tanstack start - docs
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

- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
- Use PostHogProvider in the root route (__root.tsx) for client-side tracking
- Use posthog-node for server-side event capture in API routes (src/routes/api/) - do NOT use posthog-js on the server
- Create a singleton PostHog server client to avoid re-initialization on every request
- Use TanStack Router's built-in navigation events for pageview tracking instead of useEffect
- Use PostHogProvider in the root component defined in either the file-based convention (__root.tsx) or code-based convention (wherever createRootRoute() is called) so all child routes have access to the PostHog client

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
