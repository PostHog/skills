> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload debug symbols for Go - Docs

Copy page

# Upload debug symbols for Go - Docs

The [Go SDK](/docs/error-tracking/installation/go.md) resolves stack traces in-process from the Go runtime, so captured frames already carry file names, line numbers, function names, and inlined calls. What they can't carry is your source code.

That's what uploading debug symbols adds. PostHog resolves the frames again against the exact build that crashed, so the UI can show the lines of code around each frame. It also classifies frames as app or library code from their real source paths, instead of guessing from the function name.

**Version requirements**

-   [posthog-go 1.22.0](https://github.com/PostHog/posthog-go/releases/tag/v1.22.0) or later, which records the instruction addresses and binary identity server-side symbolication needs. We recommend the latest version.
-   [CLI 0.9.1](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.9.1) or later, which uploads macOS Go binaries directly and bundles Go project sources with `--include-source`. Linux binaries without source context work with CLI 0.7.32 or later. As always, we recommend [keeping up with the latest CLI version](/docs/error-tracking/upload-source-maps/cli.md).

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

    ## Build with the right linker flags

    Required

    Go embeds DWARF debug info in every binary by default. What you add on top depends on the platform.

    On Linux, add a GNU build ID. That's the identifier PostHog uses to match stack frames to uploaded symbols, and Go doesn't emit one unless you ask:

    Terminal

    PostHog AI

    ```bash
    go build -ldflags="-B gobuildid" -o my-app .
    ```

    On macOS there's no build ID step, since every Mach-O binary carries a UUID. Instead, turn off DWARF compression. Go compresses debug info by default, and symbolication can't read the compressed form yet:

    Terminal

    PostHog AI

    ```bash
    go build -ldflags="-compressdwarf=false" -o my-app .
    ```

    Two flags to avoid: `-ldflags="-w"` and `-ldflags="-s"` strip the DWARF entirely, and `-trimpath` rewrites the source paths that `--include-source` reads from.

4.  4

    ## Build and upload

    Required

    Point the CLI at the directory containing your built binary:

    Terminal

    PostHog AI

    ```bash
    posthog-cli symbol-sets upload --directory ./bin
    ```

    The CLI scans the directory and uploads every executable that carries debug info and an identity, skipping everything else. On macOS the Go binary uploads directly. Go never produces a `.dSYM` bundle, and it doesn't need one. Universal (fat) binaries upload one symbol set per architecture slice. Windows isn't supported yet, so the SDK falls back to plain runtime-resolved frames there.

    Run this in the same pipeline that produces your production binary. Every build gets its own identity, so you need to re-upload for each build you deploy.

5.  5

    ## Optional: Include source code context

    Optional

    By default, only debug symbols are uploaded. To also display the source code around each frame in your stack traces, add `--include-source`:

    Terminal

    PostHog AI

    ```bash
    posthog-cli symbol-sets upload --directory ./bin --include-source
    ```

    This bundles the project source files referenced by the debug info into the upload. Uploads get bigger, so turn it on only if you want source context in the error tracking UI. It also means building without `-trimpath`, since the CLI reads the sources off disk using the paths recorded at compile time.

6.  6

    ## Optional: Upload from CI

    Optional

    In CI, authenticate with environment variables instead of `posthog-cli login`. For GitHub Actions:

    YAML

    PostHog AI

    ```yaml
    - name: Build release binary
      run: go build -ldflags="-B gobuildid" -o bin/my-app .
    - name: Upload debug symbols
      run: posthog-cli symbol-sets upload --directory ./bin
      env:
        POSTHOG_CLI_API_KEY: ${{ secrets.POSTHOG_CLI_API_KEY }}
        POSTHOG_CLI_PROJECT_ID: ${{ secrets.POSTHOG_CLI_PROJECT_ID }}
    ```

    Scope the credentials to the upload step. The build itself doesn't need them.

    The CLI defaults to US Cloud. If you're on EU Cloud or self-hosted, also set `POSTHOG_CLI_HOST` (for example `https://eu.posthog.com`).

    If your binary is built inside a Dockerfile, run the upload in the build stage right after the build, and pass the credentials in as build secrets so they never reach the runtime image.

8.  ## Verify debug symbols upload

    Checkpoint

    Confirm that debug symbols are successfully uploaded to PostHog.[Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

10.  8

     ## Test it end-to-end

     Optional

     Capture a test exception from the same binary the symbols were uploaded for:

     Go

     PostHog AI

     ```go
     exception := posthog.NewDefaultException(
         time.Now(),
         "test_user",
         "TestError",
         "This is a test exception from Go",
     )
     client.Enqueue(exception)
     client.Close()
     ```

     Run the binary, then open the [error tracking issues view](https://app.posthog.com/error_tracking). The stack trace should resolve against the uploaded symbols, with source context if you used `--include-source`. Rebuilding changes the binary's identity, so upload again before you test.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better