# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- For server-side capture (+server.ts endpoints, actions, hooks like handleError), the handler is short-lived per request. Configure the posthog-node singleton with flushAt 1 and flushInterval 0, and `await posthog.flush()` after capturing and before returning, or the batched event is silently dropped when the request ends
- Set paths.relative to false in svelte.config.js — this is required for PostHog session replay to work correctly with SSR and is easy to miss
- Use the Svelte MCP server tools to check Svelte documentation (list-sections, get-documentation) and validate components (svelte-autofixer) — always run svelte-autofixer on new or modified .svelte files before finishing
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
- When identity comes from framework-bridged state (Inertia or SSR shared props, a serialized session), confirm the backend actually shares that field — add the share server-side if missing — before identifying from it
