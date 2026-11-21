> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Upload debug symbols for Rust - Docs

Copy page

# Upload debug symbols for Rust - Docs

The [Rust SDK](/docs/error-tracking/installation/rust.md) resolves stack traces in-process from whatever debug info the running binary carries — which works well in development, but release builds omit that debug info by default. Uploading debug symbols gives you fully resolved production stack traces: PostHog symbolicates frames server-side from the exact build that crashed, resolves inlined frames, and can display the source code around each frame.

**Version requirements**

-   [posthog-rs 0.16.0](https://github.com/PostHog/posthog-rs/releases) or later, which records the instruction addresses server-side symbolication needs. We recommend the latest version.
-   [CLI 0.7.32](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.7.32) or later for Linux binaries. Uploading macOS `.dSYM` bundles with the same command needs [CLI 0.8.1](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.8.1) or later, and uploading standalone Mach-O executables (including universal binaries) needs [CLI 0.9.1](https://github.com/PostHog/posthog/releases/tag/posthog-cli%2Fv0.9.1) or later. As always, we recommend [keeping up with the latest CLI version](/docs/error-tracking/upload-source-maps/cli.md).

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

    ## Keep debug info in release builds

    Required

    Cargo omits debug info from release builds by default, and there is nothing to upload without it. Enable it in your `Cargo.toml`:

    toml

    PostHog AI

    ```toml
    [profile.release]
    debug = "line-tables-only"
    ```

    `line-tables-only` is enough to resolve file names, line numbers, and inlined frames while keeping binaries small. Use `debug = "full"` if you want complete debug info.

    On macOS, also set `split-debuginfo = "packed"` in the same profile. Cargo's macOS default (`unpacked`) leaves debug info in intermediate object files instead of producing the `.dSYM` bundle the CLI uploads.

    Watch out for stripping: if your profile sets `strip` explicitly, set it to `"none"` — or strip only after the upload runs. Debug info split into separate files also works: the CLI picks up `objcopy --only-keep-debug` companion files alongside the binaries.

4.  4

    ## Check for a build ID

    Required

    PostHog matches stack frames to uploaded symbols by the binary's unique build ID: a GNU build ID on Linux, or the Mach-O UUID on macOS. macOS binaries always carry a UUID, so there is nothing to check there. Most Linux toolchains emit a GNU build ID by default — confirm yours does:

    Terminal

    PostHog AI

    ```bash
    readelf -n target/release/my-app | grep "Build ID"
    ```

    Replace `my-app` with your binary's name.

    If nothing shows up, tell the linker to add one in `.cargo/config.toml`, scoped to Linux builds (Apple's linker embeds a UUID on its own and rejects this flag):

    toml

    PostHog AI

    ```toml
    [target.'cfg(target_os = "linux")']
    rustflags = ["-C", "link-arg=-Wl,--build-id=sha1"]
    ```

5.  5

    ## Build and upload

    Required

    After your release build, point the CLI at the build output directory:

    Terminal

    PostHog AI

    ```bash
    cargo build --release
    posthog-cli symbol-sets upload --directory target/release
    ```

    The CLI scans the directory and uploads every executable and shared library that carries debug info and a build ID, skipping everything else. On macOS it also uploads `.dSYM` bundles (this needs `dwarfdump`, which ships with Xcode) and standalone Mach-O binaries that embed their own DWARF, splitting universal (fat) binaries into one symbol set per architecture slice. Windows binaries (PDB debug info) are not supported yet. The upload is associated with a [release](/docs/error-tracking/releases.md) automatically when the build directory is inside a git checkout.

    Run this as part of the same pipeline that produces your production binary. Each build has its own build ID, so symbols must be re-uploaded for every build you deploy.

6.  6

    ## Optional: Include source code context

    Optional

    By default, only debug symbols are uploaded. To also display the source code around each frame in your stack traces, add `--include-source`:

    Terminal

    PostHog AI

    ```bash
    posthog-cli symbol-sets upload --directory target/release --include-source
    ```

    This bundles the project source files referenced by the debug info into the upload. It increases upload size, so only enable it if you want source context in the error tracking UI.

7.  7

    ## Optional: Upload from CI

    Optional

    In CI, authenticate with environment variables instead of `posthog-cli login`. For GitHub Actions:

    YAML

    PostHog AI

    ```yaml
    - name: Build release binary
      run: cargo build --release
    - name: Upload debug symbols
      run: posthog-cli symbol-sets upload --directory target/release
      env:
        POSTHOG_CLI_API_KEY: ${{ secrets.POSTHOG_CLI_API_KEY }}
        POSTHOG_CLI_PROJECT_ID: ${{ secrets.POSTHOG_CLI_PROJECT_ID }}
    ```

    Scope the credentials to the upload step only — the build itself doesn't need them.

    The CLI defaults to US Cloud. If you are on EU Cloud or self-hosted, also set `POSTHOG_CLI_HOST` (for example `https://eu.posthog.com`).

    If your binary is built inside a Dockerfile, run the upload in the build stage right after the build, and pass the credentials in as build secrets so they never reach the runtime image.

9.  ## Verify debug symbols upload

    Checkpoint

    Confirm that debug symbols are successfully uploaded to PostHog.[Check symbol sets in PostHog](https://app.posthog.com/error_tracking/configuration#selectedSetting=error-tracking-symbol-sets)

11.  9

     ## Test it end-to-end

     Optional

     Capture a test exception from the same release binary the symbols were uploaded for:

     Rust

     PostHog AI

     ```rust
     let error = std::io::Error::new(std::io::ErrorKind::Other, "This is a test exception from Rust");
     client.capture_exception(&error).await.unwrap();
     ```

     Run the binary, then check the [error tracking issues view](https://app.posthog.com/error_tracking): the stack trace should resolve to your source files, including source context if you uploaded with `--include-source`. A rebuild changes the build ID, so if you rebuild, upload again before testing.

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better