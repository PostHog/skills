---
name: feature-flags-react-native
description: PostHog feature flags for React Native applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog feature flags for React Native

This skill helps you add PostHog feature flags to React Native applications.

## Reference files

- `references/react-native.md` - React native feature flags installation - docs
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

- For feature flags, use useFeatureFlagEnabled() or useFeatureFlagPayload() hooks - they handle loading states and external sync automatically
- Add analytics capture in event handlers where user actions occur, NOT in useEffect reacting to state changes
- Do NOT use useEffect for data transformation - calculate derived values during render instead
- Do NOT use useEffect to respond to user events - put that logic in the event handler itself
- Do NOT use useEffect to chain state updates - calculate all related updates together in the event handler
- Do NOT use useEffect to notify parent components - call the parent callback alongside setState in the event handler
- To reset component state when a prop changes, pass the prop as the component's key instead of using useEffect
- useEffect is ONLY for synchronizing with external systems (non-React widgets, browser APIs, network subscriptions)
- posthog-react-native is the React Native SDK package name
- Use react-native-config to load POSTHOG_PROJECT_TOKEN and POSTHOG_HOST from .env (variables are embedded at build time, not runtime)
- react-native-svg is a required peer dependency of posthog-react-native (used by the surveys feature) and must be installed alongside it
- Place PostHogProvider INSIDE NavigationContainer for React Navigation v7 compatibility
