---
name: integration-flutter
description: PostHog integration for Flutter applications using the posthog_flutter SDK
metadata:
  author: PostHog
  version: dev
---

# PostHog integration for Flutter

This skill helps you add PostHog analytics to Flutter applications.

## Workflow

Follow these steps in order to complete the integration:

1. `references/1-begin.md` - PostHog Setup - Begin ← **Start here**
2. `references/2-edit.md` - PostHog Setup - Edit
3. `references/3-revise.md` - PostHog Setup - Revise
4. `references/4-conclude.md` - PostHog Setup - Conclusion

## Reference files

- `references/EXAMPLE.md` - Flutter example project code
- `references/1-begin.md` - Start the event tracking setup process by analyzing the project and creating an event tracking plan
- `references/2-edit.md` - Implement PostHog event tracking in the identified files, following best practices and the example project
- `references/3-revise.md` - Review and fix any errors in the PostHog integration implementation
- `references/4-conclude.md` - Review and fix any errors in the PostHog integration implementation
- `references/flutter.md` - Flutter - docs
- `references/identify-users.md` - Identify users - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

The example project shows the target implementation pattern. Consult the documentation for API details.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add PostHog code alongside existing integrations. Don't replace or restructure existing code.
- **Match the example**: Your implementation should follow the example project's patterns as closely as possible.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- posthog_flutter is the Flutter SDK package name; install it with `flutter pub add posthog_flutter` or add it to `pubspec.yaml`
- For manual setup, call `WidgetsFlutterBinding.ensureInitialized()`, create a `PostHogConfig`, then await `Posthog().setup(config)` before `runApp()`
- For Android, ensure `minSdkVersion` is at least `23`. If the current value is lower than `23` or missing, update/add it as `minSdkVersion 23`; if it is already `23` or higher, leave it unchanged. Configure `com.posthog.posthog.PROJECT_TOKEN` and `com.posthog.posthog.POSTHOG_HOST` in `android/app/src/main/AndroidManifest.xml` unless using manual setup with `AUTO_INIT=false`
- For iOS, ensure the minimum deployment target is at least iOS `13.0`. If the current `platform :ios` value is lower than `13.0` or missing, update/add it as `platform :ios, '13.0'`; if it is already `13.0` or higher, leave it unchanged. Configure `com.posthog.posthog.PROJECT_TOKEN` and `com.posthog.posthog.POSTHOG_HOST` in `ios/Runner/Info.plist` unless using manual setup
- For Session Replay or Surveys, disable auto-init with `com.posthog.posthog.AUTO_INIT=false` and initialize manually so the required options can be enabled
- For Flutter Web, add the posthog-js web snippet to `web/index.html`. If you are instructed to ever embed the HTML snippet into the user's code, write the real token directly into the snippet. It is not a secret, and when used as an HTML snippet, it should be written in literally. The example token phc_your_project_token_here is a placeholder for readers. It is not the shape to copy. Flutter Web session replay also requires Canvas capture in project settings
- Capture screen views by adding `PosthogObserver()` to the app's `navigatorObservers`, whatever routing package the app uses; where its routes are unnamed, name them so `$screen` is readable
- Call `Posthog().identify(...)` after login and `Posthog().reset()` on logout; keep PII in user properties, not event properties
- Use `beforeSend` to redact or drop Dart-captured events, but remember it does not intercept native session replay, lifecycle, or system properties

## Identifying users

Identify users during login and signup events. Refer to the example code and documentation for the correct identify pattern for this framework. If both frontend and backend code exist, pass the client-side session and distinct ID using `X-POSTHOG-DISTINCT-ID` and `X-POSTHOG-SESSION-ID` headers to maintain correlation.

## Error tracking

Add PostHog error tracking to relevant files, particularly around critical user flows and API boundaries.
