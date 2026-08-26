# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-node is the Node.js server-side SDK package name; posthog-js is browser-only, so use posthog-node on the server instead
- Include enableExceptionAutocapture: true in the PostHog constructor options
- Add posthog.capture() calls in route handlers for meaningful user actions – every route that creates, updates, or deletes data should track an event with contextual properties
- Add posthog.captureException(err, distinctId) in the application's error handler (e.g., Express error middleware, Fastify setErrorHandler, Koa app.on('error'))
- The SDK batches events and flushes asynchronously. await flush() or await shutdown() before letting that process exit. If unsure, set flushAt 1 and flushInterval 0.
- `posthog.capture()` enqueues synchronously and returns; the batched HTTP send happens afterwards. Treat every per-request handler as short-lived even when the framework feels like a server: Next.js / Nuxt / SvelteKit / Remix route handlers, serverless and edge functions, and Lambda are torn down per invocation before the send runs. Create the client with flushAt 1 and flushInterval 0, then await the send before returning. Always use `await posthog.flush()` for a shared/singleton client, `await posthog.shutdown()` for a per-request client. Never skip the awaited flush or risk the enqueued event being silently dropped.
- Reverse proxy is NOT needed for server-side Node.js – only client-side JavaScript needs a proxy to avoid ad blockers
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
