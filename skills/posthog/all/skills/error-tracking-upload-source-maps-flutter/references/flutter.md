> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload debug symbols for Flutter - Docs

Copy page

# Upload debug symbols for Flutter - Docs

**CLI version requirement**

A minimum CLI version of [0.7.4](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.7.4) is required, but we recommend [keeping up with the latest CLI version](/docs/error-tracking/upload-source-maps/cli.md) to ensure you have all of error tracking's features.

Flutter apps can run on multiple platforms, each with its own debug symbol format. Follow the relevant section below for each platform you support.

## Flutter Web

Ensure source maps are generated:

Terminal

PostHog AI

```bash
# Files are usually under the 'build/web' folder
flutter build web --source-maps
```

Then use our standard [CLI approach](/docs/error-tracking/upload-source-maps/cli.md) to inject and upload them.

## iOS / macOS

When `captureNativeExceptions` is enabled, native crashes on Apple platforms are captured automatically. To get symbolicated stack traces, you need to upload dSYM debug symbols.

Follow the [iOS source maps guide](/docs/error-tracking/upload-source-maps/ios.md) to set up a build phase script in Xcode that uploads dSYMs automatically.

## Android

When `captureNativeExceptions` is enabled, Java/Kotlin exceptions on Android are captured automatically. If your app uses ProGuard or R8 minification, you need to upload mapping files so stack traces can be deobfuscated.

Follow the [Android mappings guide](/docs/error-tracking/upload-mappings/android.md) to set up the PostHog Gradle plugin for automatic uploads.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better