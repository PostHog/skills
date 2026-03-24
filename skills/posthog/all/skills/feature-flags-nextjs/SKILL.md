---
name: feature-flags-nextjs
description: PostHog feature flags for Next.js applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog feature flags for Next.js

This skill helps you add PostHog feature flags to Next.js applications.

## Reference files

- `references/react.md` - React feature flags installation - docs
- `references/next-js.md` - Next.js - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Feature flag best practices - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

## Framework guidelines

- For Next.js 15.3+, initialize PostHog in instrumentation-client.ts for the simplest setup
- The PostHog React hooks (useFeatureFlagEnabled, useFeatureFlagPayload) work WITHOUT PostHogProvider if posthog-js is already initialized (e.g., via instrumentation-client.ts)
- In client components, import and use hooks directly - the React context defaults to the posthog-js singleton
- Do NOT wrap components in PostHogProvider just for feature flags - it's unnecessary if posthog-js is initialized globally
- Server Components and Route Handlers cannot use React hooks - use posthog-node SDK instead
- Create a server-side PostHog client with posthog-node, call getAllFlags() or getFeatureFlag(), then await posthog.shutdown()
- Pass flag values from server to client components as props to avoid hydration mismatches
- For flags that affect initial render, evaluate server-side and pass as props to prevent UI flicker
- Client-side hooks may return undefined initially while flags load - handle this loading state
- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
