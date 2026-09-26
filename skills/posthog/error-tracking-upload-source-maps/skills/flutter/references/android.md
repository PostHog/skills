> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload mappings for Android - Docs

Copy page

# Upload mappings for Android - Docs

1.  1

    ## Download CLI

    Required

    > [CLI v0.7.4](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.7.4) or later

    Install `posthog-cli`:

    PostHog AI

    ### Npm

    ```bash
    npm install -g @posthog/cli
    ```

    ### Curl

    ```bash
    curl --proto '=https' --tlsv1.2 -LsSf https://download.posthog.com/cli | sh
    posthog-cli-update
    ```

2.  2

    ## Authenticate

    Required

    To authenticate the CLI, call the `login` command. This opens your browser where you select your organization, project, and API scopes to grant:

    Terminal

    PostHog AI

    ```bash
    posthog-cli login
    ```

    If you are using the CLI in a CI/CD environment such as GitHub Actions, you can set environment variables to authenticate:

    | Environment Variable | Description | Source |
    | --- | --- | --- |
    | POSTHOG_CLI_HOST | The PostHog host to connect to [default: https://us.posthog.com] | [Project settings](https://app.posthog.com/settings/project#variables) |
    | POSTHOG_CLI_PROJECT_ID | PostHog project ID | [Project settings](https://app.posthog.com/settings/project#variables) |
    | POSTHOG_CLI_API_KEY | Personal API key with error tracking write and organization read scopes | [API key settings](https://app.posthog.com/settings/user-api-keys#variables) |

    You can also use the `--host` option instead of the `POSTHOG_CLI_HOST` environment variable to target a different PostHog instance or region. For EU users:

    Terminal

    PostHog AI

    ```bash
    posthog-cli --host https://eu.posthog.com [CMD]
    ```

3.  3

    ## Inject and upload

    Required

    > [AGP v8](https://developer.android.com/build/releases/gradle-plugin) or later

    Automatic mappings uploading is handled through the Gradle build process on Android.

    Install the [PostHog Android Gradle Plugin](https://github.com/PostHog/posthog-android/blob/main/posthog-android-gradle-plugin/CHANGELOG.md) on your app's `build.gradle.kts` file.

    Kotlin

    PostHog AI

    ```kotlin
    // Available through mavenCentral()
    plugins {
        id("com.android.application")
        id("com.posthog.android") version "$version"
        ...
    }
    ```

    If you are running this in CI/CD, you can configure the CLI directly on the Gradle task instead of relying on `POSTHOG_CLI_HOST`, `POSTHOG_CLI_PROJECT_ID`, and `POSTHOG_CLI_API_KEY` environment variables:

    Kotlin

    PostHog AI

    ```kotlin
    import com.posthog.android.PostHogCliExecTask
    tasks.withType<PostHogCliExecTask> {
        postHogHost = "https://eu.posthog.com"
        postHogProjectId = "my-project-id"
        postHogApiKey = "my-personal-api-key"
    }
    ```

    You can also set `postHogExecutable` if you want to use a custom `posthog-cli` path.

4.  4

    ## Upload native debug symbols (NDK)

    Optional

    > Requires [PostHog Android SDK 3.60.0](https://github.com/PostHog/posthog-android/releases/tag/android-v3.60.0) or later with `errorTrackingConfig.captureNativeCrashes` enabled, [Gradle plugin 1.5.0](https://github.com/PostHog/posthog-android/releases/tag/androidPlugin-v1.5.0) or later, and [CLI 0.7.32](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.7.32) or later.

    If your app includes native C or C++ code built with the NDK, upload the `.so` debug symbols so native crash stack traces resolve to function names, files, and line numbers.

    Enable the upload in your app's `build.gradle.kts`:

    Kotlin

    PostHog AI

    ```kotlin
    posthog {
        uploadNativeSymbols.set(true)
    }
    ```

    When enabled, the Gradle plugin's `uploadPostHogNativeSymbols<Variant>` task reads the variant's unstripped native libraries and uploads every one carrying debug info and a build ID, automatically after `assemble`, `install`, or `bundle`. This covers native code you build with the NDK as well as `.so` files bundled from `jniLibs` or dependencies, for minified and non-minified builds alike. Debuggable variants are skipped, so day-to-day debug builds don't upload symbols.

    To include source context around resolved crash frames, also bundle the project sources referenced by the debug info:

    Kotlin

    PostHog AI

    ```kotlin
    posthog {
        uploadNativeSymbols.set(true)
        includeNativeSymbolSources.set(true)
    }
    ```

    You can also run the upload task explicitly, for any variant, without enabling the automatic upload:

    Terminal

    PostHog AI

    ```bash
    ./gradlew uploadPostHogNativeSymbolsRelease
    ```

    You can also upload a directory of `.so` files directly, without the Gradle plugin:

    Terminal

    PostHog AI

    ```bash
    posthog-cli symbol-sets upload --directory app/build/intermediates/merged_native_libs/release
    ```

    PostHog matches crash frames to uploaded symbols by each library's GNU build ID, which the NDK emits by default. Each build has its own build ID, so symbols must be re-uploaded for every build you ship.

    Native crash events are captured on the next app launch, so event properties like `$app_version` reflect the app at capture time, not at crash time. If the app updated in between, check the crash's release (matched by build ID) rather than the event's version properties when investigating.

6.  ## Verify mappings upload

    Checkpoint

    Confirm that mappings are successfully uploaded to PostHog.[Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better