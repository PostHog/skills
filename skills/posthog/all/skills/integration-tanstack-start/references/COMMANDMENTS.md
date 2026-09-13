# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
- Use PostHogProvider in the root route (__root.tsx) for client-side tracking
- Use posthog-node for server-side event capture in API routes (src/routes/api/) – posthog-js is browser-only
- Create a singleton PostHog server client to avoid re-initialization on every request
- Use TanStack Router's built-in navigation events for pageview tracking instead of useEffect
- Use PostHogProvider in the root component defined in either the file-based convention (__root.tsx) or code-based convention (wherever createRootRoute() is called) so all child routes have access to the PostHog client
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
- posthog-node is the Node.js server-side SDK package name; posthog-js is browser-only, so use posthog-node on the server instead
- Include enableExceptionAutocapture: true in the PostHog constructor options
- Add posthog.capture() calls in route handlers for meaningful user actions – every route that creates, updates, or deletes data should track an event with contextual properties
- Add posthog.captureException(err, distinctId) in the application's error handler (e.g., Express error middleware, Fastify setErrorHandler, Koa app.on('error'))
- The SDK batches events and flushes asynchronously. await flush() or await shutdown() before letting that process exit. If unsure, set flushAt 1 and flushInterval 0.
- `posthog.capture()` enqueues synchronously and returns; the batched HTTP send happens afterwards. Treat every per-request handler as short-lived even when the framework feels like a server: Next.js / Nuxt / SvelteKit / Remix route handlers, serverless and edge functions, and Lambda are torn down per invocation before the send runs. Create the client with flushAt 1 and flushInterval 0, then await the send before returning. Always use `await posthog.flush()` for a shared/singleton client, `await posthog.shutdown()` for a per-request client. Never skip the awaited flush or risk the enqueued event being silently dropped.
- Reverse proxy is NOT needed for server-side Node.js – only client-side JavaScript needs a proxy to avoid ad blockers
