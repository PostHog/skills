---
name: integration-kmp
description: >-
  PostHog integration for Kotlin Multiplatform (KMP) shared code targeting
  Android, iOS, and web using the posthog-kmp SDK
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Kotlin Multiplatform

This skill helps you add PostHog analytics to Kotlin Multiplatform applications using the official PostHog Kotlin Multiplatform SDK documentation.

## Instructions

1. Detect the existing Kotlin Multiplatform app structure. Check `settings.gradle.kts`, the shared module's `build.gradle.kts` (look for the `kotlin("multiplatform")` plugin and a `commonMain` source set), and the per-platform entry points (Android `Application`/`Activity`, iOS `MainViewController`, web `main`).
2. Read the reference files below before changing code. They are the source of truth for SDK installation, initialization, event capture, identification, feature flags, group analytics, session replay, and error tracking.
3. Install the SDK by adding `implementation("com.posthog:posthog-kmp:<version>")` to the shared module's `commonMain` dependencies in `build.gradle.kts` — not to a platform-specific source set. Check the latest version on Maven Central (https://central.sonatype.com/artifact/com.posthog/posthog-kmp) rather than hardcoding a stale one.
4. Initialize PostHog once, early in the app lifecycle, from shared code: `PostHog.setup(config = PostHogConfig(apiKey = ..., host = ...), context = PostHogContext())`. Use environment or generated build-config values for the project token and host. Never hardcode secrets.
5. Build `PostHogContext` per platform: on Android pass `PostHogContext(application)`; on iOS and web use the no-argument `PostHogContext()`. All PostHog APIs live in the `com.posthog.kmp` package.
6. Add `PostHog.identify(...)` at login/signup boundaries and `PostHog.reset()` on logout.
7. Verify with the project's normal Gradle commands, such as `./gradlew build`, or the repository's existing checks.

## Reference files

- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/kmp.md` - Kotlin multiplatform - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

## Key principles

- **Environment/configuration values**: Always use environment variables or generated build config for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the docs**: Follow the Kotlin Multiplatform reference's initialization and capture patterns exactly.
- **Analytics contract**: Treat event names, property names, and feature flag keys as part of an analytics contract. Reuse existing names and patterns found in the project. When introducing new ones, make them clear, descriptive, and consistent with existing conventions.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- com.posthog:posthog-kmp is the Kotlin Multiplatform SDK package name; add it to the shared module's commonMain.dependencies in build.gradle.kts, not to androidMain, iosMain, or any platform-specific source set
- All PostHog APIs live in the com.posthog.kmp package — import com.posthog.kmp.PostHog, com.posthog.kmp.PostHogConfig, and com.posthog.kmp.PostHogContext
- Call PostHog.setup(config, context) exactly once, early in the app lifecycle, from shared code; do not also add posthog-android or posthog-js directly
- PostHogContext is platform-specific — on Android pass PostHogContext(application); on iOS and web use the no-argument PostHogContext()
- posthog-kmp is a thin wrapper that delegates to the native posthog-android, posthog-ios, and posthog-js SDKs, so session replay and autocapture availability follow the underlying native platform
- Use PostHogConfig.HOST_US or PostHogConfig.HOST_EU for the host, and read the project token from generated build config or environment values rather than hardcoding it
- The SDK is 0.x pre-release; check the latest posthog-kmp version on Maven Central (https://central.sonatype.com/artifact/com.posthog/posthog-kmp) before pinning instead of hardcoding a stale version
