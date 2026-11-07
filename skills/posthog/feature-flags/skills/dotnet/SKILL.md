---
name: feature-flags-dotnet
description: PostHog feature flags for .NET applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for .NET

This skill helps you add PostHog feature flags to .NET applications.

## Reference files

- `references/dotnet.md` - .net feature flags installation - docs
- `references/dotnet.md` - .net - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Best practices for production-ready flags - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog-dotnet package names are `PostHog` for general .NET apps and `PostHog.AspNetCore` for ASP.NET Core apps
- Use environment variables, user secrets, or configuration providers for `ProjectToken`, `HostUrl`, and `PersonalApiKey`; never hardcode PostHog secrets
- For CLIs, scripts, workers, and other short-lived processes, create one `PostHogClient` for the process lifetime and call `FlushAsync()` before exit
- Call `IdentifyAsync` for known users and put PII such as email in person properties, not in event properties
- Use `CaptureException(exception, distinctId, properties, groups, flags)` for handled exceptions; automatic exception capture is not available in the .NET SDK yet
