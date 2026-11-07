---
name: posthog-ios-audit
description: Audit and review PostHog implementations in iOS/SwiftUI codebases. Use this skill when a user wants to verify their PostHog iOS integration is correct, identify common implementation mistakes, check for SwiftUI-specific issues, review feature flag usage, or ensure best practices are followed. Works by analyzing Swift source files for PostHog SDK usage patterns.
---

# PostHog iOS Audit

Analyze iOS and SwiftUI codebases for PostHog implementation quality. This skill helps developers identify configuration issues, missing best practices, and common mistakes in their PostHog iOS SDK integration.

## Critical Rules

1. **Always check SDK version first.** Many features and patterns depend on the SDK version. Look for the version in `Package.swift`, `Podfile`, or `Package.resolved`.
2. **SwiftUI requires special handling.** Automatic screen tracking doesn't work well with SwiftUI. Always check if manual tracking is configured.
3. **Never assume feature flags have values.** All feature flag checks must include fallbacks.
4. **Check for thread safety.** PostHog SDK is thread-safe, but improper async handling in the app can cause issues.
5. **Report findings clearly.** Use the structured format with severity levels (🔴 Critical, 🟡 Warning, 🟢 Good).

## Audit Workflow

### Step 1: Locate PostHog Integration

Search for PostHog imports and initialization:

```swift
// Import pattern
import PostHog

// Initialization pattern
let config = PostHogConfig(apiKey: "phc_...")
PostHogSDK.shared.setup(config)
```

**Files to check:**
- `AppDelegate.swift`
- `*App.swift` (SwiftUI app entry point)
- `SceneDelegate.swift`
- Any file with "PostHog" or "Analytics" in the name

### Step 2: Check SDK Version

Look for version constraints in dependency files:

**Swift Package Manager:**
```swift
// Package.swift or Package.resolved
.package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.0.0")
```

**CocoaPods:**
```ruby
# Podfile
pod 'PostHog', '~> 3.0'
```

**Version requirements:**
- Session Replay: >= 3.6.1
- SwiftUI masking fixes: >= 3.36.1 (for iOS 26)
- Surveys (enabled by default): >= 3.31.0
- `getFeatureFlagResult`: >= 3.40.0
- `setPersonProperties`: >= 3.39.0
- `evaluationContexts`: >= 3.38.0 (replaces `evaluationEnvironments`)

### Step 3: Audit Configuration

Check `PostHogConfig` setup for common issues:

```swift
let config = PostHogConfig(apiKey: "phc_...", host: "https://...")
```

**Configuration checklist:**

| Setting | SwiftUI Recommendation | UIKit Recommendation |
|---------|------------------------|----------------------|
| `captureScreenViews` | `false` (use manual) | `true` |
| `captureApplicationLifecycleEvents` | `true` | `true` |
| `captureElementInteractions` | `true` (if autocapture needed) | `true` |
| `sessionReplay` | `true` with `screenshotMode` | `true` |
| `sessionReplayConfig.screenshotMode` | `true` (required for SwiftUI) | `false` |
| `preloadFeatureFlags` | `true` | `true` |
| `flushAt` | `20` (default, not `1` in prod) | `20` |
| `debug` | `false` in production | `false` in production |

**Red flags to look for:**
- `flushAt = 1` in production (battery drain)
- `debug = true` in production (performance + logs)
- `captureScreenViews = true` with SwiftUI (meaningless screen names)
- `sessionReplay = true` without `screenshotMode = true` in SwiftUI

### Step 4: Audit SwiftUI Screen Tracking

If the app uses SwiftUI, check for proper screen tracking:

**Good pattern:**
```swift
struct HomeView: View {
    var body: some View {
        NavigationStack {
            // content
        }
        .postHogScreenView("Home")
    }
}
```

**Bad patterns:**
```swift
// ❌ Relying on automatic capture in SwiftUI
config.captureScreenViews = true // Produces meaningless names like "ModifiedContent<...>"

// ❌ Missing screen tracking entirely
struct HomeView: View {
    var body: some View {
        // No .postHogScreenView() modifier
    }
}

// ❌ Tracking on inner views instead of screen-level views
struct HomeView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .postHogScreenView("Home") // Wrong - should be on the outer view
        }
    }
}
```

**SwiftUI modifiers to look for:**
- `.postHogScreenView(_:_:)` - Screen tracking
- `.postHogViewSeen(_:_:)` - Non-screen view events
- `.postHogLabel(_:)` - Element labeling for autocapture
- `.postHogMask()` - Mask view in session replay
- `.postHogNoMask()` - Unmask view in session replay

### Step 5: Audit Feature Flag Usage

Check for proper feature flag patterns:

**Good patterns:**
```swift
// ✅ Simple boolean check (returns false if not loaded)
if PostHogSDK.shared.isFeatureEnabled("new-feature") {
    // feature code
}

// ✅ Using getFeatureFlagResult (SDK >= 3.40.0)
if let result = PostHogSDK.shared.getFeatureFlagResult("my-feature") {
    if result.enabled {
        // use result.variant or result.payload
    }
}

// ✅ Centralized flag management
class FeatureFlagManager {
    static func reloadFlags(completion: @escaping () -> Void) {
        PostHogSDK.shared.reloadFeatureFlags {
            completion()
        }
    }
}
```

**Bad patterns:**
```swift
// ❌ Force unwrapping flag value (crashes if nil)
let variant = PostHogSDK.shared.getFeatureFlag("experiment") as! String

// ❌ Not handling nil case for getFeatureFlag
if let flag = PostHogSDK.shared.getFeatureFlag("experiment") {
    // Good - but also handle the else case
}

// ❌ Reloading flags on every view appear
struct SomeView: View {
    var body: some View {
        Text("Hello")
            .onAppear {
                PostHogSDK.shared.reloadFeatureFlags() // ❌ Wasteful
            }
    }
}
```

### Step 6: Audit Event Tracking

Check event naming and property conventions:

**Good patterns:**
```swift
// ✅ [object] [verb] naming
PostHogSDK.shared.capture("user_signed_up")
PostHogSDK.shared.capture("purchase_completed", properties: ["amount": 99.99])
PostHogSDK.shared.capture("article_viewed", properties: ["article_id": "123"])

// ✅ Consistent property naming (snake_case)
properties: ["user_type": "premium", "item_count": 5]
```

**Bad patterns:**
```swift
// ❌ Inconsistent naming
PostHogSDK.shared.capture("SignUp") // PascalCase
PostHogSDK.shared.capture("user-signed-up") // kebab-case
PostHogSDK.shared.capture("User Signed Up") // Spaces

// ❌ Missing context in properties
PostHogSDK.shared.capture("button_clicked") // Which button?

// ❌ Inconsistent property naming
properties: ["userType": "premium", "item_count": 5] // Mixed camelCase and snake_case
```

### Step 7: Audit User Identification

Check identification flow:

**Good patterns:**
```swift
// ✅ Identify after login with properties
PostHogSDK.shared.identify(userId, userProperties: [
    "email": email,
    "plan": "premium"
])

// ✅ Reset on logout
func logout() {
    PostHogSDK.shared.reset()
    // Navigate to login
}

// ✅ Update properties without re-identifying (SDK >= 3.39.0)
PostHogSDK.shared.setPersonProperties(userPropertiesToSet: ["plan": "enterprise"])
```

**Bad patterns:**
```swift
// ❌ Identifying with anonymous/temporary IDs
PostHogSDK.shared.identify(UUID().uuidString) // Creates new user each time

// ❌ Not resetting on logout
func logout() {
    // Missing PostHogSDK.shared.reset()
    navigateToLogin()
}

// ❌ Re-identifying just to update properties
PostHogSDK.shared.identify(currentUserId, userProperties: ["plan": "new_plan"])
// Should use setPersonProperties instead
```

### Step 8: Audit Session Replay Configuration

If session replay is enabled, check configuration:

**Good patterns:**
```swift
// ✅ SwiftUI-compatible configuration
config.sessionReplay = true
config.sessionReplayConfig.screenshotMode = true // Required for SwiftUI
config.sessionReplayConfig.maskAllTextInputs = true
config.sessionReplayConfig.maskAllImages = true

// ✅ Masking sensitive views
SensitiveDataView()
    .postHogMask()

// ✅ Using ph-no-capture for UIKit
sensitiveTextField.accessibilityIdentifier = "ph-no-capture"
```

**Bad patterns:**
```swift
// ❌ SwiftUI without screenshot mode
config.sessionReplay = true
// Missing: config.sessionReplayConfig.screenshotMode = true

// ❌ Not masking sensitive data
CreditCardInputView() // Should have .postHogMask()
```

### Step 9: Check App Groups (if using extensions)

If the app has extensions (widgets, watch app, etc.):

**Good pattern:**
```swift
// ✅ Same App Group in all targets
config.appGroupIdentifier = "group.com.yourcompany.yourapp"
```

**Check for:**
- App Group configured in Xcode capabilities for all targets
- Same `appGroupIdentifier` used in all PostHog configurations
- Extension targets initializing PostHog with matching config

## Response Format

After auditing, provide a structured summary:

```
## PostHog iOS Audit Results

### Overview
- **SDK Version:** [version]
- **UI Framework:** [SwiftUI / UIKit / Mixed]
- **Features Enabled:** [list]

### Findings

#### 🔴 Critical Issues
[Issues that will cause crashes, data loss, or major functionality problems]

#### 🟡 Warnings
[Issues that may cause incorrect data or suboptimal behavior]

#### 🟢 Good Practices Found
[Things the implementation does well]

### Recommendations
[Prioritized list of fixes with code examples]
```

## Example Audit

**User:** "Can you audit the PostHog implementation in my iOS app?"

**Agent:** "I'll audit your PostHog iOS implementation. Let me search for the relevant files."

[Searches for PostHog imports and configuration]

**Agent:**
```
## PostHog iOS Audit Results

### Overview
- **SDK Version:** 3.38.0
- **UI Framework:** SwiftUI
- **Features Enabled:** Events, Feature Flags, Session Replay

### Findings

#### 🔴 Critical Issues

1. **SwiftUI session replay without screenshot mode**
   ```swift
   // Current
   config.sessionReplay = true
   
   // Fix: Add screenshot mode
   config.sessionReplay = true
   config.sessionReplayConfig.screenshotMode = true
   ```

2. **Force unwrapped feature flag value**
   ```swift
   // Current (line 45 in HomeView.swift)
   let tier = PostHogSDK.shared.getFeatureFlag("user-tier") as! String
   
   // Fix: Handle nil safely
   if let tier = PostHogSDK.shared.getFeatureFlag("user-tier") as? String {
       // use tier
   } else {
       // fallback behavior
   }
   ```

#### 🟡 Warnings

1. **Automatic screen capture enabled with SwiftUI**
   ```swift
   // Current
   config.captureScreenViews = true
   
   // Recommendation: Disable and use manual tracking
   config.captureScreenViews = false
   // Then add .postHogScreenView("ScreenName") to each screen
   ```

2. **Debug mode enabled**
   - Ensure `config.debug = false` before production release

#### 🟢 Good Practices Found

- ✅ PostHog initialized early in app lifecycle
- ✅ User identification includes relevant properties
- ✅ Reset called on logout
- ✅ Event naming follows [object]_[verb] convention

### Recommendations

1. **[High Priority]** Add `screenshotMode = true` for session replay
2. **[High Priority]** Add fallbacks to all feature flag checks
3. **[Medium Priority]** Switch to manual screen tracking with `.postHogScreenView()`
4. **[Low Priority]** Consider upgrading to SDK 3.41.x for latest fixes
```

## Version Compatibility Notes

Keep these SDK version requirements in mind:

| Feature | Minimum Version |
|---------|-----------------|
| Basic SDK | 3.0.0 |
| Session Replay | 3.6.1 |
| Surveys (opt-in) | 3.22.0 |
| `beforeSend` hook | 3.28.0 |
| Custom Survey UI | 3.29.0 |
| Surveys (default on) | 3.31.0 |
| SwiftUI iOS 26 fixes | 3.36.1 |
| `evaluationContexts` | 3.38.0 |
| `setPersonProperties` | 3.39.0 |
| `getFeatureFlagResult` | 3.40.0 |
| `enableSwizzling` config | 3.34.0 |
| Latest stable | 3.41.2 |
