---
name: error-tracking-angular
description: PostHog error tracking for Angular
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog error tracking for Angular

This skill helps you add PostHog error tracking to Angular applications.

## Reference files

- `references/angular.md` - Angular error tracking installation - docs
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

- Use inject() instead of constructor injection. PostHog service should be injected via inject() in components/services that need it.
- Create a dedicated PosthogService as a singleton root service that wraps the PostHog SDK.
- Always use standalone components over NgModules.
- Configure PostHog credentials in src/environments/environment.ts files, as Angular reads environment variables from these configuration files
