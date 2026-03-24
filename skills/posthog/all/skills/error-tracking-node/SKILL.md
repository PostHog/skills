---
name: error-tracking-node
description: PostHog error tracking for Node.js
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for Node.js

This skill helps you add PostHog error tracking to Node.js applications.

## Reference files

- `references/node.md` - Node.js error tracking installation - docs
- `references/fingerprints.md` - Fingerprints - docs
- `references/alerts.md` - Send error tracking alerts - docs
- `references/monitoring.md` - Monitor and search issues - docs
- `references/assigning-issues.md` - Assign issues to teammates - docs
- `references/upload-source-maps.md` - Upload source maps - docs

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and host URLs. Never hardcode them.
- **Minimal changes**: Add error tracking alongside existing error handling. Don't replace or restructure existing error handling code.
- **Autocapture first**: Enable exception autocapture in the SDK initialization before adding manual captures.
- **Source maps**: Upload source maps so stack traces resolve to original source code, not minified bundles.
- **Manual capture for boundaries**: Use `captureException()` at error boundaries and catch blocks for errors that don't propagate to the global handler.

## Framework guidelines

- posthog-node is the Node.js server-side SDK package name – do NOT use posthog-js on the server
- Include enableExceptionAutocapture: true in the PostHog constructor options
- Add posthog.capture() calls in route handlers for meaningful user actions – every route that creates, updates, or deletes data should track an event with contextual properties
- Add posthog.captureException(err, distinctId) in the application's error handler (e.g., Express error middleware, Fastify setErrorHandler, Koa app.on('error'))
- In long-running servers, the SDK batches events automatically – do NOT set flushAt or flushInterval unless you have a specific reason to
- For short-lived processes (scripts, CLIs, serverless), set flushAt to 1 and flushInterval to 0 to send events immediately
- Reverse proxy is NOT needed for server-side Node.js – only client-side JavaScript needs a proxy to avoid ad blockers
- Remember that source code is available in the node_modules directory
- Check package.json for type checking or build scripts to validate changes
