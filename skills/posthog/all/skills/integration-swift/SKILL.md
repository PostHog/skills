---
name: integration-swift
description: PostHog integration for Swift iOS and macOS applications
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Swift (iOS/macOS)

This skill helps you add PostHog analytics to Swift (iOS/macOS) applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE-swift.md` - swift example project code
- `references/EXAMPLE-swift-xcodegen.md` - swift-xcodegen example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/ios.md` - Ios - docs
- `references/usage.md` - Ios SDK usage - docs
- `references/configuration.md` - Ios SDK configuration - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Set the PostHog project token and host directly in code when creating the `PostHogConfig` (e.g. `PostHogConfig(apiKey: "<project-token>", host: "https://us.i.posthog.com")`). The project token is a public client-side key designed to ship in the app binary, so hardcoding it is safe and is the recommended approach for iOS
- Do NOT depend on Xcode scheme environment variables (`ProcessInfo.processInfo.environment`) as the only source of the token: they are injected only when launching from Xcode (debug/simulator), NOT in Archive/Release builds (TestFlight, App Store). Reading them is fine as an optional override, but never force-unwrap or `fatalError` on their absence — that crashes production builds on launch. Ensure a value always ships in the binary
- Before editing any Xcode project file, check for a project generator spec. If a `project.yml` with XcodeGen-shaped content (top-level `targets:` and/or `packages:` keys — do not trust the filename alone) exists at the repo root, the `.xcodeproj` is generated and MUST NOT be edited directly: the next `xcodegen generate` silently wipes any edit to `project.pbxproj`. Instead declare the package in `project.yml` under `packages:` as `PostHog: { url: https://github.com/PostHog/posthog-ios, from: <latest release> }`, add `- package: PostHog` to the app target's `dependencies:` list, then tell the user to re-run `xcodegen generate` to apply it
- When adding SPM dependencies to project.pbxproj (only when no XcodeGen `project.yml` generator spec exists — see the rule above), create three distinct objects with unique UUIDs — a `PBXBuildFile` (with `productRef`), an `XCSwiftPackageProductDependency` (with `package` and `productName`), and an `XCRemoteSwiftPackageReference` (with `repositoryURL` and `requirement`). The build file goes in the Frameworks phase `files`, the product dependency goes in the target's `packageProductDependencies`, and the package reference goes in the project's `packageReferences`.
- Check the latest release version of posthog-ios at `https://github.com/PostHog/posthog-ios/releases` before setting the `minimumVersion` in the SPM package reference — do not hardcode a stale version
- If the project uses App Sandbox (macOS), add `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` to the target's build settings so PostHog can reach its servers — do NOT disable the sandbox entirely
- Install the PostHog iOS SDK as `PostHog` via Swift Package Manager or CocoaPods, using `https://github.com/PostHog/posthog-ios.git` for SPM
- Initialize `PostHogSDK.shared.setup(config)` exactly once and as early as possible, either in `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)` or in the SwiftUI `App` initializer
- For SwiftUI apps, prefer meaningful `.postHogScreenView(...)` modifiers for screen tracking because automatic SwiftUI screen names can be internal view identifiers
- Call `PostHogSDK.shared.identify(...)` after login and `PostHogSDK.shared.reset()` on logout; keep PII in user properties, not event properties
- Enable iOS error autocapture with `config.errorTrackingConfig.autoCapture = true` and upload dSYM files so crash reports are symbolicated
- Enable session replay with `config.sessionReplay = true` only after confirming project replay settings and privacy masking requirements; session replay is iOS-only, not macOS
- Use `config.setBeforeSend { event in ... }` to redact, drop, or sample custom events, while preserving PostHog internal events where possible
- For iOS logs, use posthog-ios 3.58.0 or later, set `config.logs` fields before `setup`, and capture logs manually with `PostHogSDK.shared.logger` or `captureLog`
- For widgets, app clips, share extensions, and other app extensions, configure `config.appGroupIdentifier` so the main app and extensions share analytics identity

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
