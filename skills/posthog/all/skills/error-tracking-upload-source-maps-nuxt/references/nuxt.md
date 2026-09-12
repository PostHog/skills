> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload source maps for Nuxt - Docs

Copy page

# Upload source maps for Nuxt - Docs

## AI wizard

Set up source map uploading automatically with our wizard by running this command in your project directory with your terminal (it also works for [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt):

`npx @posthog/wizard upload-source-maps`

[Learn more](/wizard.md)

## Nuxt v3.7 and above

For Nuxt v3.7 and above, the `@posthog/nuxt` module automatically handles source map generation and upload during the build process.

No manual configuration is needed – follow the [Nuxt Error Tracking installation guide](/docs/error-tracking/installation/nuxt-3-7.md) to set up the module, and source maps are automatically generated and uploaded when you build your project.

## Nuxt v3.6 and below

For older versions of Nuxt, you'll need to manually configure source map generation and upload using the PostHog CLI.

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

    ## Generate source maps during build

    Required

    You can hook into the `close` event to generate and upload source maps for your Nuxt application like this:

    nuxt.config.js

    PostHog AI

    ```javascript
    import { execSync } from 'child_process'
    export default defineNuxtConfig({
      ...,
      sourcemap: {
        client: true
      },
      hooks: {
        'nitro:build:public-assets': async () => {
          console.log('Running PostHog sourcemap injection and upload...')
          try {
            execSync("posthog-cli sourcemap inject --directory '.output'", {
              stdio: 'inherit',
            })
            execSync("posthog-cli sourcemap upload --directory '.output' --delete-after", {
              stdio: 'inherit',
            })
            console.log('PostHog sourcemap injection completed successfully')
          } catch (error) {
            console.error('PostHog sourcemap injection failed:', error)
          }
        }
      }
    })
    ```

4.  4

    ## Build your project for production

    Required

    Build your project for production by running the following command:

    Terminal

    PostHog AI

    ```bash
    nuxt build
    ```

    Post-build scripts should automatically generate and upload source maps to PostHog.

5.  ## Verify source map upload

    Checkpoint

    *Confirm source maps are being properly uploaded*

    Before proceeding, confirm that source maps are being properly uploaded.

    You can verify the injection is successful by checking your `.mjs` bundle files for `//# chunkId=` comments. The `--delete-after` flag removes the `.map` files after upload so they won't be exposed in your public deployment — PostHog already has them. Make sure to serve the injected JS bundles in production, PostHog will use the `//# chunkId` comments to match them with the uploaded source maps.

    [Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

6.  5

    ## Next steps

    After configuring PostHog, update your build and deployment process to serve bundles **injected** with the `chunkId` comments. PostHog relies on these comments to display the correct stack traces. Remember to export the [required environment variables](#authenticating-the-posthog-cli) in your deployment process.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better