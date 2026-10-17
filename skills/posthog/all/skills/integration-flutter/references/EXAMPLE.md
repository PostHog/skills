# PostHog Flutter Example Project

Repository: https://github.com/PostHog/context-mill
Path: example-apps/flutter

---

## README.md

# PostHog Flutter example

A [Flutter](https://flutter.dev/) example app demonstrating PostHog integration with product analytics, user identification, screen tracking, and error tracking across Android, iOS, Web, and macOS — the platforms the [posthog_flutter](https://pub.dev/packages/posthog_flutter) SDK supports.

## Features

- **Product analytics**: Track user events and behaviors with `Posthog().capture()`
- **Screen tracking**: Automatic `$screen` events for named routes via `PosthogObserver`
- **Error tracking**: Manual `captureException()` plus autocapture of uncaught Flutter errors
- **User authentication**: Demo login flow with PostHog `identify()`/`reset()`
- **Manual SDK setup**: Dart-side configuration with native auto-init disabled (required for session replay and surveys)

**Flutter Web initializes separately.** `Posthog().setup()` is a no-op on web, so
an app that ships a `web/` target needs the posthog-js snippet in `web/index.html`
as well — a Dart-side setup alone leaves web builds capturing nothing. See
`web/index.html` in this example.

## Prerequisites

1. **Flutter SDK** — follow the [install guide](https://docs.flutter.dev/get-started/install) for your OS, then verify with:
   ```bash
   flutter doctor
   ```
2. **For iOS/macOS**: a Mac with Xcode and [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (`brew install cocoapods`)
3. **For Android**: Android Studio with an emulator or a connected device
4. **For Web**: Chrome

## Getting started

### 1. Regenerate icons and install dependencies

```bash
flutter create --platforms=android,ios,web,macos .
flutter pub get
```

Binary launcher/app icons are deliberately not committed. The `flutter create` step regenerates them — it only adds missing files and never overwrites the committed configs.

### 2. Configure your PostHog project token

Get your project token from your [PostHog project settings](https://app.posthog.com/settings/project).

For **Android, iOS, and macOS**, the token is embedded at build time via `--dart-define` (no file to edit):

```bash
flutter run \
  --dart-define=POSTHOG_PROJECT_TOKEN=phc_your_project_token_here \
  --dart-define=POSTHOG_HOST=https://us.i.posthog.com
```

`POSTHOG_HOST` is optional and defaults to `https://us.i.posthog.com` (use `https://eu.i.posthog.com` for EU Cloud).

For **Web**, edit `web/index.html` and replace `phc_your_project_token_here` in the posthog-js snippet — Flutter Web is initialized by that snippet, not by the Dart config.

> **Note:** The app still runs without a token — analytics are simply disabled (a warning is logged).

### 3. Run per platform

```bash
flutter devices                      # list available targets

flutter run --dart-define=POSTHOG_PROJECT_TOKEN=phc_...              # default device
flutter run -d chrome                                                 # Web (token comes from web/index.html)
flutter run -d macos --dart-define=POSTHOG_PROJECT_TOKEN=phc_...     # macOS
```

For iOS, install pods first (first time only): `cd ios && pod install && cd ..`

## Project structure

```
lib/
├── main.dart                    # Entry point: PostHog setup, MaterialApp with
│                                # named routes + PosthogObserver
├── posthog/
│   └── posthog.dart             # PostHog configuration (manual setup)
├── auth/
│   └── auth_state.dart          # Fake auth with identify()/reset()
└── screens/
    ├── home_screen.dart         # Home/login screen
    ├── burrito_screen.dart      # Demo feature screen with event capture
    └── profile_screen.dart      # Profile with error tracking demo

test/
├── mocks.dart                   # FakePosthogPlatform: records identify/capture/
│                                # screen/captureException calls for assertions
├── posthog/                     # SDK setup config tests
├── auth/                        # identify()/reset() lifecycle tests
└── screens/                     # Event capture + error tracking widget tests

android/                         # AUTO_INIT disabled in AndroidManifest.xml
ios/                             # AUTO_INIT disabled in Runner/Info.plist; Podfile pins iOS 13+
web/                             # posthog-js snippet in index.html
macos/                           # AUTO_INIT disabled in Runner/Info.plist;
                                 # network.client entitlement for the app sandbox
```

## Key integration points

### Manual SDK setup (lib/posthog/posthog.dart)

PostHog is configured once in Dart. Manual setup (instead of the native auto-init path) is required for session replay and surveys, so the native layers disable auto-init with `com.posthog.posthog.AUTO_INIT: false`:

```dart
final config = PostHogConfig(PosthogEnv.projectToken);
config.host = PosthogEnv.host;
config.debug = kDebugMode;
config.errorTrackingConfig.captureFlutterErrors = true;
config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
await Posthog().setup(config);
```

On Flutter Web, `setup()` is a no-op — the posthog-js snippet in `web/index.html` initializes the SDK instead.

### Screen tracking (lib/main.dart)

`PosthogObserver` captures a `$screen` event on every route change. Routes must be named or they won't be recorded:

```dart
MaterialApp(
  navigatorObservers: [PosthogObserver()],
  routes: {
    '/': (_) => const HomeScreen(),
    '/burrito': (_) => const BurritoScreen(),
    '/profile': (_) => const ProfileScreen(),
  },
)
```

### User identification (lib/auth/auth_state.dart)

Identify users as soon as they log in; person data goes in `userProperties` (`$set`) / `userPropertiesSetOnce` (`$set_once`), not event properties. Call `reset()` on logout:

```dart
await Posthog().identify(
  userId: username, // in a real app, use your database user ID here
  userProperties: {'username': username},
  userPropertiesSetOnce: {'first_login_date': DateTime.now().toIso8601String()},
);

// on logout
await Posthog().reset();
```

### Event capture (lib/screens/burrito_screen.dart)

Capture custom events with properties. We recommend a `[object] [verb]` format for event names:

```dart
await Posthog().capture(
  eventName: 'burrito_considered',
  properties: {
    'total_considerations': total,
    'is_first_consideration': total == 1,
  },
);
```

### Error tracking (lib/screens/profile_screen.dart)

Uncaught Flutter errors are captured automatically via `errorTrackingConfig`. Handled errors can be captured manually:

```dart
try {
  throw StateError('Test error for PostHog error tracking');
} catch (error, stackTrace) {
  await Posthog().captureException(
    error: error,
    stackTrace: stackTrace,
    properties: {'source': 'profile_test_button'},
  );
}
```

### Application lifecycle events

`Application Installed`, `Application Updated`, `Application Opened`, and `Application Backgrounded` are captured automatically (`captureApplicationLifecycleEvents` is enabled by default).

## Testing

```bash
flutter test
```

The tests show how to verify a PostHog integration without a network or a
device. `test/mocks.dart` installs a fake `PosthogFlutterPlatformInterface`
that records every `identify`, `capture`, `screen`, `reset`, and
`captureException` call, so tests assert on exactly what would be sent to
PostHog. The fake must `extend` the platform interface (not `implement` it) —
`PlatformInterface.verifyToken` rejects generated mockito/mocktail mocks.

## Learn more

- [PostHog documentation](https://posthog.com/docs)
- [PostHog Flutter integration](https://posthog.com/docs/libraries/flutter)
- [PostHog error tracking](https://posthog.com/docs/error-tracking)
- [Flutter documentation](https://docs.flutter.dev/)

---

## android/app/build.gradle.kts

```kts
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.posthog.burrito_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.posthog.burrito_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // posthog_flutter requires minSdk 23+; Flutter's default (24) satisfies it.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

```

---

## android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required for PostHog to send events in release builds
         (debug/profile builds get it from their own manifests) -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="burrito_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- PostHog is set up manually from Dart (lib/posthog/posthog.dart),
             so disable the SDK's native auto-init.
             @see https://posthog.com/docs/libraries/flutter -->
        <meta-data android:name="com.posthog.posthog.AUTO_INIT" android:value="false" />
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>

```

---

## ios/Podfile

```
# posthog_flutter requires iOS 13.0+
# @see https://posthog.com/docs/libraries/flutter
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end

```

---

## ios/Runner/Info.plist

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- PostHog is set up manually from Dart (lib/posthog/posthog.dart),
	     so disable the SDK's native auto-init.
	     See https://posthog.com/docs/libraries/flutter -->
	<key>com.posthog.posthog.AUTO_INIT</key>
	<false/>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Burrito App</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>burrito_app</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
		<key>UISceneConfigurations</key>
		<dict>
			<key>UIWindowSceneSessionRoleApplication</key>
			<array>
				<dict>
					<key>UISceneClassName</key>
					<string>UIWindowScene</string>
					<key>UISceneConfigurationName</key>
					<string>flutter</string>
					<key>UISceneDelegateClassName</key>
					<string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
					<key>UISceneStoryboardFile</key>
					<string>Main</string>
				</dict>
			</array>
		</dict>
	</dict>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>

```

---

## lib/auth/auth_state.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Fake in-memory authentication demonstrating PostHog user identification.
///
/// This is intentionally not production grade — there is no password and no
/// persistence. It exists to show where `identify()` and `reset()` belong in
/// a real login flow.
///
/// @see https://posthog.com/docs/libraries/flutter#identifying-users
class AuthState extends ChangeNotifier {
  /// In production, use [instance]. Tests construct fresh instances to
  /// stay isolated from each other.
  @visibleForTesting
  AuthState();

  static AuthState _instance = AuthState();
  static AuthState get instance => _instance;
  @visibleForTesting
  static set instance(AuthState value) => _instance = value;

  String? _username;
  int _burritoConsiderations = 0;

  String? get username => _username;
  bool get isLoggedIn => _username != null;
  int get burritoConsiderations => _burritoConsiderations;

  Future<void> logIn(String username) async {
    _username = username;
    _burritoConsiderations = 0;
    notifyListeners();

    // Identify the user as soon as they log in. Events captured anonymously
    // before this point are linked to the user retroactively.
    // Person data (like the username) belongs in userProperties ($set) and
    // userPropertiesSetOnce ($set_once), not in event properties.
    await Posthog().identify(
      // In a real app, use your database user ID here — a stable identifier
      // that never changes throughout the user's lifecycle.
      // @see https://posthog.com/docs/product-analytics/identity-resolution#choosing-your-identity-strategy
      userId: username,
      userProperties: {'username': username},
      userPropertiesSetOnce: {
        'first_login_date': DateTime.now().toIso8601String(),
      },
    );

    await Posthog().capture(
      eventName: 'user_logged_in',
      properties: {'login_method': 'demo_form'},
    );
  }

  Future<void> logOut() async {
    _username = null;
    _burritoConsiderations = 0;
    notifyListeners();

    await Posthog().capture(eventName: 'user_logged_out');

    // Clears the distinct ID and anonymous ID so the next user on this
    // device starts a fresh identity.
    await Posthog().reset();
  }

  int incrementBurritoConsiderations() {
    _burritoConsiderations++;
    notifyListeners();
    return _burritoConsiderations;
  }
}

```

---

## lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'posthog/posthog.dart';
import 'screens/burrito_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupPostHog();
  runApp(const BurritoApp());
}

class BurritoApp extends StatelessWidget {
  const BurritoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burrito App',
      // Match the web examples' look: system font stack on a light grey
      // page with #333 body text (see globals.css in the web examples).
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: Typography.blackCupertino.apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        ),
      ),
      // PosthogObserver captures a $screen event on every route change.
      // Routes must be named (like the `routes` map below) or the screen
      // views won't be recorded.
      // @see https://posthog.com/docs/libraries/flutter#capturing-screen-views
      navigatorObservers: [PosthogObserver()],
      initialRoute: HomeScreen.route,
      routes: {
        HomeScreen.route: (_) => const HomeScreen(),
        BurritoScreen.route: (_) => const BurritoScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
      },
    );
  }
}

```

---

## lib/posthog/posthog.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog credentials embedded at build time via --dart-define:
///
/// ```bash
/// flutter run \
///   --dart-define=POSTHOG_PROJECT_TOKEN=phc_your_project_token_here \
///   --dart-define=POSTHOG_HOST=https://us.i.posthog.com
/// ```
///
/// Get your project token from your PostHog project settings
/// (https://app.posthog.com/settings/project).
class PosthogEnv {
  static const projectToken = String.fromEnvironment('POSTHOG_PROJECT_TOKEN');
  static const host = String.fromEnvironment(
    'POSTHOG_HOST',
    // Usually 'https://us.i.posthog.com' or 'https://eu.i.posthog.com'
    defaultValue: 'https://us.i.posthog.com',
  );
}

/// Sets up the PostHog Flutter SDK manually from Dart.
///
/// Manual setup keeps all configuration in one place and is required for
/// session replay and surveys. Native auto-init is disabled with
/// `com.posthog.posthog.AUTO_INIT: false` in:
/// - android/app/src/main/AndroidManifest.xml
/// - ios/Runner/Info.plist
/// - macos/Runner/Info.plist
///
/// On Flutter Web the SDK is initialized by the posthog-js snippet in
/// web/index.html instead — the native `setup()` call is a no-op there.
///
/// The [projectToken] and [host] parameters exist for tests; production code
/// uses the build-time values from [PosthogEnv].
///
/// @see https://posthog.com/docs/libraries/flutter
Future<void> setupPostHog({
  String projectToken = PosthogEnv.projectToken,
  String host = PosthogEnv.host,
}) async {
  if (projectToken.isEmpty) {
    debugPrint(
      'PostHog project token not configured. Analytics will be disabled. '
      'Run with --dart-define=POSTHOG_PROJECT_TOKEN=phc_... to enable it.',
    );
    return;
  }

  final config = PostHogConfig(projectToken);
  config.host = host;

  // Verbose SDK logging in debug builds
  config.debug = kDebugMode;

  // Application lifecycle events (Application Installed, Application Updated,
  // Application Opened, Application Backgrounded) are captured by default
  // (captureApplicationLifecycleEvents, enabled since 5.23.0).

  // Error tracking: capture uncaught Flutter framework and platform
  // dispatcher errors as $exception events. Handled errors can be captured
  // manually with Posthog().captureException() (see ProfileScreen).
  // @see https://posthog.com/docs/error-tracking
  config.errorTrackingConfig.captureFlutterErrors = true;
  config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
  // Mark this app's stack frames as in-app in the error tracking UI
  config.errorTrackingConfig.inAppIncludes.add('package:burrito_app');

  await Posthog().setup(config);
}

```

---

## lib/screens/burrito_screen.dart

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../auth/auth_state.dart';
import '../theme.dart';
import '../widgets/page_scaffold.dart';

/// Burrito Consideration Screen.
///
/// Demonstrates PostHog event capture with custom properties. Each time the
/// user considers a burrito, an event is captured.
///
/// @see https://posthog.com/docs/libraries/flutter#capturing-events
class BurritoScreen extends StatefulWidget {
  const BurritoScreen({super.key});

  static const route = '/burrito';

  @override
  State<BurritoScreen> createState() => _BurritoScreenState();
}

class _BurritoScreenState extends State<BurritoScreen> {
  bool _hasConsidered = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _considerBurrito() async {
    final total = AuthState.instance.incrementBurritoConsiderations();
    setState(() => _hasConsidered = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hasConsidered = false);
    });

    // Capture a custom event with properties. We recommend a
    // [object] [verb] format for event names. Person data (like the
    // username) belongs in identify(), not in event properties.
    await Posthog().capture(
      eventName: 'burrito_considered',
      properties: {
        'total_considerations': total,
        'is_first_consideration': total == 1,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ListenableBuilder(
        listenable: AuthState.instance,
        builder: (context, _) {
          final auth = AuthState.instance;
          if (!auth.isLoggedIn) {
            return const Text(
              'Log in to consider burritos.',
              style: AppTextStyles.body,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Burrito consideration zone',
                  style: AppTextStyles.h1,
                ),
              ),
              const Text(
                'Take a moment to truly consider the potential of burritos.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: TextButton(
                        onPressed: _considerBurrito,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          overlayColor: AppColors.successHover,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        child: const Text(
                          'I have considered the burrito potential',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_hasConsidered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Thank you for your consideration! '
                          'Count: ${auth.burritoConsiderations}',
                          style: AppTextStyles.success,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              StatsBox(
                children: [
                  const Text('Consideration stats', style: AppTextStyles.h3),
                  Text(
                    'Total considerations: ${auth.burritoConsiderations}',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

```

---

## lib/screens/home_screen.dart

```dart
import 'package:flutter/material.dart';

import '../auth/auth_state.dart';
import '../theme.dart';
import '../widgets/page_scaffold.dart';

/// Home/login screen.
///
/// Logging in identifies the user in PostHog (see AuthState.logIn).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const route = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = '');
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please provide both username and password');
      return;
    }
    await AuthState.instance.logIn(username);
    if (!mounted) return;
    _usernameController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ListenableBuilder(
        listenable: AuthState.instance,
        builder: (context, _) {
          final auth = AuthState.instance;
          if (auth.isLoggedIn) {
            return _LoggedInView(username: auth.username!);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Welcome to Burrito Consideration App',
                  style: AppTextStyles.h1,
                ),
              ),
              const Text(
                'Please sign in to begin your burrito journey',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),
              const _FieldLabel('Username:'),
              _TextInput(
                controller: _usernameController,
                hint: 'Enter any username',
                onSubmitted: _signIn,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Password:'),
              _TextInput(
                controller: _passwordController,
                hint: 'Enter any password',
                obscure: true,
                onSubmitted: _signIn,
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error, style: AppTextStyles.error),
                ),
              const SizedBox(height: 16),
              _PrimaryButton(label: 'Sign In', onPressed: _signIn),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Note: This is a demo app. Use any username and password '
                  'to sign in.',
                  style: AppTextStyles.note,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoggedInView extends StatelessWidget {
  const _LoggedInView({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text('Welcome back, $username!', style: AppTextStyles.h1),
        ),
        const Text(
          'You are logged in. Feel free to explore:',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullet('Consider the potential of burritos'),
              _Bullet('View your profile and statistics'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: AppTextStyles.body),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmitted;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.body,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.note),
        isDense: true,
        contentPadding: const EdgeInsets.all(8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          overlayColor: AppColors.primaryHover,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(fontSize: 16, height: 1.6),
        ),
        child: Text(label),
      ),
    );
  }
}

```

---

## lib/screens/profile_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../auth/auth_state.dart';
import '../theme.dart';
import '../widgets/page_scaffold.dart';

/// User profile screen with an error tracking demo.
///
/// @see https://posthog.com/docs/error-tracking
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  Future<void> _triggerTestError(BuildContext context) async {
    try {
      throw StateError('Test error for PostHog error tracking');
    } catch (error, stackTrace) {
      // Capture handled exceptions manually. Uncaught Flutter errors are
      // captured automatically via errorTrackingConfig (see setupPostHog).
      await Posthog().captureException(
        error: error,
        stackTrace: stackTrace,
        properties: {'source': 'profile_test_button'},
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error captured and sent to PostHog!')),
      );
    }
  }

  String _journeyMessage(int considerations) {
    if (considerations == 0) {
      return "You haven't considered any burritos yet. "
          'Visit the Burrito Consideration page to start!';
    }
    if (considerations == 1) {
      return "You've considered the burrito potential once. Keep going!";
    }
    if (considerations < 5) {
      return "You're getting the hang of burrito consideration!";
    }
    if (considerations < 10) {
      return "You're becoming a burrito consideration expert!";
    }
    return 'You are a true burrito consideration master! 🌯';
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: ListenableBuilder(
        listenable: AuthState.instance,
        builder: (context, _) {
          final auth = AuthState.instance;
          if (!auth.isLoggedIn) {
            return const Text('Not logged in.', style: AppTextStyles.body);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('User Profile', style: AppTextStyles.h1),
              ),
              StatsBox(
                children: [
                  const Text('Your Information', style: AppTextStyles.h2),
                  _BoldLabelText(
                    label: 'Username:',
                    value: auth.username!,
                  ),
                  _BoldLabelText(
                    label: 'Burrito Considerations:',
                    value: '${auth.burritoConsiderations}',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _triggerTestError(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    overlayColor: AppColors.dangerHover,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  child: const Text('Trigger Test Error (for PostHog)'),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Your Burrito Journey', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                _journeyMessage(auth.burritoConsiderations),
                style: AppTextStyles.body,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoldLabelText extends StatelessWidget {
  const _BoldLabelText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.body,
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

```

---

## lib/theme.dart

```dart
import 'package:flutter/material.dart';

/// Design tokens mirroring the web examples' globals.css so every burrito
/// consideration app looks identical.
abstract final class AppColors {
  static const text = Color(0xFF333333); // body color: #333
  static const background = Color(0xFFF5F5F5); // body background: #f5f5f5
  static const header = Color(0xFF333333); // .header background
  static const headerHover = Color(0xFF555555); // .header a:hover
  static const primary = Color(0xFF0070F3); // .btn-primary
  static const primaryHover = Color(0xFF0051CC);
  static const danger = Color(0xFFDC3545); // .btn-logout / .error
  static const dangerHover = Color(0xFFC82333);
  static const success = Color(0xFF28A745); // .btn-burrito / .success
  static const successHover = Color(0xFF218838);
  static const note = Color(0xFF666666); // .note
  static const statsBackground = Color(0xFFF8F9FA); // .stats
  static const inputBorder = Color(0xFFDDDDDD); // .form-group input border
}

/// Text styles matching the browser defaults the CSS relies on
/// (16px body, line-height 1.6, bold headings at 2em/1.5em/1.17em).
abstract final class AppTextStyles {
  static const body = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: AppColors.text,
  );

  static const h1 = TextStyle(
    fontSize: 32,
    height: 1.6,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const h2 = TextStyle(
    fontSize: 24,
    height: 1.6,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const h3 = TextStyle(
    fontSize: 18.7,
    height: 1.6,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const label = TextStyle(
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const note = TextStyle(
    fontSize: 14,
    height: 1.6,
    color: AppColors.note,
  );

  static const error = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: AppColors.danger,
  );

  static const success = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: AppColors.success,
  );
}

```

---

## lib/widgets/app_header.dart

```dart
import 'package:flutter/material.dart';

import '../auth/auth_state.dart';
import '../screens/burrito_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';

/// Dark navigation header mirroring the web examples' `.header` bar:
/// nav links on the left, user section with logout on the right.
/// Collapses to two stacked rows on narrow (mobile) screens.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  void _goTo(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    if (route == HomeScreen.route) {
      navigator.popUntil((r) => r.isFirst);
    } else {
      navigator.pushNamed(route);
    }
  }

  Future<void> _logOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthState.instance.logOut();
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.header,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: AuthState.instance,
          builder: (context, _) {
            final auth = AuthState.instance;

            final nav = Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _HeaderLink(
                  label: 'Home',
                  onTap: () => _goTo(context, HomeScreen.route),
                ),
                if (auth.isLoggedIn) ...[
                  _HeaderLink(
                    label: 'Burrito Consideration',
                    onTap: () => _goTo(context, BurritoScreen.route),
                  ),
                  _HeaderLink(
                    label: 'Profile',
                    onTap: () => _goTo(context, ProfileScreen.route),
                  ),
                ],
              ],
            );

            final userSection = Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (auth.isLoggedIn) ...[
                  Text(
                    'Welcome, ${auth.username}!',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                  _LogoutButton(onPressed: () => _logOut(context)),
                ] else
                  Text(
                    'Not logged in',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
              ],
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 640;
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [nav, const SizedBox(height: 8), userSection],
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Flexible(child: nav), userSection],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.headerHover,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        overlayColor: AppColors.dangerHover,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 14, height: 1.6),
      ),
      child: const Text('Logout'),
    );
  }
}

```

---

## lib/widgets/page_scaffold.dart

```dart
import 'package:flutter/material.dart';

import '../theme.dart';
import 'app_header.dart';

/// Page shell mirroring the web examples' layout: dark header on top,
/// then a white `.container` card (max-width 600, radius 8, subtle shadow)
/// centered on the grey page background. Scrolls and shrinks padding on
/// small screens so it works on mobile too.
class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 640;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: narrow ? 16 : 32,
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: EdgeInsets.all(narrow ? 20 : 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000), // rgba(0,0,0,0.1)
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey info panel matching the `.stats` box.
class StatsBox extends StatelessWidget {
  const StatsBox({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

```

---

## macos/Podfile

```
# posthog_flutter requires macOS 10.15+, matching Flutter's default
platform :osx, '10.15'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure \"flutter pub get\" is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Flutter-Generated.xcconfig, then run \"flutter pub get\""
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_macos_podfile_setup

target 'Runner' do
  use_frameworks!

  flutter_install_all_macos_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)
  end
end

```

---

## macos/Runner/DebugProfile.entitlements

```entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<!-- Outgoing network access so PostHog can send events from the
	     sandboxed macOS app -->
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>

```

---

## macos/Runner/Info.plist

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- PostHog is set up manually from Dart (lib/posthog/posthog.dart),
	     so disable the SDK's native auto-init.
	     See https://posthog.com/docs/libraries/flutter -->
	<key>com.posthog.posthog.AUTO_INIT</key>
	<false/>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIconFile</key>
	<string></string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSMinimumSystemVersion</key>
	<string>$(MACOSX_DEPLOYMENT_TARGET)</string>
	<key>NSHumanReadableCopyright</key>
	<string>$(PRODUCT_COPYRIGHT)</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>

```

---

## macos/Runner/Release.entitlements

```entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<!-- Outgoing network access so PostHog can send events from the
	     sandboxed macOS app -->
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>

```

---

## pubspec.yaml

```yaml
name: burrito_app
description: "PostHog Flutter example app demonstrating product analytics, user identification, screen tracking, and error tracking."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  # PostHog Flutter SDK — the only dependency to add for PostHog integration.
  # @see https://posthog.com/docs/libraries/flutter
  posthog_flutter: ^5.32.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true

```

---

## web/index.html

```html
<!DOCTYPE html>
<html>
<head>
  <!--
    If you are serving your web app in a path other than the root, change the
    href value below to reflect the base path you are serving from.

    The path provided below has to start and end with a slash "/" in order for
    it to work correctly.

    For more details:
    * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base

    This is a placeholder for base href that will be replaced by the value of
    the `--base-href` argument provided to `flutter build`.
  -->
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="PostHog Flutter example app.">

  <!--
    PostHog for Flutter Web is initialized by this posthog-js snippet — the
    Dart Posthog().setup() call is a no-op on web. Replace the token below
    with your project token from https://app.posthog.com/settings/project.
    For session replay on Flutter Web, also enable canvas capture in your
    PostHog project settings (Flutter renders into a canvas element).
    @see https://posthog.com/docs/libraries/flutter
  -->
  <script async>
    !(function (t, e) {
      var o, n, p, r;
      e.__SV ||
        ((window.posthog = e),
        (e._i = []),
        (e.init = function (i, s, a) {
          function g(t, e) {
            var o = e.split(".");
            (2 == o.length && ((t = t[o[0]]), (e = o[1])),
              (t[e] = function () {
                t.push([e].concat(Array.prototype.slice.call(arguments, 0)));
              }));
          }
          (((p = t.createElement("script")).type = "text/javascript"),
            (p.crossOrigin = "anonymous"),
            (p.async = !0),
            (p.src = s.api_host + "/static/array.js"),
            (r = t.getElementsByTagName("script")[0]).parentNode.insertBefore(p, r));
          var u = e;
          for (
            void 0 !== a ? (u = e[a] = []) : (a = "posthog"),
              u.people = u.people || [],
              u.toString = function (t) { var e = "posthog"; return ("posthog" !== a && (e += "." + a), t || (e += " (stub)"), e); },
              u.people.toString = function () { return u.toString(1) + ".people (stub)"; },
              o = "capture identify alias people.set people.set_once set_config register register_once unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags getFeatureFlag getFeatureFlagResult reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys getNextSurveyStep onSessionId".split(" "),
              n = 0;
            n < o.length;
            n++
          )
            g(u, o[n]);
          e._i.push([i, s, a]);
        }),
        (e.__SV = 1));
    })(document, window.posthog || []);

    posthog.init("phc_your_project_token_here", {
      // Usually 'https://us.i.posthog.com' or 'https://eu.i.posthog.com'
      api_host: "https://us.i.posthog.com",
      defaults: "2025-05-24",
    });
  </script>

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="burrito_app">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>burrito_app</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <!--
    You can customize the "flutter_bootstrap.js" script.
    This is useful to provide a custom configuration to the Flutter loader
    or to give the user feedback during the initialization process.

    For more details:
    * https://docs.flutter.dev/platform-integration/web/initialization
  -->
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>

```

---

