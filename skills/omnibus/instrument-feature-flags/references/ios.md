> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# iOS Feature Flags installation

Canonical URL: https://posthog.com/docs/feature-flags/installation/ios

> **Cloud region:** This page uses US Cloud hosts. For an EU Cloud project, use `https://eu.i.posthog.com` instead of `https://us.i.posthog.com` (ingestion host).

## On this page

- [Install with the wizard](#install-with-the-wizard)
- [Install dependency](#install-dependency)
- [Configure PostHog](#configure-posthog)
- [Send events](#send-events)
- [Evaluate boolean feature flags](#evaluate-boolean-feature-flags)
- [Evaluate multivariate feature flags](#evaluate-multivariate-feature-flags)
- [Running experiments](#running-experiments)
- [Next steps](#next-steps)

## Install with the wizard

Run this command in your project directory to add PostHog to your iOS project. The wizard detects your framework, installs the SDK, and sets up your first events.

`npx @posthog/wizard`

Or set it up manually by following the rest of this guide.

1.  1

    ## Install dependency

    Required

    Install via Swift Package Manager. PostHog requires Xcode 26 or later, and iOS 15, macOS 12, tvOS 15, watchOS 10, or visionOS 1 or later.

    Package.swift

    ```swift
    dependencies: [
      .package(url: "https://github.com/PostHog/posthog-ios.git", from: "4.0.0")
    ]
    ```

    **Using CocoaPods?**

    Version 4 is only published to Swift Package Manager. Version 3 stays on CocoaPods (`pod "PostHog", "~> 3.0"`), but [CocoaPods trunk becomes read-only on December 2, 2026](https://blog.cocoapods.org/CocoaPods-Specs-Repo/). After that, existing 3.x versions stay installable, but new releases only ship through Swift Package Manager. To switch, see the [iOS migration guide](https://github.com/PostHog/posthog-ios/blob/main/MIGRATION.md).

2.  2

    ## Configure PostHog

    Required

    Initialize PostHog in your AppDelegate:

    AppDelegate.swift

    ```swift
    import Foundation
    import PostHog
    import UIKit
    
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            let POSTHOG_PROJECT_TOKEN = "<ph_project_token>"
            let POSTHOG_HOST = "https://us.i.posthog.com"
    
            let config = PostHogConfig(projectToken: POSTHOG_PROJECT_TOKEN, host: POSTHOG_HOST)
            PostHogSDK.shared.setup(config)
    
            return true
        }
    }
    ```

3.  3

    ## Send events

    Recommended

    Once installed, PostHog will automatically start capturing events. You can also manually send events to test your integration:

    Swift

    ```swift
    PostHogSDK.shared.capture("button_clicked", properties: ["button_name": "signup"])
    ```

4.  4

    ## Evaluate boolean feature flags

    Required

    Check if a feature flag is enabled:

    Swift

    ```swift
    let isMyFlagEnabled = PostHogSDK.shared.isFeatureEnabled("flag-key")
    if isMyFlagEnabled {
        // Do something differently for this user
        // Optional: fetch the payload
        let matchedFlagPayload = PostHogSDK.shared.getFeatureFlagResult("flag-key")?.payload
    }
    ```

5.  5

    ## Evaluate multivariate feature flags

    Optional

    For multivariate flags, check which variant the user has been assigned:

    Swift

    ```swift
    let enabledVariant = PostHogSDK.shared.getFeatureFlag("flag-key")
    if enabledVariant == "variant-key" { // replace 'variant-key' with the key of your variant
        // Do something differently for this user
        // Optional: fetch the payload
        let matchedFlagPayload = PostHogSDK.shared.getFeatureFlagResult("flag-key")?.payload
    }
    ```

6.  6

    ## Running experiments

    Optional

    Experiments run on top of our feature flags. Once you've implemented the flag in your code, you run an experiment by creating a new experiment in the PostHog dashboard.

7.  7

    ## Next steps

    Recommended

    Now that you're evaluating flags, continue with the resources below to learn what else Feature Flags enables within the PostHog platform.

    | Resource | Description |
    | --- | --- |
    | [Creating a feature flag](https://posthog.com/docs/feature-flags/creating-feature-flags.md) | How to create a feature flag in PostHog |
    | [Adding feature flag code](https://posthog.com/docs/feature-flags/adding-feature-flag-code.md) | How to check flags in your code for all platforms |
    | [Framework-specific guides](https://posthog.com/docs/feature-flags/tutorials.md#framework-guides) | Setup guides for React Native, Next.js, Flutter, and other frameworks |
    | [How to do a phased rollout](https://posthog.com/tutorials/phased-rollout.md) | Gradually roll out features to minimize risk |
    | [More tutorials](https://posthog.com/docs/feature-flags/tutorials.md) | Other real-world examples and use cases |
