# Framework rules

Follow these when integrating PostHog into this framework.

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
