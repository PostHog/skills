---
name: error-tracking-android
description: PostHog error tracking for Android
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for Android

This skill helps you add PostHog error tracking to Android applications.

## Reference files

- `references/android.md` - Android error tracking installation - docs
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

- Adapt dependency configuration to the appropriate build.gradle(.kts) file according to the project gradle version
- Call `PostHogAndroid.setup()` only once in the Application class's `onCreate()` method, so it's initialized as early as possible and only once.
- Initialize PostHog in the Application class's `onCreate()` method
- Ensure every activity has a `android:label` to accurately track screen views.
