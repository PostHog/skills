# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- For Next.js 15.3+, initialize PostHog in instrumentation-client.ts for the simplest setup
- The PostHog React hooks (useFeatureFlagEnabled, useFeatureFlagPayload) work WITHOUT PostHogProvider if posthog-js is already initialized (e.g., via instrumentation-client.ts)
- In client components, import and use hooks directly - the React context defaults to the posthog-js singleton
- Do NOT wrap components in PostHogProvider just for feature flags - it's unnecessary if posthog-js is initialized globally
- Server Components and Route Handlers cannot use React hooks - use posthog-node SDK instead
- Create a server-side PostHog client with posthog-node, call getAllFlags() or getFeatureFlag(), then await posthog.shutdown()
- Route Handlers and Server Actions are short-lived per request. Create the posthog-node client with flushAt 1 and flushInterval 0, and `await posthog.flush()` after capturing and before returning, or the function freezes before the event is sent and it is silently dropped
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
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
