---
name: error-tracking-react-native
description: PostHog error tracking for React Native
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for React Native

This skill helps you add PostHog error tracking to React Native applications.

## Reference files

- `references/react-native.md` - React native error tracking installation - docs
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

- posthog-react-native is the React Native SDK package name
- Use react-native-config to load POSTHOG_PROJECT_TOKEN and POSTHOG_HOST from .env (variables are embedded at build time, not runtime)
- react-native-svg is a required peer dependency of posthog-react-native (used by the surveys feature) and must be installed alongside it
- Place PostHogProvider INSIDE NavigationContainer for React Navigation v7 compatibility
