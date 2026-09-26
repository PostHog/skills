---
name: llm-analytics-dotnet-openai
description: >-
  PostHog LLM analytics for .NET applications using PostHog.AI with OpenAI or
  Azure OpenAI
metadata:
  author: PostHog
  version: dev
---

# PostHog LLM analytics

This skill helps you add PostHog LLM analytics to any application using AI/LLM providers.

## Reference files

- `references/README.md` - PostHog.ai for .net
- `references/openai.md` - Openai observability installation - docs
- `references/azure-openai.md` - Azure openai observability installation - docs
- `references/basics.md` - Ai observability basics - docs
- `references/traces.md` - Traces - docs
- `references/calculating-costs.md` - Calculating llm costs - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Each provider reference contains installation instructions, SDK setup, and code examples specific to that provider or framework. Find the reference that matches the user's stack and follow its instructions.

If the user's provider isn't listed, use `manual-capture.md` as a fallback — it covers the generic event capture approach that works with any provider.

## Key principles

- **Environment variables**: Always use environment variables for PostHog and LLM provider keys. Never hardcode them.
- **Minimal changes**: Add LLM analytics alongside existing LLM calls. Don't replace or restructure existing code.
- **Trace all generations**: Capture input tokens, output tokens, model name, latency, and costs for every LLM call.
- **Link to users**: Associate LLM generations with identified users via distinct IDs when possible.
- **One provider at a time**: Only instrument the provider(s) the user is actually using. Don't add instrumentation for providers not present in the codebase.

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
