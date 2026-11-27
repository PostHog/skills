> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Flutter Feature Flags installation

Canonical URL: https://posthog.com/docs/feature-flags/installation/flutter

> **Cloud region:** This page uses US Cloud hosts. For an EU Cloud project, use `https://eu.i.posthog.com` instead of `https://us.i.posthog.com` (ingestion host).

## On this page

- [Install with the wizard](#install-with-the-wizard)
- [Install the package](#install-the-package)
- [Platform setup](#platform-setup)
- [Send events](#send-events)
- [Evaluate boolean feature flags](#evaluate-boolean-feature-flags)
- [Evaluate multivariate feature flags](#evaluate-multivariate-feature-flags)
- [Running experiments](#running-experiments)
- [Next steps](#next-steps)

## Install with the wizard

Run this command in your project directory to add PostHog to your Flutter project. The wizard detects your framework, installs the SDK, and sets up your first events.

`npx @posthog/wizard`

Or set it up manually by following the rest of this guide.

> **CocoaPods is becoming read-only.** [CocoaPods trunk becomes read-only on December 2, 2026](https://blog.cocoapods.org/CocoaPods-Specs-Repo/), and `posthog-ios` 4.0 and later is only published through Swift Package Manager (SPM).
>
> `posthog_flutter` 6.0 and later uses `posthog-ios` 4.0 and installs on iOS and macOS through SPM only. It has no podspec. It needs Xcode 26 or later, iOS 15, and macOS 12. Flutter 3.44 and later turn SPM on by default. See the [Flutter migration guide](https://github.com/PostHog/posthog-flutter/blob/main/posthog_flutter/MIGRATION.md).
>
> `posthog_flutter` 5.x stays on `posthog-ios` 3.x through CocoaPods or SPM. If your app can't use SPM, stay on 5.x. That includes a Flutter module embedded in an iOS app on Flutter earlier than 3.50, which installs module plugins with CocoaPods.
>
> `posthog_flutter` 6.0 also needs Flutter 3.41 or later on every platform, including Android and web. `flutter pub get` fails on an older Flutter.

1.  1

    ## Install the package

    Required

    Add the PostHog Flutter SDK to your `pubspec.yaml`:

    pubspec.yaml

    ```yaml
    posthog_flutter: ^6.0.0
    ```

    `posthog_flutter 6.0` requires Flutter 3.41 or later on every platform.

    If you embed Flutter in an iOS app as a module (`flutter create -t module`), use Flutter 3.50 or later and build it with `flutter build swift-package`. Earlier Flutter versions install module plugins with CocoaPods, and `posthog_flutter` 6.0 has no podspec, so stay on `posthog_flutter` 5.x there.

2.  2

    ## Platform setup

    Required

    ## Tab

    Add these values to your `AndroidManifest.xml`:

    android/app/src/main/AndroidManifest.xml

    ```xml
    <application>
      <activity>
        [...]
      </activity>
      <meta-data android:name="com.posthog.posthog.PROJECT_TOKEN" android:value="<ph_project_token>" />
      <meta-data android:name="com.posthog.posthog.POSTHOG_HOST" android:value="https://us.i.posthog.com" />
      <meta-data android:name="com.posthog.posthog.CAPTURE_APPLICATION_LIFECYCLE_EVENTS" android:value="true" />
      <meta-data android:name="com.posthog.posthog.DEBUG" android:value="true" />
    </application>
    ```

    posthog\_flutter needs a minimum Android SDK version of **23** or higher. New Flutter projects default to 24, so change `android/app/build.gradle` only if your app sets a lower value:

    android/app/build.gradle

    ```groovy
    defaultConfig {
      minSdkVersion 23
      // rest of your config
    }
    ```

    ## Tab

    Add these values to your `Info.plist`:

    ios/Runner/Info.plist

    ```xml
    <dict>
      [...]
      <key>com.posthog.posthog.PROJECT_TOKEN</key>
      <string><ph_project_token></string>
      <key>com.posthog.posthog.POSTHOG_HOST</key>
      <string>https://us.i.posthog.com</string>
      <key>com.posthog.posthog.CAPTURE_APPLICATION_LIFECYCLE_EVENTS</key>
      <true/>
      <key>com.posthog.posthog.DEBUG</key>
      <true/>
    </dict>
    ```

    iOS and macOS builds require Xcode 26 or later. Set the minimum deployment target to iOS 15.0, or macOS 12.0 for a macOS app, in Xcode (**Runner > General > Minimum Deployments**). PostHog installs through Swift Package Manager, which is on by default from Flutter 3.44. On Flutter 3.41 to 3.43, or if you turned it off, run `flutter config --enable-swift-package-manager`. If you keep a `Podfile` for other plugins, set `platform :ios, '15.0'` there too (`platform :osx, '12.0'` in `macos/Podfile`), then run `flutter build ios --config-only` (or `flutter build macos --config-only`).

    ## Tab

    Add these values in `index.html`:

    web/index.html

    ```html
    <!DOCTYPE html>
    <html>
      <head>
        ...
        <script>
          !function(t,e){var o,n,p,r;e.__SV||(window.posthog && window.posthog.__loaded)||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}p||((p=t.createElement("script")).type="text/javascript",p.crossOrigin="anonymous",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",p.onerror=function(){p=null},(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r));var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],Object.defineProperty(u,"toString",{configurable:!0,enumerable:!0,writable:!0,value:function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e}}),Object.defineProperty(u.people,"toString",{configurable:!0,enumerable:!0,writable:!0,value:function(){return u.toString(1)+".people (stub)"}}),o="init capture register register_once register_for_session unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group identify setPersonProperties setPersonPropertiesForFlags resetPersonPropertiesForFlags setGroupPropertiesForFlags resetGroupPropertiesForFlags resetGroups onFeatureFlags addFeatureFlagsHandler onSessionId getSurveys getActiveMatchingSurveys renderSurvey canRenderSurvey getNextSurveyStep".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
          posthog.init('<ph_project_token>', {
              api_host: 'https://us.i.posthog.com',
              defaults: '2026-08-30',
          })
        </script>
      </head>
      <body>
        ...
      </body>
    </html>
    ```

3.  3

    ## Send events

    Recommended

    Once installed, PostHog will automatically start capturing events. You can also manually send events to test your integration:

    Dart

    ```dart
    import 'package:posthog_flutter/posthog_flutter.dart';
    
    await Posthog().capture(
        eventName: 'button_clicked',
        properties: {
          'button_name': 'signup'
        }
    );
    ```

4.  4

    ## Evaluate boolean feature flags

    Required

    Check if a feature flag is enabled:

    Dart

    ```dart
    final isMyFlagEnabled = await Posthog().isFeatureEnabled('flag-key');
    if (isMyFlagEnabled) {
        // Do something differently for this user
        // Optional: fetch the payload
        final matchedFlagPayload = (await Posthog().getFeatureFlagResult('flag-key'))?.payload;
    }
    ```

5.  5

    ## Evaluate multivariate feature flags

    Optional

    For multivariate flags, check which variant the user has been assigned:

    Dart

    ```dart
    final enabledVariant = await Posthog().getFeatureFlag('flag-key');
    if (enabledVariant == 'variant-key') { // replace 'variant-key' with the key of your variant
        // Do something differently for this user
        // Optional: fetch the payload
        final matchedFlagPayload = (await Posthog().getFeatureFlagResult('flag-key'))?.payload;
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
