---
name: error-tracking-dotnet
description: PostHog error tracking for .NET / ASP.NET Core
metadata:
  author: PostHog
  version: dev
---

# PostHog error tracking for .NET / ASP.NET Core

This skill helps you add PostHog error tracking to .NET / ASP.NET Core applications.

## Reference files

- `references/dotnet.md` - .net error tracking installation - docs
- `references/dotnet.md` - .net - docs
- `references/fingerprints.md` - Fingerprints - docs
- `references/alerts.md` - Send error tracking alerts - docs
- `references/monitoring.md` - Monitor and search issues - docs
- `references/assigning-issues.md` - Assign issues to teammates - docs
- `references/upload-source-maps.md` - Upload source maps - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys and host URLs. Never hardcode them.
- **Minimal changes**: Add error tracking alongside existing error handling. Don't replace or restructure existing error handling code.
- **Autocapture first**: Enable exception autocapture in the SDK initialization before adding manual captures.
- **Source maps**: Upload source maps so stack traces resolve to original source code, not minified bundles.
- **Manual capture for boundaries**: Use `captureException()` at error boundaries and catch blocks for errors that don't propagate to the global handler.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-dotnet package names are `PostHog` for general .NET apps and `PostHog.AspNetCore` for ASP.NET Core apps
- Use environment variables, user secrets, or configuration providers for `ProjectToken`, `HostUrl`, and `PersonalApiKey`; never hardcode PostHog secrets
- For CLIs, scripts, workers, and other short-lived processes, create one `PostHogClient` for the process lifetime and call `FlushAsync()` before exit
- Call `IdentifyAsync` for known users and put PII such as email in person properties, not in event properties
- Use `CaptureException(exception, distinctId, properties, groups, flags)` for handled exceptions; automatic exception capture is not available in the .NET SDK yet
- In ASP.NET Core apps, prefer `builder.AddPostHog()` from `PostHog.AspNetCore` and inject `IPostHogClient` from dependency injection instead of manually constructing clients in controllers
- Configure ASP.NET Core apps with the `PostHog` configuration section or environment variable fallbacks such as `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST`
- Add product analytics captures at route, controller, or handler boundaries where meaningful user actions occur; do not track every low-level method call
- Capture request exceptions in middleware with `CaptureException` and then rethrow so existing ASP.NET Core error handling still runs
- For Microsoft.FeatureManagement, call `UseFeatureManagement<TContextProvider>()` and implement `IPostHogFeatureFlagContextProvider` to provide the current distinct ID, person properties, and groups
