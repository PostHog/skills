> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload source maps for Angular - Docs

Copy page

# Upload source maps for Angular - Docs

## AI wizard

Set up source map uploading automatically with our wizard by running this command in your project directory with your terminal (it also works for [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt):

`npx @posthog/wizard upload-source-maps`

[Learn more](/wizard.md)

## Manual setup

1.  1

    ## Install the PostHog CLI

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

    ## Authenticate the PostHog CLI

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

    ## Output source maps for Angular

    Required

    You can configure Angular to [generate source maps](https://angular.dev/reference/configs/workspace-config#source-map-configuration) by adding the following to your `angular.json` file:

    angular.json

    PostHog AI

    ```json
    "build": {
              "builder": "@angular-devkit/build-angular:application",
              "options": {
                "sourceMap": {
                  "scripts": true,
                  "styles": true,
                  "hidden": true,
                  "vendor": true
                }
              }
            }
    ```

    Then, build your Angular application:

    Terminal

    PostHog AI

    ```bash
    ng build --configuration production
    ```

4.  ## Verify source map generation

    Checkpoint

    *Confirm source maps are generated*

    Confirm that the source maps are generated in the `dist/<your-app-name>/` directory. You should see a `.js.map` file for each JS bundle.

5.  4

    ## Inject source map

    Required

    *Your goal in this step: Add metadata to associate maps with your code.*

    Once you've built your application and have bundled assets, inject the context required by PostHog to associate the maps with the served code.

    Terminal

    PostHog AI

    ```bash
    # Inject release and chunk metadata into sourcemaps
    posthog-cli sourcemap inject --directory ./path/to/assets
    ```

6.  ## Verify source map injection

    Checkpoint

    *Confirm source map comments are present*

    Confirm that the served files are injected with the correct source map comment in production in dev tools:

    You should see a comment like this in your minified JS files, for example `main-IX6K2QJM.js`:

    JavaScript

    PostHog AI

    ```javascript
    //# chunkId=0197e6db-9a73-7b91-9e80-4e1b7158db5c
    ```

7.  5

    ## Upload source map

    Required

    *Your goal in this step: Send the processed source maps to PostHog.*

    You will then need to upload the modified assets to PostHog.

    Terminal

    PostHog AI

    ```bash
    # Upload injected sourcemaps to their release
    posthog-cli sourcemap upload --directory ./path/to/assets --release-name my-app --release-version 1.2.3 --build 42
    ```

    The CLI will create or reuse the [release](/docs/error-tracking/releases.md) for the detected or supplied release name and version. The CLI will try to detect release name and version information, but you can set them explicitly with `--release-name` and `--release-version`. We recommend setting the release name, and letting the CLI detect the version, if your project is continuously deployed (the version will be the git commit hash at build time).

    You can also pass `--build` to record a build number (e.g. `CFBundleVersion` on iOS, `versionCode` on Android) as release metadata. This is optional — when omitted, no build info is recorded.

    > **💡 Tip:** You can use `--delete-after` option to clean up sourcemaps after uploading them.

    #### Serve injected assets

    You *must* serve the injected assets in deployed production app. The injected metadata is used during error capture to identify the correct source map to use. We suggest you upload source maps right after your production build in CI.

    If you serve a copy of the bundled assets as they were prior to running `posthog-cli sourcemap inject`, we won't be able to use the uploaded sourcemap to unminify or demangle your stack traces.

8.  ## Verify source map upload

    Checkpoint

    *Confirm source maps are successfully uploaded*

    Before proceeding, confirm that source maps are successfully uploaded to PostHog.

    [Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better