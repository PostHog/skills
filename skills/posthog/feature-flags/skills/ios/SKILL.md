---
name: feature-flags-ios
description: PostHog feature flags for iOS applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog feature flags for iOS

This skill helps you add PostHog feature flags to iOS applications.

## Reference files

- `references/ios.md` - Ios feature flags installation - docs
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

- Read configuration from environment variables via a `PostHogEnv` enum with a `value` computed property that calls `ProcessInfo.processInfo.environment[rawValue]` and `fatalError`s if missing — cases should be `projectToken = "POSTHOG_PROJECT_TOKEN"` and `host = "POSTHOG_HOST"`, set in the Xcode scheme's Run environment variables
- When adding SPM dependencies to project.pbxproj, create three distinct objects with unique UUIDs — a `PBXBuildFile` (with `productRef`), an `XCSwiftPackageProductDependency` (with `package` and `productName`), and an `XCRemoteSwiftPackageReference` (with `repositoryURL` and `requirement`). The build file goes in the Frameworks phase `files`, the product dependency goes in the target's `packageProductDependencies`, and the package reference goes in the project's `packageReferences`.
- Check the latest release version of posthog-ios at `https://github.com/PostHog/posthog-ios/releases` before setting the `minimumVersion` in the SPM package reference — do not hardcode a stale version
- If the project uses App Sandbox (macOS), add `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` to the target's build settings so PostHog can reach its servers — do NOT disable the sandbox entirely
