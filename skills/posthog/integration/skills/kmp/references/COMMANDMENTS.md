# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- com.posthog:posthog-kmp is the Kotlin Multiplatform SDK package name; add it to the shared module's commonMain.dependencies in build.gradle.kts, not to androidMain, iosMain, or any platform-specific source set
- All PostHog APIs live in the com.posthog.kmp package — import com.posthog.kmp.PostHog, com.posthog.kmp.PostHogConfig, and com.posthog.kmp.PostHogContext
- Call PostHog.setup(config, context) exactly once, early in the app lifecycle, from shared code; do not also add posthog-android or posthog-js directly
- PostHogContext is platform-specific — on Android pass PostHogContext(application); on iOS and web use the no-argument PostHogContext()
- posthog-kmp is a thin wrapper that delegates to the native posthog-android, posthog-ios, and posthog-js SDKs, so session replay and autocapture availability follow the underlying native platform
- Use PostHogConfig.HOST_US or PostHogConfig.HOST_EU for the host, and read the project token from generated build config or environment values rather than hardcoding it
- The SDK is 0.x pre-release; check the latest posthog-kmp version on Maven Central (https://central.sonatype.com/artifact/com.posthog/posthog-kmp) before pinning instead of hardcoding a stale version
