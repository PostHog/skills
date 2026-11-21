> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload dSYMs for iOS - Docs

Copy page

# Upload dSYMs for iOS - Docs

**CLI version requirement**

A minimum CLI version of [0.7.7](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.7.7) is required, but we recommend [keeping up with the latest CLI version](/docs/error-tracking/upload-source-maps/cli.md) to ensure you have all of Error Tracking's features.

1.  1

    ## Download CLI

    Required

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

    ## Configure build settings

    Required

    In Xcode, configure your build settings to generate dSYMs:

    1.  Open your project in Xcode
    2.  Select your target
    3.  Go to **Build Settings**
    4.  Search for **Debug Information Format**
    5.  Make sure Release configurations have **DWARF with dSYM File**

    ![Xcode dSYM setting](https://res.cloudinary.com/dmukukwp6/image/upload/q_auto,f_auto/DWARF_and_d_SYM_xcode_settings_light_f6a8bb74c3.png)![Xcode dSYM setting](https://res.cloudinary.com/dmukukwp6/image/upload/q_auto,f_auto/DWARF_and_d_SYM_xcode_settings_7b2c628b52.png)

    **Disable User Script Sandboxing**

    You must disable User Script Sandboxing for the upload script to work:

    1.  In Build Settings, search for **User Script Sandboxing**(`ENABLE_USER_SCRIPT_SANDBOXING`)
    2.  Set `ENABLE_USER_SCRIPT_SANDBOXING` to **No**

    **Why is this required?**

    When User Script Sandboxing is enabled, Xcode only allows run scripts to access files explicitly specified in the build phase's **Input Files**. The dSYM upload script needs to walk directories to locate and read dSYM bundles, and execute `posthog-cli` which are currently not allowed with User Script Sandboxing enabled.

4.  4

    ## Add build phase script

    Required

    To symbolicate crash reports, PostHog needs your project's debug symbol (dSYM) files. The following script automatically processes and uploads dSYMs whenever you build your app.

    Add a **Run Script** build phase:

    1.  In Xcode, select your main app target
    2.  Go to **Build Phases** tab
    3.  Click the **+** button and select **New Run Script Phase**
    4.  Make sure it's set to run last (after "Copy Bundle Resources" or similar)
    5.  Add the appropriate script for your package manager:

    PostHog AI

    ### Swift

    ```bash
    ${BUILD_DIR%/Build/*}/SourcePackages/checkouts/posthog-ios/build-tools/upload-symbols.sh
    ```

    ### CocoaPods

    ```bash
    ${PODS_ROOT}/PostHog/build-tools/upload-symbols.sh
    ```

    6.  In the **Input Files** section of the Run Script phase, add:

    PostHog AI

    ```
    $(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Resources/DWARF/$(EXECUTABLE_NAME)
    ```

    This makes Xcode wait for the app's dSYM contents before running the upload script.

5.  5

    ## Optional: Include source code context

    Optional

    By default, only debug symbols are uploaded. To include source code snippets in your stack traces (for better debugging context), set the `POSTHOG_INCLUDE_SOURCE` environment variable:

    1.  In the Run Script build phase, click the chevron to expand
    2.  Set the **environment Variable** when calling the upload script:

    PostHog AI

    ### Swift

    ```bash
    POSTHOG_INCLUDE_SOURCE=1 ${BUILD_DIR%/Build/*}/SourcePackages/checkouts/posthog-ios/build-tools/upload-symbols.sh
    ```

    ### CocoaPods

    ```bash
    POSTHOG_INCLUDE_SOURCE=1 ${PODS_ROOT}/PostHog/build-tools/upload-symbols.sh
    ```

    **Note**: This increases upload size and build times. Only enable if you need source code context in PostHog's error tracking UI.

6.  6

    ## Optional: Skip conflicting uploads

    Optional

    If PostHog already has a dSYM with the same UUID but different content, the upload fails with `content_hash_mismatch` and stops your build. To skip these conflicting uploads and keep the existing symbols instead, set the `POSTHOG_SKIP_ON_CONFLICT` environment variable when calling the upload script:

    PostHog AI

    ### Swift

    ```bash
    POSTHOG_SKIP_ON_CONFLICT=1 ${BUILD_DIR%/Build/*}/SourcePackages/checkouts/posthog-ios/build-tools/upload-symbols.sh
    ```

    ### CocoaPods

    ```bash
    POSTHOG_SKIP_ON_CONFLICT=1 ${PODS_ROOT}/PostHog/build-tools/upload-symbols.sh
    ```

    Requires posthog-ios 3.64.7 or later and posthog-cli 0.7.12 or later.

7.  7

    ## Build and verify

    Required

    Build your app in Xcode. The dSYM upload script will automatically run and upload symbols to PostHog.

    Check the build log output for confirmation.

8.  8

    ## Force a test crash

    Optional

    To verify everything is working end-to-end, force a test crash and confirm it appears in PostHog.

    1.  Add a crash trigger button to your app:

    PostHog AI

    ### SwiftUI

    ```swift
    Button("Test Crash") {
        fatalError("PostHog test crash")
    }
    ```

    ### UIKit

    ```swift
    let button = UIButton(type: .system)
    button.setTitle("Test Crash", for: .normal)
    button.addTarget(self, action: #selector(testCrash), for: .touchUpInside)
    view.addSubview(button)
    @objc func testCrash() {
        fatalError("PostHog test crash")
    }
    ```

    2.  Build and run your app in Xcode,

        -   Make sure the debugger is not attached, since it will intercept the crash and prevent the report from being collected. You can:
            -   Detach the debugger (click the stop button in Xcode) and run the app directly from the device/simulator home screen
            -   Or uncheck "Debug executable" in the scheme settings before running
    3.  Reopen the app from your device or simulator's home screen (not from Xcode).

    4.  Tap the **Test Crash** button. The app will crash. The exception is collected but **not yet sent** to PostHog.

    5.  Reopen the app once more. This triggers the SDK to send the previously collected crash report to PostHog.

    6.  Check the [error tracking dashboard](https://app.posthog.com/error_tracking) for your test crash.

    Remove the crash trigger button before shipping to production.

10.  ## Verify dSYMs upload

     Checkpoint

     Confirm that dSYMs are successfully uploaded to PostHog.[Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

## Troubleshooting

### Script fails with "error: posthog-cli not found"

Install the CLI using one of these methods:

Terminal

PostHog AI

```bash
# NPM global install
npm install -g @posthog/cli
# Or download binary
curl --proto '=https' --tlsv1.2 -LsSf https://download.posthog.com/cli | sh
```

### Script fails with permission errors

Ensure `ENABLE_USER_SCRIPT_SANDBOXING` is set to `NO` in your build settings.

### dSYMs not being generated

Verify that `DEBUG_INFORMATION_FORMAT` is set to **DWARF with dSYM File** for the configuration you're building (Debug or Release).

### Script fails with "content\_hash\_mismatch"

This happens when the upload script runs before Xcode finishes generating the dSYM files. Leave **Based on dependency analysis** enabled and add `$(DWARF_DSYM_FOLDER_PATH)/$(DWARF_DSYM_FILE_NAME)/Contents/Resources/DWARF/$(EXECUTABLE_NAME)` to the **Input Files** of the Run Script build phase. This makes Xcode wait for the app's dSYM contents before running the upload script.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better