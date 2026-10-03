# PostHog iOS Audit Skill

Audit and review PostHog implementations in iOS and SwiftUI codebases.

## What This Skill Does

This skill helps AI agents analyze iOS projects for PostHog SDK implementation quality. It checks for:

- **Configuration issues** — Incorrect settings for SwiftUI vs UIKit
- **SwiftUI-specific problems** — Missing manual screen tracking, session replay misconfiguration
- **Feature flag best practices** — Missing fallbacks, inefficient reloading patterns
- **Event tracking conventions** — Naming consistency, property standards
- **User identification flow** — Proper identify/reset patterns
- **Session replay setup** — Privacy masking, screenshot mode for SwiftUI

## When to Use

Use this skill when:
- Setting up PostHog in a new iOS project
- Reviewing an existing PostHog integration
- Debugging analytics data issues
- Preparing for production release
- Migrating from UIKit to SwiftUI

## Requirements

- iOS project with PostHog iOS SDK (v3.0.0+)
- Access to the project's Swift source files

## Example Usage

Ask your AI assistant:
- "Audit the PostHog implementation in my iOS app"
- "Check if my PostHog SwiftUI integration follows best practices"
- "Review my feature flag usage for issues"
- "Is my session replay configured correctly for SwiftUI?"

## Key Checks

| Category | What's Checked |
|----------|----------------|
| Configuration | SDK version, debug mode, flush settings |
| SwiftUI | Screen tracking, screenshot mode, view modifiers |
| Feature Flags | Fallbacks, reload patterns, result handling |
| Events | Naming conventions, property consistency |
| Identification | Login/logout flow, property updates |
| Session Replay | Privacy masking, SwiftUI compatibility |
| Extensions | App Group configuration |

## Output Format

The skill produces a structured audit report with:
- Overview of SDK version and features
- 🔴 Critical issues (crashes, data loss)
- 🟡 Warnings (incorrect data, suboptimal behavior)
- 🟢 Good practices found
- Prioritized recommendations with code examples

## Files

```
posthog-ios-audit/
├── README.md    # This file
└── SKILL.md     # Main skill instructions
```
