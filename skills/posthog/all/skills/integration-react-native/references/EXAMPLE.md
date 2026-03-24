# PostHog React Native Example Project

Repository: https://github.com/PostHog/context-mill
Path: basics/react-native

---

## README.md

# PostHog React Native example

This is a bare [React Native](https://reactnative.dev/) example (no Expo) demonstrating PostHog integration with product analytics, user identification, autocapture, and error tracking.

## Features

- **Product analytics**: Track user events and behaviors
- **Autocapture**: Automatic touch event and screen view tracking
- **Error tracking**: Capture and track errors manually
- **User authentication**: Demo login system with PostHog user identification
- **Session persistence**: AsyncStorage for maintaining user sessions across app restarts
- **Native navigation**: React Navigation v7 with native stack navigator

## Prerequisites

### For iOS Development

You need a Mac with the following installed:

1. **Xcode** (from the Mac App Store)
   - Open App Store and search for "Xcode"
   - Install it (~12GB download)
   - After installing, open Xcode once to accept the license agreement

2. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```

3. **CocoaPods** (iOS dependency manager)
   ```bash
   brew install cocoapods
   ```
   Or without Homebrew:
   ```bash
   sudo gem install cocoapods
   ```

### For Android Development

1. **Android Studio** (the Android IDE)
   ```bash
   brew install --cask android-studio
   ```
   Or download from: https://developer.android.com/studio

2. **First-time Android Studio Setup**
   - Open Android Studio
   - Complete the setup wizard (downloads Android SDK automatically)
   - Go to **Settings → Languages & Frameworks → Android SDK**
   - Ensure "Android SDK Platform 34" (or latest) is installed

3. **Create an Android Emulator**
   - In Android Studio: **Tools → Device Manager**
   - Click **Create Device**
   - Select a phone (e.g., "Pixel 7")
   - Download a system image (e.g., API 34)
   - Finish and click the **Play** button to launch

4. **Environment Variables** (add to `~/.zshrc` or `~/.bashrc`)
   ```bash
   # Android SDK
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   
   # Java from Android Studio (required for Gradle)
   export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
   export PATH=$JAVA_HOME/bin:$PATH
   ```
   Then run `source ~/.zshrc` to apply.

5. **Create local.properties file** (if SDK location is not detected)
   Create `android/local.properties` with:
   ```
   sdk.dir=$HOME/Library/Android/sdk
   ```

6. **Clear Gradle cache** (required when jumping between different versions of Gradle)
   ```bash
   rm -rf ~/.gradle/caches/modules-2/files-2.1/org.gradle.toolchains/foojay-resolver
   ```

## Getting started

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

Create a `.env` file:

```bash
cp .env.example .env
```

Edit `.env` and add your PostHog project token:

```bash
POSTHOG_PROJECT_TOKEN=phc_your_project_token_here
POSTHOG_HOST=https://us.i.posthog.com
```

Get your PostHog project token from your [PostHog project settings](https://app.posthog.com/project/settings).

> **Note:** The app will still run without a PostHog project token - analytics will simply be disabled.

### 3. Run on iOS

Install iOS dependencies (first time only):
```bash
cd ios && pod install && cd ..
```

Run the app:
```bash
npm run ios
```

> **Note:** First build takes 5-10 minutes. Subsequent builds are much faster.

### 4. Run on Android

Make sure an Android emulator is running (from Android Studio Device Manager), then:

```bash
npm run android
```

> **Note:** First build takes 3-5 minutes.

## Troubleshooting

### iOS Issues

**"No `Podfile' found"**
- Make sure you're in the `ios` directory: `cd ios && pod install`

**Build fails with signing errors**
- Open `ios/BurritoApp.xcworkspace` in Xcode
- Select the project → Signing & Capabilities
- Select your development team

**Simulator not launching**
- Open Xcode → Open Developer Tool → Simulator
- Or run: `open -a Simulator`

### Android Issues

**"SDK location not found"**
- Ensure `ANDROID_HOME` is set in your shell profile
- Run `source ~/.zshrc` after adding it

**"No connected devices"**
- Launch an emulator from Android Studio Device Manager
- Or connect a physical device with USB debugging enabled

**Gradle build fails**
- Try: `cd android && ./gradlew clean && cd ..`
- Then: `npm run android`

## Project structure

```
src/
├── config/
│   └── posthog.ts           # PostHog client configuration
├── contexts/
│   └── AuthContext.tsx      # Authentication context with PostHog integration
├── navigation/
│   └── RootNavigator.tsx    # React Navigation stack navigator
├── screens/
│   ├── HomeScreen.tsx       # Home/login screen
│   ├── BurritoScreen.tsx    # Demo feature screen with event tracking
│   └── ProfileScreen.tsx    # User profile with error tracking demo
├── services/
│   └── storage.ts           # AsyncStorage wrapper for persistence
├── styles/
│   └── theme.ts             # Shared style constants
└── types/
    └── env.d.ts             # Type declarations for environment variables

App.tsx                      # Root component with PostHogProvider
index.js                     # App entry point
.env                         # Environment variables (create from .env.example)
ios/                         # Native iOS project (Xcode)
android/                     # Native Android project (Android Studio)
```

## Key integration points

### PostHog client setup (config/posthog.ts)

The PostHog client is configured with V4 SDK options. If no project token is provided, analytics are disabled gracefully:

```typescript
import PostHog from 'posthog-react-native'
import Config from 'react-native-config'

const apiKey = Config.POSTHOG_PROJECT_TOKEN
const isPostHogConfigured = apiKey && apiKey !== 'phc_your_project_token_here'

export const posthog = new PostHog(apiKey || 'placeholder_key', {
  host: Config.POSTHOG_HOST || 'https://us.i.posthog.com',
  disabled: !isPostHogConfigured,  // Disable if no project token
  captureAppLifecycleEvents: true,
  debug: __DEV__,
  flushAt: 20,
  flushInterval: 10000,
  preloadFeatureFlags: true,
})
```

### Provider setup with React Navigation v7 (App.tsx)

For React Navigation v7, `PostHogProvider` must be placed **inside** `NavigationContainer`, and screen tracking must be done manually:

```typescript
import { NavigationContainer, NavigationContainerRef } from '@react-navigation/native'
import { PostHogProvider } from 'posthog-react-native'
import { posthog } from './src/config/posthog'

export default function App() {
  const navigationRef = useRef<NavigationContainerRef<RootStackParamList>>(null)
  const routeNameRef = useRef<string | undefined>()

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name
      }}
      onStateChange={() => {
        // Manual screen tracking for React Navigation v7
        const previousRouteName = routeNameRef.current
        const currentRouteName = navigationRef.current?.getCurrentRoute()?.name

        if (previousRouteName !== currentRouteName && currentRouteName) {
          posthog.screen(currentRouteName, {
            previous_screen: previousRouteName,
          })
        }
        routeNameRef.current = currentRouteName
      }}
    >
      <PostHogProvider
        client={posthog}
        autocapture={{
          captureScreens: false,  // Disabled for React Navigation v7
          captureTouches: true,   // Enable touch event autocapture
          propsToCapture: ['testID'],
        }}
      >
        <AuthProvider>
          <RootNavigator />
        </AuthProvider>
      </PostHogProvider>
    </NavigationContainer>
  )
}
```

### Autocapture

PostHog autocapture automatically tracks:

- **Touch events**: When users interact with the screen
- **App lifecycle events**: Application Installed, Updated, Opened, Became Active, Backgrounded

Use `testID` prop on components to help identify them in analytics:

```typescript
<TouchableOpacity testID="consider-burrito-button" onPress={handlePress}>
  <Text>Consider Burrito</Text>
</TouchableOpacity>
```

### User identification (contexts/AuthContext.tsx)

Use `$set` and `$set_once` for person properties:

```typescript
import { usePostHog } from 'posthog-react-native'

const posthog = usePostHog()

// On login - identify with person properties
posthog.identify(username, {
  $set: {
    username: username,
  },
  $set_once: {
    first_login_date: new Date().toISOString(),
  },
})

// Capture login event
posthog.capture('user_logged_in', {
  username: username,
  is_new_user: isNewUser,
})

// On logout - reset clears distinct ID and anonymous ID
posthog.capture('user_logged_out')
posthog.reset()
```

### Event tracking (screens/BurritoScreen.tsx)

Capture custom events with properties:

```typescript
import { usePostHog } from 'posthog-react-native'

const posthog = usePostHog()

// We recommend using a [object] [verb] format for event names
posthog.capture('burrito_considered', {
  total_considerations: user.burritoConsiderations + 1,
  username: user.username,
})
```

### Error tracking (screens/ProfileScreen.tsx)

Capture exceptions using the `$exception` event:

```typescript
import { usePostHog } from 'posthog-react-native'

const posthog = usePostHog()

try {
  throw new Error('Test error for PostHog error tracking')
} catch (err) {
  posthog.capture('$exception', {
    $exception_type: err.name,
    $exception_message: err.message,
    $exception_source: 'ProfileScreen',
    $exception_stack_trace_raw: err.stack,
  })
}
```

### Session persistence (services/storage.ts)

AsyncStorage replaces localStorage for persisting user sessions:

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage'

export const storage = {
  getCurrentUser: async (): Promise<string | null> => {
    return await AsyncStorage.getItem('currentUser')
  },

  setCurrentUser: async (username: string): Promise<void> => {
    await AsyncStorage.setItem('currentUser', username)
  },

  saveUser: async (user: User): Promise<void> => {
    const users = await storage.getUsers()
    users[user.username] = user
    await AsyncStorage.setItem('users', JSON.stringify(users))
  },
}
```

## Learn more

- [PostHog documentation](https://posthog.com/docs)
- [PostHog React Native integration](https://posthog.com/docs/libraries/react-native)
- [PostHog React Native autocapture](https://posthog.com/docs/libraries/react-native#autocapture)
- [PostHog React Native screen tracking](https://posthog.com/docs/libraries/react-native#capturing-screen-views)
- [React Native documentation](https://reactnative.dev/docs/getting-started)
- [React Native environment setup](https://reactnative.dev/docs/set-up-your-environment)
- [React Navigation documentation](https://reactnavigation.org/docs/getting-started)

---

## __tests__/App.test.tsx

```tsx
/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App from '../App';

test('renders correctly', async () => {
  await ReactTestRenderer.act(() => {
    ReactTestRenderer.create(<App />);
  });
});

```

---

## .env.example

```example
POSTHOG_PROJECT_TOKEN=phc_your_project_token_here
POSTHOG_HOST=https://us.i.posthog.com

```

---

## .prettierrc.js

```js
module.exports = {
  arrowParens: 'avoid',
  singleQuote: true,
  trailingComma: 'all',
};

```

---

## android/app/debug.keystore

```keystore
����          androiddebugkey  CJ���  0��0
+* ��N���O�J�`>���X'����_���ȏ�R9���,xJ'K~\j��:ز��}�U)Q]"���ա!�	Ȉ��Ù��F�5�H�x�A�\�P�)��@�I�s�d��>�2#m�י�j/8p��","ȁ��|\����1e�7�!����h(����.�Fi5��o��ung�*�!�����vF��֪�Sb!��T��4��P<G�̑�8���(��է!Zd"�{�k���'_+ �k��5o�>9�R.+4�/w3Y�s�By�������0(J�)pB�g̝��R�]�hT.?�0���޳���kGg�=�/����	^Q����".O�Qŗ���Q���Yg+8��f�%� �"`�Vf�b���M�6hW�q�t���[x�Ӏ��%\l���XV���u}:�9��'+N��7:z\��4�#����A�G���ݘLJad��ɓ�����{tbP�ў�lʉD}�I����m;�Ɉ#�t�6G�;!w��b@�xf)�G�EA�5X8 �sE_?/f��)��y�#��~�EZiW��L��mj��9)��LpoBI@f�]u�C����8g1B4���9�����b,���,b� �;�i���� �#���^#�d�ˢ���~�<w%JE��V�1d���/��=��Z�o�l���JC2��85�%8j�o��U�)����-nE}1(���%���01�	-!I��Zz�g�l5����V�@v����>��x�VwLw_���N���o�i7E�/�(���f�0ڸl��ۅl��On�cѾ�d8�,J�&N��Ih��\pM^���{�z��T�Z�ڳ�r�u�(���3r�<��Y����K=��V�E�o�e��uǳ�z�"d#x�e�{o����\5�o�u��i�nvW��@%��9z��C�C:���mNA��8Z�zI��f�S�(ӝ{r292�p�{�pO') ��m5V�L��[c�ՒTd���'�� p>*�R��0>NH��c���'K���dp�Z�kl�=NmKW�ȧ��)�9���ɴ@:��l�c���~��������GF�K�`�� ����|���=����3P*�.��\vUԑd�����|��H���x��2����p�Z��g��E�ƈ#f�rK����F��D8�"�V)�n|���ʴ�1�(�o�$J����a��\sݦ8�$^@$�Q�.�vK��D�	e�/�������QG��
˺��s����Y�q    X.509  0�{0�c�#.�b0	*�H�� 0m10	UUS10UUnknown10UUnknown10U
Unknown10UAndroid10UAndroid Debug0 131231223504Z20520430223504Z0m10	UUS10UUnknown10UUnknown10U
Unknown10UAndroid10UAndroid Debug0�"0	*�H�� � 0�
� ��n &�l�Dx�%�[��w��zg�}��?�^�SkX��6��gp��5��q$����v�B�����/��4��X�Z[�H7�Wk�X���3�=!�)6�P���9�O�ٵa�WӈEI,Ժ��A_���u�si��>��W���@ُ-���' ��c8]������UJ�*5Y�}c����Jq���b@�C�G���H�ty+ ߓ!�Cߙ]�B7i��+�-#�O��.p���%x
�EIr�M�%�����a �!00U��8�Ҋ�X��
�C(�#� 0	*�H�� � _�v��cMP��u����Nz�w����==k��,
m~<���vֶ�'.��h%�h�w�0E^{�ù�/Oz��u�R��$_1�I�~����s��ܖ��ӓ���֭�\�JX��j��;RC�՜�n<q�f�$��Z1N�������7����ڵk[Ųm��5^B����]W��e���i4V��*:�D~]z�ޝ����<��l.e���Ɖ��#�L�:c�~0�?���q�I�@���x�٨�*I�ӗ���Y`G'@^w�
```

---

## android/app/proguard-rules.pro

```pro
# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

```

---

## android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
      android:name=".MainApplication"
      android:label="@string/app_name"
      android:icon="@mipmap/ic_launcher"
      android:roundIcon="@mipmap/ic_launcher_round"
      android:allowBackup="false"
      android:theme="@style/AppTheme"
      android:usesCleartextTraffic="${usesCleartextTraffic}"
      android:supportsRtl="true">
      <activity
        android:name=".MainActivity"
        android:label="@string/app_name"
        android:configChanges="keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode"
        android:launchMode="singleTask"
        android:windowSoftInputMode="adjustResize"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
      </activity>
    </application>
</manifest>

```

---

## android/app/src/main/java/com/burritoapp/MainActivity.kt

```kt
package com.burritoapp

import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate

class MainActivity : ReactActivity() {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  override fun getMainComponentName(): String = "BurritoApp"

  /**
   * Returns the instance of the [ReactActivityDelegate]. We use [DefaultReactActivityDelegate]
   * which allows you to enable New Architecture with a single boolean flags [fabricEnabled]
   */
  override fun createReactActivityDelegate(): ReactActivityDelegate =
      DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)
}

```

---

## android/app/src/main/java/com/burritoapp/MainApplication.kt

```kt
package com.burritoapp

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
      context = applicationContext,
      packageList =
        PackageList(this).packages.apply {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // add(MyReactNativePackage())
        },
    )
  }

  override fun onCreate() {
    super.onCreate()
    loadReactNative(this)
  }
}

```

---

## android/app/src/main/res/drawable/rn_edit_text_material.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright (C) 2014 The Android Open Source Project

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
-->
<inset xmlns:android="http://schemas.android.com/apk/res/android"
       android:insetLeft="@dimen/abc_edit_text_inset_horizontal_material"
       android:insetRight="@dimen/abc_edit_text_inset_horizontal_material"
       android:insetTop="@dimen/abc_edit_text_inset_top_material"
       android:insetBottom="@dimen/abc_edit_text_inset_bottom_material"
       >

    <selector>
        <!--
          This file is a copy of abc_edit_text_material (https://bit.ly/3k8fX7I).
          The item below with state_pressed="false" and state_focused="false" causes a NullPointerException.
          NullPointerException:tempt to invoke virtual method 'android.graphics.drawable.Drawable android.graphics.drawable.Drawable$ConstantState.newDrawable(android.content.res.Resources)'

          <item android:state_pressed="false" android:state_focused="false" android:drawable="@drawable/abc_textfield_default_mtrl_alpha"/>

          For more info, see https://bit.ly/3CdLStv (react-native/pull/29452) and https://bit.ly/3nxOMoR.
        -->
        <item android:state_enabled="false" android:drawable="@drawable/abc_textfield_default_mtrl_alpha"/>
        <item android:drawable="@drawable/abc_textfield_activated_mtrl_alpha"/>
    </selector>

</inset>

```

---

## android/app/src/main/res/values/strings.xml

```xml
<resources>
    <string name="app_name">BurritoApp</string>
</resources>

```

---

## android/app/src/main/res/values/styles.xml

```xml
<resources>

    <!-- Base application theme. -->
    <style name="AppTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
        <!-- Customize your theme here. -->
        <item name="android:editTextBackground">@drawable/rn_edit_text_material</item>
    </style>

</resources>

```

---

## android/gradle.properties

```properties
# Project-wide Gradle settings.

# IDE (e.g. Android Studio) users:
# Gradle settings configured through the IDE *will override*
# any settings specified in this file.

# For more details on how to configure your build environment visit
# http://www.gradle.org/docs/current/userguide/build_environment.html

# Specifies the JVM arguments used for the daemon process.
# The setting is particularly useful for tweaking memory settings.
# Default value: -Xmx512m -XX:MaxMetaspaceSize=256m
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m

# When configured, Gradle will run in incubating parallel mode.
# This option should only be used with decoupled projects. More details, visit
# http://www.gradle.org/docs/current/userguide/multi_project_builds.html#sec:decoupled_projects
# org.gradle.parallel=true

# AndroidX package structure to make it clearer which packages are bundled with the
# Android operating system, and which are packaged with your app's APK
# https://developer.android.com/topic/libraries/support-library/androidx-rn
android.useAndroidX=true

# Use this property to specify which architecture you want to build.
# You can also override it from the CLI using
# ./gradlew <task> -PreactNativeArchitectures=x86_64
reactNativeArchitectures=armeabi-v7a,arm64-v8a,x86,x86_64

# Use this property to enable support to the new architecture.
# This will allow you to use TurboModules and the Fabric render in
# your application. You should enable this flag either if you want
# to write custom TurboModules/Fabric components OR use libraries that
# are providing them.
newArchEnabled=true

# Use this property to enable or disable the Hermes JS engine.
# If set to false, you will be using JSC instead.
hermesEnabled=true

# Use this property to enable edge-to-edge display support.
# This allows your app to draw behind system bars for an immersive UI.
# Note: Only works with ReactActivity and should not be used with custom Activity.
edgeToEdgeEnabled=false

```

---

## App.tsx

```tsx
import React, { useRef } from 'react'
import { StatusBar } from 'react-native'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import {
  NavigationContainer,
  NavigationContainerRef,
} from '@react-navigation/native'
import { PostHogProvider } from 'posthog-react-native'

import { AuthProvider } from './src/contexts/AuthContext'
import { RootNavigator, RootStackParamList } from './src/navigation/RootNavigator'
import { posthog } from './src/config/posthog'
import { colors } from './src/styles/theme'

/**
 * Burrito Consideration App
 *
 * A demo React Native application showcasing PostHog analytics integration.
 *
 * Features:
 * - User authentication (demo mode - accepts any credentials)
 * - Burrito consideration counter with event tracking
 * - User profile with statistics
 * - Error tracking demonstration
 *
 * @see https://posthog.com/docs/libraries/react-native
 */
export default function App() {
  const navigationRef = useRef<NavigationContainerRef<RootStackParamList>>(null)
  const routeNameRef = useRef<string | undefined>()

  return (
    <SafeAreaProvider>
      <StatusBar
        barStyle="light-content"
        backgroundColor={colors.headerBackground}
      />
      <NavigationContainer
        ref={navigationRef}
        onReady={() => {
          // Store the initial route name
          routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name
        }}
        onStateChange={() => {
          // Track screen views manually for React Navigation v7
          const previousRouteName = routeNameRef.current
          const currentRouteName = navigationRef.current?.getCurrentRoute()?.name

          if (previousRouteName !== currentRouteName && currentRouteName) {
            // Capture screen view event
            posthog.screen(currentRouteName, {
              previous_screen: previousRouteName,
            })
          }

          // Update the stored route name
          routeNameRef.current = currentRouteName
        }}
      >
        {/*
          PostHogProvider is placed INSIDE NavigationContainer for React Navigation v7.

          For React Navigation v7, we disable automatic screen capture and handle it
          manually via onStateChange above. Touch event autocapture is still enabled.

          @see https://posthog.com/docs/libraries/react-native#with-react-navigationnative-and-autocapture
        */}
        <PostHogProvider
          client={posthog}
          autocapture={{
            // Disable automatic screen capture for React Navigation v7
            // We handle screen tracking manually via NavigationContainer.onStateChange
            captureScreens: false,
            // Enable touch event autocapture
            captureTouches: true,
            // Limit which props are captured for touch events
            propsToCapture: ['testID'],
            // Maximum number of elements captured in touch event hierarchy
            maxElementsCaptured: 20,
          }}
        >
          <AuthProvider>
            <RootNavigator />
          </AuthProvider>
        </PostHogProvider>
      </NavigationContainer>
    </SafeAreaProvider>
  )
}

```

---

## babel.config.js

```js
module.exports = {
  presets: ['module:@react-native/babel-preset'],
};

```

---

## Gemfile

```
source 'https://rubygems.org'

# You may use http://rbenv.org/ or https://rvm.io/ to install and use this version
ruby ">= 2.6.10"

# Exclude problematic versions of cocoapods and activesupport that causes build failures.
gem 'cocoapods', '>= 1.13', '!= 1.15.0', '!= 1.15.1'
gem 'activesupport', '>= 6.1.7.5', '!= 7.1.0'
gem 'xcodeproj', '< 1.26.0'
gem 'concurrent-ruby', '< 1.3.4'

# Ruby 3.4.0 has removed some libraries from the standard library.
gem 'bigdecimal'
gem 'logger'
gem 'benchmark'
gem 'mutex_m'

```

---

## index.js

```js
/**
 * @format
 */

import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';

AppRegistry.registerComponent(appName, () => App);

```

---

## ios/.xcode.env

```env
# This `.xcode.env` file is versioned and is used to source the environment
# used when running script phases inside Xcode.
# To customize your local environment, you can create an `.xcode.env.local`
# file that is not versioned.

# NODE_BINARY variable contains the PATH to the node executable.
#
# Customize the NODE_BINARY variable here.
# For example, to use nvm with brew, add the following line
# . "$(brew --prefix nvm)/nvm.sh" --no-use
export NODE_BINARY=$(command -v node)

```

---

## ios/BurritoApp.xcodeproj/xcshareddata/xcschemes/BurritoApp.xcscheme

```xcscheme
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1210"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "13B07F861A680F5B00A75B9A"
               BuildableName = "BurritoApp.app"
               BlueprintName = "BurritoApp"
               ReferencedContainer = "container:BurritoApp.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "00E356ED1AD99517003FC87E"
               BuildableName = "BurritoAppTests.xctest"
               BlueprintName = "BurritoAppTests"
               ReferencedContainer = "container:BurritoApp.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "13B07F861A680F5B00A75B9A"
            BuildableName = "BurritoApp.app"
            BlueprintName = "BurritoApp"
            ReferencedContainer = "container:BurritoApp.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "13B07F861A680F5B00A75B9A"
            BuildableName = "BurritoApp.app"
            BlueprintName = "BurritoApp"
            ReferencedContainer = "container:BurritoApp.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>

```

---

## ios/BurritoApp.xcworkspace/contents.xcworkspacedata

```xcworkspacedata
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:BurritoApp.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:Pods/Pods.xcodeproj">
   </FileRef>
</Workspace>

```

---

## ios/BurritoApp/AppDelegate.swift

```swift
import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    window = UIWindow(frame: UIScreen.main.bounds)

    factory.startReactNative(
      withModuleName: "BurritoApp",
      in: window,
      launchOptions: launchOptions
    )

    return true
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}

```

---

## ios/BurritoApp/Info.plist

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>BurritoApp</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string></string>
	<key>RCTNewArchEnabled</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>arm64</string>
	</array>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
</dict>
</plist>

```

---

## ios/BurritoApp/LaunchScreen.storyboard

```storyboard
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="15702" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina4_7" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="15704"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <!--View Controller-->
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <label opaque="NO" clipsSubviews="YES" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="BurritoApp" textAlignment="center" lineBreakMode="middleTruncation" baselineAdjustment="alignBaselines" minimumFontSize="18" translatesAutoresizingMaskIntoConstraints="NO" id="GJd-Yh-RWb">
                                <rect key="frame" x="0.0" y="202" width="375" height="43"/>
                                <fontDescription key="fontDescription" type="boldSystem" pointSize="36"/>
                                <nil key="highlightedColor"/>
                            </label>
                            <label opaque="NO" clipsSubviews="YES" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="Powered by React Native" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" minimumFontSize="9" translatesAutoresizingMaskIntoConstraints="NO" id="MN2-I3-ftu">
                                <rect key="frame" x="0.0" y="626" width="375" height="21"/>
                                <fontDescription key="fontDescription" type="system" pointSize="17"/>
                                <nil key="highlightedColor"/>
                            </label>
                        </subviews>
                        <color key="backgroundColor" systemColor="systemBackgroundColor" cocoaTouchSystemColor="whiteColor"/>
                        <constraints>
                            <constraint firstItem="Bcu-3y-fUS" firstAttribute="bottom" secondItem="MN2-I3-ftu" secondAttribute="bottom" constant="20" id="OZV-Vh-mqD"/>
                            <constraint firstItem="Bcu-3y-fUS" firstAttribute="centerX" secondItem="GJd-Yh-RWb" secondAttribute="centerX" id="Q3B-4B-g5h"/>
                            <constraint firstItem="MN2-I3-ftu" firstAttribute="centerX" secondItem="Bcu-3y-fUS" secondAttribute="centerX" id="akx-eg-2ui"/>
                            <constraint firstItem="MN2-I3-ftu" firstAttribute="leading" secondItem="Bcu-3y-fUS" secondAttribute="leading" id="i1E-0Y-4RG"/>
                            <constraint firstItem="GJd-Yh-RWb" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="bottom" multiplier="1/3" constant="1" id="moa-c2-u7t"/>
                            <constraint firstItem="GJd-Yh-RWb" firstAttribute="leading" secondItem="Bcu-3y-fUS" secondAttribute="leading" symbolic="YES" id="x7j-FC-K8j"/>
                        </constraints>
                        <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="52.173913043478265" y="375"/>
        </scene>
    </scenes>
</document>

```

---

## ios/BurritoApp/PrivacyInfo.xcprivacy

```xcprivacy
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>C617.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategorySystemBootTime</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>35F9.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryDiskSpace</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>85F4.1</string>
			</array>
		</dict>
	</array>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyTracking</key>
	<false/>
</dict>
</plist>

```

---

## ios/Podfile

```
# Resolve react_native_pods.rb with node to allow for hoisting
require Pod::Executable.execute_command('node', ['-p',
  'require.resolve(
    "react-native/scripts/react_native_pods.rb",
    {paths: [process.argv[1]]},
  )', __dir__]).strip

platform :ios, min_ios_version_supported
prepare_react_native_project!

linkage = ENV['USE_FRAMEWORKS']
if linkage != nil
  Pod::UI.puts "Configuring Pod with #{linkage}ally linked Frameworks".green
  use_frameworks! :linkage => linkage.to_sym
end

target 'BurritoApp' do
  config = use_native_modules!

  use_react_native!(
    :path => config[:reactNativePath],
    # An absolute path to your application root.
    :app_path => "#{Pod::Config.instance.installation_root}/.."
  )

  post_install do |installer|
    react_native_post_install(
      installer,
      config[:reactNativePath],
      :mac_catalyst_enabled => false,
      # :ccache_enabled => true
    )
  end
end

```

---

## jest.config.js

```js
module.exports = {
  preset: 'react-native',
};

```

---

## metro.config.js

```js
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);

```

---

## src/config/posthog.ts

```ts
import PostHog from 'posthog-react-native'
import Config from 'react-native-config'

// Environment variables are embedded at build time via react-native-config
// Ensure .env file exists with POSTHOG_PROJECT_TOKEN and POSTHOG_HOST
const apiKey = Config.POSTHOG_PROJECT_TOKEN
const host = Config.POSTHOG_HOST || 'https://us.i.posthog.com'
const isPostHogConfigured = apiKey && apiKey !== 'phc_your_project_token_here'

if (!isPostHogConfigured) {
  console.warn(
    'PostHog project token not configured. Analytics will be disabled. ' +
    'Set POSTHOG_PROJECT_TOKEN in your .env file to enable analytics.'
  )
}

/**
 * PostHog client instance for bare React Native
 *
 * Configuration loaded from .env via react-native-config (embedded at build time).
 * Required peer dependencies: @react-native-async-storage/async-storage,
 * react-native-device-info, react-native-localize
 *
 * @see https://posthog.com/docs/libraries/react-native
 */
export const posthog = new PostHog(apiKey || 'placeholder_key', {
  // PostHog API host (usually 'https://us.i.posthog.com' or 'https://eu.i.posthog.com')
  host,

  // Disable PostHog if project token is not configured
  disabled: !isPostHogConfigured,

  // Capture app lifecycle events:
  // - Application Installed, Application Updated
  // - Application Opened, Application Became Active, Application Backgrounded
  captureAppLifecycleEvents: true,

  // Enable debug mode in development for verbose logging
  debug: __DEV__,

  // Batching: queue events and flush periodically to optimize battery usage
  flushAt: 20,              // Number of events to queue before sending
  flushInterval: 10000,     // Interval in ms between periodic flushes
  maxBatchSize: 100,        // Maximum events per batch
  maxQueueSize: 1000,       // Maximum queued events (oldest dropped when full)

  // Feature flags
  preloadFeatureFlags: true,        // Load flags on initialization
  sendFeatureFlagEvent: true,       // Track getFeatureFlag calls for experiments
  featureFlagsRequestTimeoutMs: 10000, // Timeout for flag requests (prevents blocking)

  // Network settings
  requestTimeout: 10000,    // General request timeout in ms
  fetchRetryCount: 3,       // Number of retry attempts for failed requests
  fetchRetryDelay: 3000,    // Delay between retries in ms
})

// Export helper to check if PostHog is enabled
export const isPostHogEnabled = isPostHogConfigured

```

---

## src/contexts/AuthContext.tsx

```tsx
import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
  useCallback,
} from 'react'
import { usePostHog } from 'posthog-react-native'
import { storage, User } from '../services/storage'

interface AuthContextType {
  user: User | null
  isLoading: boolean
  login: (username: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
  incrementBurritoConsiderations: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

interface AuthProviderProps {
  children: ReactNode
}

/**
 * Authentication Provider with PostHog integration
 *
 * Manages user authentication state and integrates with PostHog for:
 * - User identification (posthog.identify)
 * - Login/logout event tracking
 * - Session reset on logout
 *
 * @see https://posthog.com/docs/libraries/react-native#identifying-users
 */
export function AuthProvider({ children }: AuthProviderProps) {
  const posthog = usePostHog()
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Restore session on app launch
  useEffect(() => {
    restoreSession()
  }, [])

  const restoreSession = async () => {
    try {
      const storedUsername = await storage.getCurrentUser()
      if (storedUsername) {
        const existingUser = await storage.getUser(storedUsername)
        if (existingUser) {
          setUser(existingUser)

          // Re-identify user in PostHog on session restore
          // This ensures events are correctly attributed after app restart
          posthog.identify(storedUsername, {
            $set: {
              username: storedUsername,
            },
          })
        }
      }
    } catch (error) {
      console.error('Failed to restore session:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const login = useCallback(
    async (username: string, password: string): Promise<boolean> => {
      // Simple validation (demo app accepts any username/password)
      if (!username.trim() || !password.trim()) {
        return false
      }

      try {
        // Check if user exists or create new
        const existingUser = await storage.getUser(username)
        const isNewUser = !existingUser

        const userData: User = existingUser || {
          username,
          burritoConsiderations: 0,
        }

        // Save user data
        await storage.saveUser(userData)
        await storage.setCurrentUser(username)
        setUser(userData)

        // PostHog identify - use username as distinct ID
        // $set updates properties every time, $set_once only sets if not already set
        // @see https://posthog.com/docs/libraries/react-native#identifying-users
        posthog.identify(username, {
          $set: {
            username: username,
          },
          $set_once: {
            first_login_date: new Date().toISOString(),
          },
        })

        // Capture login event with properties
        // @see https://posthog.com/docs/libraries/react-native#capturing-events
        posthog.capture('user_logged_in', {
          username: username,
          is_new_user: isNewUser,
        })

        return true
      } catch (error) {
        console.error('Login error:', error)
        return false
      }
    },
    [posthog],
  )

  const logout = useCallback(async () => {
    // Capture logout event before reset
    posthog.capture('user_logged_out')

    // Reset PostHog - clears the current user's distinct ID and anonymous ID
    // This should be called when the user logs out
    // @see https://posthog.com/docs/libraries/react-native#reset-after-logout
    posthog.reset()

    await storage.removeCurrentUser()
    setUser(null)
  }, [posthog])

  const incrementBurritoConsiderations = useCallback(async () => {
    if (user) {
      const updatedUser: User = {
        ...user,
        burritoConsiderations: user.burritoConsiderations + 1,
      }
      setUser(updatedUser)
      await storage.saveUser(updatedUser)
    }
  }, [user])

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        login,
        logout,
        incrementBurritoConsiderations,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

```

---

## src/navigation/RootNavigator.tsx

```tsx
import React from 'react'
import { ActivityIndicator, View, StyleSheet } from 'react-native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { useAuth } from '../contexts/AuthContext'
import { colors } from '../styles/theme'

import HomeScreen from '../screens/HomeScreen'
import BurritoScreen from '../screens/BurritoScreen'
import ProfileScreen from '../screens/ProfileScreen'

// Type definitions for navigation
export type RootStackParamList = {
  Home: undefined
  Burrito: undefined
  Profile: undefined
}

const Stack = createNativeStackNavigator<RootStackParamList>()

export function RootNavigator() {
  const { isLoading } = useAuth()

  // Show loading indicator while restoring session
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    )
  }

  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.headerBackground,
        },
        headerTintColor: colors.headerText,
        headerTitleStyle: {
          fontWeight: 'bold',
        },
        headerBackTitleVisible: false,
        animation: 'slide_from_right',
      }}
    >
      <Stack.Screen
        name="Home"
        component={HomeScreen}
        options={{
          title: 'Burrito App',
        }}
      />
      <Stack.Screen
        name="Burrito"
        component={BurritoScreen}
        options={{
          title: 'Burrito Consideration',
        }}
      />
      <Stack.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          title: 'Profile',
        }}
      />
    </Stack.Navigator>
  )
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
})

```

---

## src/screens/BurritoScreen.tsx

```tsx
import React, { useState, useEffect } from 'react'
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native'
import { useNavigation } from '@react-navigation/native'
import { NativeStackNavigationProp } from '@react-navigation/native-stack'
import { usePostHog } from 'posthog-react-native'
import { useAuth } from '../contexts/AuthContext'
import { RootStackParamList } from '../navigation/RootNavigator'
import {
  colors,
  spacing,
  typography,
  borderRadius,
  shadows,
} from '../styles/theme'

type BurritoScreenNavigationProp = NativeStackNavigationProp<
  RootStackParamList,
  'Burrito'
>

/**
 * Burrito Consideration Screen
 *
 * Demonstrates PostHog event tracking with custom properties.
 * Each time the user considers a burrito, an event is captured.
 *
 * @see https://posthog.com/docs/libraries/react-native#capturing-events
 */
export default function BurritoScreen() {
  const { user, incrementBurritoConsiderations } = useAuth()
  const navigation = useNavigation<BurritoScreenNavigationProp>()
  const posthog = usePostHog()
  const [hasConsidered, setHasConsidered] = useState(false)

  // Redirect to home if not logged in
  useEffect(() => {
    if (!user) {
      navigation.navigate('Home')
    }
  }, [user, navigation])

  if (!user) {
    return null
  }

  const handleConsideration = async () => {
    const newCount = user.burritoConsiderations + 1

    // Update state first for immediate feedback
    await incrementBurritoConsiderations()
    setHasConsidered(true)

    // Hide success message after 2 seconds
    setTimeout(() => setHasConsidered(false), 2000)

    // Capture custom event in PostHog with properties
    // We recommend using a [object] [verb] format for event names
    // @see https://posthog.com/docs/libraries/react-native#capturing-events
    posthog.capture('burrito_considered', {
      total_considerations: newCount,
      username: user.username,
    })
  }

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.title}>Burrito Consideration Zone</Text>
        <Text style={styles.text}>
          Take a moment to truly consider the potential of burritos.
        </Text>

        {/*
          testID is captured by PostHog autocapture for touch events
          This helps identify the button in analytics
          @see https://posthog.com/docs/libraries/react-native#autocapture
        */}
        <TouchableOpacity
          style={styles.burritoButton}
          onPress={handleConsideration}
          activeOpacity={0.8}
          testID="consider-burrito-button"
        >
          <Text style={styles.burritoButtonText}>Consider Burrito</Text>
        </TouchableOpacity>

        {hasConsidered && (
          <View style={styles.successContainer}>
            <Text style={styles.success}>
              Thank you for your consideration!
            </Text>
            <Text style={styles.successCount}>
              Count: {user.burritoConsiderations}
            </Text>
          </View>
        )}

        <View style={styles.stats}>
          <Text style={styles.statsTitle}>Consideration Stats</Text>
          <Text style={styles.statsText}>
            Total considerations: {user.burritoConsiderations}
          </Text>
        </View>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: spacing.md,
  },
  card: {
    backgroundColor: colors.cardBackground,
    borderRadius: borderRadius.md,
    padding: spacing.lg,
    ...shadows.md,
  },
  title: {
    fontSize: typography.sizes.xl,
    fontWeight: typography.weights.bold,
    color: colors.text,
    marginBottom: spacing.sm,
  },
  text: {
    fontSize: typography.sizes.md,
    color: colors.text,
    marginBottom: spacing.lg,
    lineHeight: 24,
  },
  burritoButton: {
    backgroundColor: colors.burrito,
    borderRadius: borderRadius.sm,
    padding: spacing.lg,
    alignItems: 'center',
    marginVertical: spacing.md,
    ...shadows.sm,
  },
  burritoButtonText: {
    color: colors.white,
    fontSize: typography.sizes.lg,
    fontWeight: typography.weights.bold,
  },
  successContainer: {
    alignItems: 'center',
    marginVertical: spacing.sm,
  },
  success: {
    color: colors.success,
    fontSize: typography.sizes.md,
    fontWeight: typography.weights.medium,
  },
  successCount: {
    color: colors.success,
    fontSize: typography.sizes.lg,
    fontWeight: typography.weights.bold,
    marginTop: spacing.xs,
  },
  stats: {
    backgroundColor: colors.statsBackground,
    padding: spacing.md,
    borderRadius: borderRadius.sm,
    marginTop: spacing.lg,
  },
  statsTitle: {
    fontSize: typography.sizes.lg,
    fontWeight: typography.weights.semibold,
    color: colors.text,
    marginBottom: spacing.xs,
  },
  statsText: {
    fontSize: typography.sizes.md,
    color: colors.text,
  },
})

```

---

## src/screens/HomeScreen.tsx

```tsx
import React, { useState } from 'react'
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native'
import { useNavigation } from '@react-navigation/native'
import { NativeStackNavigationProp } from '@react-navigation/native-stack'
import { useAuth } from '../contexts/AuthContext'
import { RootStackParamList } from '../navigation/RootNavigator'
import {
  colors,
  spacing,
  typography,
  borderRadius,
  shadows,
} from '../styles/theme'

type HomeScreenNavigationProp = NativeStackNavigationProp<
  RootStackParamList,
  'Home'
>

export default function HomeScreen() {
  const { user, login, logout } = useAuth()
  const navigation = useNavigation<HomeScreenNavigationProp>()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async () => {
    setError('')

    if (!username.trim() || !password.trim()) {
      setError('Please provide both username and password')
      return
    }

    setIsSubmitting(true)
    try {
      const success = await login(username, password)
      if (success) {
        setUsername('')
        setPassword('')
      } else {
        setError('An error occurred during login')
      }
    } catch {
      setError('An error occurred during login')
    } finally {
      setIsSubmitting(false)
    }
  }

  // Logged in view
  if (user) {
    return (
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
      >
        <View style={styles.card}>
          <Text style={styles.title}>Welcome back, {user.username}!</Text>
          <Text style={styles.text}>
            You are now logged in. Feel free to explore:
          </Text>

          <View style={styles.buttonGroup}>
            <TouchableOpacity
              style={[styles.button, styles.burritoButton]}
              onPress={() => navigation.navigate('Burrito')}
              activeOpacity={0.8}
            >
              <Text style={styles.buttonText}>Consider Burritos</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.primaryButton]}
              onPress={() => navigation.navigate('Profile')}
              activeOpacity={0.8}
            >
              <Text style={styles.buttonText}>View Profile</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.button, styles.logoutButton]}
              onPress={logout}
              activeOpacity={0.8}
            >
              <Text style={styles.buttonText}>Logout</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    )
  }

  // Login view
  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.card}>
          <Text style={styles.title}>Welcome to Burrito Consideration App</Text>
          <Text style={styles.text}>
            Please sign in to begin your burrito journey
          </Text>

          <View style={styles.form}>
            <Text style={styles.label}>Username:</Text>
            <TextInput
              style={styles.input}
              value={username}
              onChangeText={setUsername}
              placeholder="Enter any username"
              placeholderTextColor={colors.textLight}
              autoCapitalize="none"
              autoCorrect={false}
              autoComplete="username"
              editable={!isSubmitting}
            />

            <Text style={styles.label}>Password:</Text>
            <TextInput
              style={styles.input}
              value={password}
              onChangeText={setPassword}
              placeholder="Enter any password"
              placeholderTextColor={colors.textLight}
              secureTextEntry
              autoComplete="password"
              editable={!isSubmitting}
            />

            {error ? <Text style={styles.error}>{error}</Text> : null}

            <TouchableOpacity
              style={[
                styles.button,
                styles.primaryButton,
                isSubmitting && styles.buttonDisabled,
              ]}
              onPress={handleSubmit}
              disabled={isSubmitting}
              activeOpacity={0.8}
            >
              <Text style={styles.buttonText}>
                {isSubmitting ? 'Signing In...' : 'Sign In'}
              </Text>
            </TouchableOpacity>
          </View>

          <Text style={styles.note}>
            Note: This is a demo app. Use any username and password to sign in.
          </Text>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollView: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing.md,
    justifyContent: 'center',
  },
  card: {
    backgroundColor: colors.cardBackground,
    borderRadius: borderRadius.md,
    padding: spacing.lg,
    ...shadows.md,
  },
  title: {
    fontSize: typography.sizes.xl,
    fontWeight: typography.weights.bold,
    color: colors.text,
    marginBottom: spacing.sm,
  },
  text: {
    fontSize: typography.sizes.md,
    color: colors.text,
    marginBottom: spacing.md,
    lineHeight: 24,
  },
  form: {
    marginTop: spacing.md,
  },
  label: {
    fontSize: typography.sizes.md,
    fontWeight: typography.weights.medium,
    color: colors.text,
    marginBottom: spacing.xs,
  },
  input: {
    backgroundColor: colors.inputBackground,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: borderRadius.sm,
    padding: spacing.sm,
    fontSize: typography.sizes.md,
    color: colors.text,
    marginBottom: spacing.md,
  },
  buttonGroup: {
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  button: {
    borderRadius: borderRadius.sm,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  primaryButton: {
    backgroundColor: colors.primary,
  },
  burritoButton: {
    backgroundColor: colors.burrito,
  },
  logoutButton: {
    backgroundColor: colors.danger,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.sizes.md,
    fontWeight: typography.weights.semibold,
  },
  error: {
    color: colors.danger,
    marginBottom: spacing.sm,
    fontSize: typography.sizes.sm,
  },
  note: {
    marginTop: spacing.lg,
    color: colors.textSecondary,
    fontSize: typography.sizes.sm,
    textAlign: 'center',
    lineHeight: 20,
  },
})

```

---

## src/screens/ProfileScreen.tsx

```tsx
import React, { useEffect } from 'react'
import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native'
import { useNavigation } from '@react-navigation/native'
import { NativeStackNavigationProp } from '@react-navigation/native-stack'
import { usePostHog } from 'posthog-react-native'
import { useAuth } from '../contexts/AuthContext'
import { RootStackParamList } from '../navigation/RootNavigator'
import {
  colors,
  spacing,
  typography,
  borderRadius,
  shadows,
} from '../styles/theme'

type ProfileScreenNavigationProp = NativeStackNavigationProp<
  RootStackParamList,
  'Profile'
>

/**
 * Profile Screen
 *
 * Displays user information and demonstrates PostHog error tracking.
 * The test error button shows how to capture exceptions manually.
 *
 * @see https://posthog.com/docs/libraries/react-native#error-tracking
 */
export default function ProfileScreen() {
  const { user } = useAuth()
  const navigation = useNavigation<ProfileScreenNavigationProp>()
  const posthog = usePostHog()

  // Redirect to home if not logged in
  useEffect(() => {
    if (!user) {
      navigation.navigate('Home')
    }
  }, [user, navigation])

  if (!user) {
    return null
  }

  /**
   * Triggers a test error and captures it in PostHog
   *
   * This demonstrates manual exception capture using the $exception event.
   * In production, you would typically set up automatic exception capture
   * or use the before_send callback for customization.
   *
   * @see https://posthog.com/docs/libraries/react-native#error-tracking
   */
  const triggerTestError = () => {
    try {
      throw new Error('Test error for PostHog error tracking')
    } catch (err) {
      const error = err as Error

      // Capture exception in PostHog using the $exception event
      // This follows PostHog's error tracking format
      posthog.capture('$exception', {
        $exception_type: error.name,
        $exception_message: error.message,
        $exception_source: 'ProfileScreen.triggerTestError',
        $exception_stack_trace_raw: error.stack,
        // Additional context
        username: user.username,
        screen: 'Profile',
      })

      console.error('Captured error:', error)
      Alert.alert(
        'Error Captured',
        'The test error has been sent to PostHog!',
        [{ text: 'OK' }],
      )
    }
  }

  const getJourneyMessage = () => {
    const count = user.burritoConsiderations
    if (count === 0) {
      return "You haven't considered any burritos yet. Visit the Burrito Consideration page to start!"
    } else if (count === 1) {
      return "You've considered the burrito potential once. Keep going!"
    } else if (count < 5) {
      return "You're getting the hang of burrito consideration!"
    } else if (count < 10) {
      return "You're becoming a burrito consideration expert!"
    } else {
      return 'You are a true burrito consideration master!'
    }
  }

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <Text style={styles.title}>User Profile</Text>

        <View style={styles.stats}>
          <Text style={styles.statsTitle}>Your Information</Text>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Username:</Text>
            <Text style={styles.infoValue}>{user.username}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Burrito Considerations:</Text>
            <Text style={styles.infoValue}>{user.burritoConsiderations}</Text>
          </View>
        </View>

        {/*
          testID is captured by PostHog autocapture for touch events
          @see https://posthog.com/docs/libraries/react-native#autocapture
        */}
        <TouchableOpacity
          style={styles.errorButton}
          onPress={triggerTestError}
          activeOpacity={0.8}
          testID="trigger-error-button"
        >
          <Text style={styles.buttonText}>Trigger Test Error (for PostHog)</Text>
        </TouchableOpacity>

        <View style={styles.journey}>
          <Text style={styles.journeyTitle}>Your Burrito Journey</Text>
          <Text style={styles.journeyText}>{getJourneyMessage()}</Text>
        </View>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: spacing.md,
  },
  card: {
    backgroundColor: colors.cardBackground,
    borderRadius: borderRadius.md,
    padding: spacing.lg,
    ...shadows.md,
  },
  title: {
    fontSize: typography.sizes.xl,
    fontWeight: typography.weights.bold,
    color: colors.text,
    marginBottom: spacing.md,
  },
  stats: {
    backgroundColor: colors.statsBackground,
    padding: spacing.md,
    borderRadius: borderRadius.sm,
  },
  statsTitle: {
    fontSize: typography.sizes.lg,
    fontWeight: typography.weights.semibold,
    color: colors.text,
    marginBottom: spacing.sm,
  },
  infoRow: {
    flexDirection: 'row',
    marginBottom: spacing.xs,
  },
  infoLabel: {
    fontSize: typography.sizes.md,
    fontWeight: typography.weights.bold,
    color: colors.text,
    marginRight: spacing.xs,
  },
  infoValue: {
    fontSize: typography.sizes.md,
    color: colors.text,
  },
  errorButton: {
    backgroundColor: colors.danger,
    borderRadius: borderRadius.sm,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.sizes.md,
    fontWeight: typography.weights.semibold,
  },
  journey: {
    marginTop: spacing.lg,
  },
  journeyTitle: {
    fontSize: typography.sizes.lg,
    fontWeight: typography.weights.semibold,
    color: colors.text,
    marginBottom: spacing.sm,
  },
  journeyText: {
    fontSize: typography.sizes.md,
    color: colors.text,
    lineHeight: 24,
  },
})

```

---

## src/services/storage.ts

```ts
import AsyncStorage from '@react-native-async-storage/async-storage'

const CURRENT_USER_KEY = 'currentUser'
const USERS_KEY = 'users'

export interface User {
  username: string
  burritoConsiderations: number
}

/**
 * Storage service for persisting user data
 * Uses AsyncStorage (React Native's async key-value storage)
 */
export const storage = {
  /**
   * Get the currently logged in user's username
   */
  getCurrentUser: async (): Promise<string | null> => {
    try {
      return await AsyncStorage.getItem(CURRENT_USER_KEY)
    } catch (error) {
      console.error('Error getting current user:', error)
      return null
    }
  },

  /**
   * Set the currently logged in user's username
   */
  setCurrentUser: async (username: string): Promise<void> => {
    try {
      await AsyncStorage.setItem(CURRENT_USER_KEY, username)
    } catch (error) {
      console.error('Error setting current user:', error)
    }
  },

  /**
   * Remove the current user (logout)
   */
  removeCurrentUser: async (): Promise<void> => {
    try {
      await AsyncStorage.removeItem(CURRENT_USER_KEY)
    } catch (error) {
      console.error('Error removing current user:', error)
    }
  },

  /**
   * Get all stored users
   */
  getUsers: async (): Promise<Record<string, User>> => {
    try {
      const data = await AsyncStorage.getItem(USERS_KEY)
      return data ? JSON.parse(data) : {}
    } catch (error) {
      console.error('Error getting users:', error)
      return {}
    }
  },

  /**
   * Get a specific user by username
   */
  getUser: async (username: string): Promise<User | null> => {
    try {
      const users = await storage.getUsers()
      return users[username] || null
    } catch (error) {
      console.error('Error getting user:', error)
      return null
    }
  },

  /**
   * Save a user to storage
   */
  saveUser: async (user: User): Promise<void> => {
    try {
      const users = await storage.getUsers()
      users[user.username] = user
      await AsyncStorage.setItem(USERS_KEY, JSON.stringify(users))
    } catch (error) {
      console.error('Error saving user:', error)
    }
  },

  /**
   * Clear all stored data (for testing/debugging)
   */
  clearAll: async (): Promise<void> => {
    try {
      await AsyncStorage.multiRemove([CURRENT_USER_KEY, USERS_KEY])
    } catch (error) {
      console.error('Error clearing storage:', error)
    }
  },
}

```

---

## src/styles/theme.ts

```ts
/**
 * Theme constants for consistent styling across the app
 * Matches the color scheme from the TanStack Start web version
 */

export const colors = {
  // Primary colors
  primary: '#0070f3',
  primaryDark: '#0051cc',

  // Status colors
  success: '#28a745',
  successDark: '#218838',
  danger: '#dc3545',
  dangerDark: '#c82333',

  // Feature colors
  burrito: '#e07c24',
  burritoDark: '#c96a1a',

  // Neutral colors
  background: '#f5f5f5',
  white: '#ffffff',
  text: '#333333',
  textSecondary: '#666666',
  textLight: '#999999',
  border: '#dddddd',
  borderLight: '#eeeeee',

  // Component-specific
  statsBackground: '#f8f9fa',
  headerBackground: '#333333',
  headerText: '#ffffff',
  inputBackground: '#ffffff',
  cardBackground: '#ffffff',
}

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
}

export const typography = {
  sizes: {
    xs: 12,
    sm: 14,
    md: 16,
    lg: 18,
    xl: 24,
    xxl: 32,
  },
  weights: {
    normal: '400' as const,
    medium: '500' as const,
    semibold: '600' as const,
    bold: '700' as const,
  },
}

export const borderRadius = {
  sm: 4,
  md: 8,
  lg: 12,
  full: 9999,
}

export const shadows = {
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  lg: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 5,
  },
}

```

---

## src/types/env.d.ts

```ts
declare module 'react-native-config' {
  export interface NativeConfig {
    POSTHOG_PROJECT_TOKEN?: string
    POSTHOG_HOST?: string
  }

  export const Config: NativeConfig
  export default Config
}

```

---

