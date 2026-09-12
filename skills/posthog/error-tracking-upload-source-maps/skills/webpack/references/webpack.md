> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload source maps for Webpack - Docs

Copy page

# Upload source maps for Webpack - Docs

## AI wizard

Set up source map uploading automatically with our wizard by running this command in your project directory with your terminal (it also works for [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt):

`npx @posthog/wizard upload-source-maps`

[Learn more](/wizard.md)

## Manual setup

1.  1

    ## Install the PostHog Webpack plugin

    Required

    Terminal

    PostHog AI

    ```shell
    npm install @posthog/webpack-plugin
    ```

2.  2

    ## Add PostHog plugin to your Webpack config

    Required

    Add the following to your `webpack.config.js` file:

    webpack.config.js

    PostHog AI

    ```javascript
    const { PosthogWebpackPlugin } = require('@posthog/webpack-plugin')
    module.exports = {
      // ... your existing config
      plugins: [
        new PosthogWebpackPlugin({
          personalApiKey: process.env.POSTHOG_API_KEY, // Personal API Key
          projectId: process.env.POSTHOG_PROJECT_ID, // Project ID
          host: process.env.POSTHOG_HOST, // (optional) defaults to https://us.i.posthog.com
          sourcemaps: { // (optional)
            enabled: true, // (optional) Enable sourcemaps generation and upload, defaults to true
            releaseName: 'my-application', // (optional) Release name
            releaseVersion: '1.0.0', // (optional) Release version
            deleteAfterUpload: true, // (optional) Delete sourcemaps after upload, defaults to true
          },
        }),
      ],
    }
    ```

    Where you should set the following environment variables:

    | Environment Variable | Description |
    | --- | --- |
    | POSTHOG_API_KEY | [Personal API key](https://app.posthog.com/settings/user-api-keys#variables) with at least write access on error tracking |
    | POSTHOG_PROJECT_ID | Project ID you can find in your [project settings](https://app.posthog.com/settings/project#variables) |
    | POSTHOG_HOST | (optional) Your PostHog instance URL. Defaults to https://us.i.posthog.com |

    If you are using a CI/CD service, make sure these environment variables are added to your project settings, not just your local setup. This enables source maps to be automatically uploaded on your production build.

3.  ## Verify source map upload and injection

    Checkpoint

    1.  Confirm that source maps are successfully uploaded to PostHog.

    [Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

    2.  Confirm that the served files are injected with the correct source map comment in production in dev tools:

    JavaScript

    PostHog AI

    ```javascript
    //# chunkId=0197e6db-9a73-7b91-9e80-4e1b7158db5c
    ```

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better