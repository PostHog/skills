> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Rust Error Tracking installation - Docs

Copy page

# Rust Error Tracking installation - Docs

1.  1

    ## Install the Rust SDK

    Required

    Install the [PostHog Rust SDK](/docs/libraries/rust.md):

    Terminal

    PostHog AI

    ```bash
    cargo add posthog-rs
    ```

    Error tracking ships enabled by default through the `error-tracking` feature. If you build with `default-features = false`, add it back explicitly:

    toml

    PostHog AI

    ```toml
    [dependencies]
    posthog-rs = { version = "*", default-features = false, features = ["error-tracking"] }
    ```

    **Debug symbol uploads**

    The Rust SDK resolves stack traces in-process, so when the running binary carries debug info (as development builds do), captured frames include file names, line numbers, and function names without any symbol uploads. For resolved stack traces from release builds — which omit debug info by default — plus inlined frame resolution and source context (the surrounding lines of code in the error tracking UI), [upload debug symbols](/docs/error-tracking/upload-source-maps/rust.md).

2.  2

    ## Initialize the client

    Required

    Rust

    PostHog AI

    ```rust
    let client = posthog_rs::client((
        "<ph_project_token>",
        "https://us.i.posthog.com",
    )).await;
    ```

    The default client is async (Tokio). Building with `default-features = false` gives you a blocking client instead — the same methods without `.await`.

3.  3

    ## Capture exceptions

    Required

    `capture_exception` works with any `std::error::Error` and captures it personlessly — the exception type, message, and full `source()` chain are sent, with a stack trace recorded at the call site:

    Rust

    PostHog AI

    ```rust
    let error = std::io::Error::new(std::io::ErrorKind::Other, "connection refused");
    client.capture_exception(&error).await.unwrap();
    ```

    To associate the exception with a person or attach context, use `capture_exception_with`:

    Rust

    PostHog AI

    ```rust
    use posthog_rs::CaptureExceptionOptions;
    client.capture_exception_with(
        &error,
        CaptureExceptionOptions::new()
            .distinct_id("user_distinct_id")
            .property("route", "/checkout").unwrap()
            .group("company", "company_id")
            .fingerprint("my-custom-fingerprint")
            .level("warning"),
    ).await.unwrap();
    ```

    All options are optional: `distinct_id` links a person, `property` and `group` add context, `fingerprint` overrides [issue grouping](/docs/error-tracking/grouping-issues.md), and `level` sets the severity (defaults to `error`).

    If you use `anyhow`, pass the underlying error with `err.as_ref()`:

    Rust

    PostHog AI

    ```rust
    let result: anyhow::Result<()> = do_work();
    if let Err(err) = result {
        client.capture_exception(err.as_ref()).await.unwrap();
    }
    ```

4.  4

    ## Capture panics

    Optional

    Panic autocapture is opt-in and uses the process-global client. Enable `capture_panics` and initialize the global client with `init_global`; the SDK then installs a process-wide `std::panic` hook:

    Rust

    PostHog AI

    ```rust
    use posthog_rs::{ClientOptionsBuilder, ErrorTrackingOptionsBuilder};
    let options = ClientOptionsBuilder::default()
        .api_key("<ph_project_token>".to_string())
        .host("https://us.i.posthog.com")
        .error_tracking(
            ErrorTrackingOptionsBuilder::default()
                .capture_panics(true)
                .build()
                .unwrap(),
        )
        .build()
        .unwrap();
    // Installs the panic hook and routes panics through the global client.
    posthog_rs::init_global(options).await.unwrap();
    ```

    Each panic is captured as a personless `$exception` carrying the panic message, the panic-site location, and a call-site stack trace (subject to `capture_stacktrace`). The previously installed hook still runs afterwards.

    Because a panic hook is process-global, panic autocapture pairs with the global client — there is no per-`Client` panic API. Capture routes through the SDK's background worker, so it needs no async runtime, and the flush is bounded to a short timeout (2s) so a slow or unreachable PostHog can't freeze the crashing process. Delivery is best-effort: under sustained backpressure the event may not be sent before the process exits.

5.  5

    ## Configure stack traces

    Optional

    Stack trace capture and in-app frame classification are configured per client through `ErrorTrackingOptionsBuilder`:

    Rust

    PostHog AI

    ```rust
    use posthog_rs::{ClientOptionsBuilder, ErrorTrackingOptionsBuilder};
    let options = ClientOptionsBuilder::default()
        .api_key("<ph_project_token>".to_string())
        .host("https://us.i.posthog.com")
        .error_tracking(
            ErrorTrackingOptionsBuilder::default()
                // Skip the stack walk entirely, e.g. for high-volume handled errors
                .capture_stacktrace(false)
                // Mark frames from a crate as library code rather than in-app
                .in_app_exclude_paths(vec!["other_crate::".to_string()])
                .build()
                .unwrap(),
        )
        .build()
        .unwrap();
    let client = posthog_rs::client(options).await;
    ```

    In-app patterns match both file paths and function symbols, so crate prefixes like `"my_crate::"` and path fragments like `"/service/"` both work. By default, frames from the cargo registry, the standard library, and vendored or target paths are classified as library code.

6.  6

    ## Verify error tracking

    Recommended

    Trigger a test exception to confirm events are being sent to PostHog. You should see it appear in the [error tracking issues view](https://app.posthog.com/error_tracking).

    Rust

    PostHog AI

    ```rust
    let error = std::io::Error::new(std::io::ErrorKind::Other, "This is a test exception from Rust");
    client.capture_exception(&error).await.unwrap();
    ```

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better