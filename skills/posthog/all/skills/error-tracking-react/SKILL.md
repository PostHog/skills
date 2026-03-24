---
name: error-tracking-react
description: PostHog error tracking for React
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for React

This skill helps you add PostHog error tracking to React applications.

## Reference files

- `references/react.md` - React error tracking installation - docs
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

- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
