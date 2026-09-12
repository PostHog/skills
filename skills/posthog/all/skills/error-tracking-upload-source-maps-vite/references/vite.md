> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload source maps for Vite - Docs

Copy page

# Upload source maps for Vite - Docs

## AI wizard

Set up source map uploading automatically with our wizard by running this command in your project directory with your terminal (it also works for [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt):

`npx @posthog/wizard upload-source-maps`

[Learn more](/wizard.md)

## Manual setup

1.  1

    ## Install the PostHog Rollup plugin

    Required

    Vite uses Rollup under the hood, so you can use the PostHog Rollup plugin to upload source maps:

    Terminal

    PostHog AI

    ```shell
    npm install @posthog/rollup-plugin
    ```

2.  2

    ## Add PostHog plugin to your Vite config

    Required

    Add the PostHog plugin to your `vite.config.js` file:

    vite.config.js

    PostHog AI

    ```javascript
    import { defineConfig } from 'vite'
    import posthog from '@posthog/rollup-plugin'
    export default defineConfig({
      plugins: [
        posthog({
          personalApiKey: process.env.POSTHOG_API_KEY!, // Personal API Key
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
    })
    ```

    Set the following environment variables:

    | Environment variable | Description |
    | --- | --- |
    | POSTHOG_API_KEY | [Personal API key](https://app.posthog.com/settings/user-api-keys#variables) with at least write access on error tracking |
    | POSTHOG_PROJECT_ID | Project ID you can find in your [project settings](https://app.posthog.com/settings/project#variables) |
    | POSTHOG_HOST | (optional) Your PostHog instance URL. Defaults to https://us.i.posthog.com |

    **Using CI/CD?**

    Add these environment variables to your CI/CD service's project settings to automatically upload source maps during production builds.

3.  ## Verify source map upload and injection

    Checkpoint

    Confirm source maps were successfully uploaded:

    1.  Go to your [symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets) and verify your latest upload appears.

    2.  Check your production JavaScript files in browser dev tools. They should include a source map reference comment:

    JavaScript

    PostHog AI

    ```javascript
    //# chunkId=0197e6db-9a73-7b91-9e80-4e1b7158db5c
    ```

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better