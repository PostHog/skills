---
name: integration-swift
description: PostHog integration for Swift iOS and macOS applications
metadata:
  author: PostHog
  version: 1.9.4
---

# PostHog integration for Swift (iOS/macOS)

This skill helps you add PostHog analytics to Swift (iOS/macOS) applications.

## Workflow

Follow these steps in order to complete the integration:

1. `basic-integration-1.0-begin.md` - PostHog Setup - Begin ← **Start here**
2. `basic-integration-1.1-edit.md` - PostHog Setup - Edit
3. `basic-integration-1.2-revise.md` - PostHog Setup - Revise
4. `basic-integration-1.3-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Swift (iOS/macOS) example project code
- `references/ios.md` - Ios - docs
- `references/identify-users.md` - Identify users - docs
- `references/basic-integration-1.0-begin.md` - PostHog setup - begin
- `references/basic-integration-1.1-edit.md` - PostHog setup - edit
- `references/basic-integration-1.2-revise.md` - PostHog setup - revise
- `references/basic-integration-1.3-conclude.md` - PostHog setup - conclusion

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- Read configuration from environment variables via a `PostHogEnv` enum with a `value` computed property that calls `ProcessInfo.processInfo.environment[rawValue]` and `fatalError`s if missing — cases should be `projectToken = "POSTHOG_PROJECT_TOKEN"` and `host = "POSTHOG_HOST"`, set in the Xcode scheme's Run environment variables
- When adding SPM dependencies to project.pbxproj, create three distinct objects with unique UUIDs — a `PBXBuildFile` (with `productRef`), an `XCSwiftPackageProductDependency` (with `package` and `productName`), and an `XCRemoteSwiftPackageReference` (with `repositoryURL` and `requirement`). The build file goes in the Frameworks phase `files`, the product dependency goes in the target's `packageProductDependencies`, and the package reference goes in the project's `packageReferences`.
- Check the latest release version of posthog-ios at `https://github.com/PostHog/posthog-ios/releases` before setting the `minimumVersion` in the SPM package reference — do not hardcode a stale version
- If the project uses App Sandbox (macOS), add `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES` to the target's build settings so PostHog can reach its servers — do NOT disable the sandbox entirely

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
