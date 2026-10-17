# PostHog Rust Example Project

Repository: https://github.com/PostHog/context-mill
Path: example-apps/rust

---

## README.md

# PostHog Rust example

This is an [Axum](https://github.com/tokio-rs/axum) example demonstrating PostHog integration with product analytics, feature flags, user identification, and error tracking using the server-side Rust SDK, [`posthog-rs`](https://crates.io/crates/posthog-rs).

## Features

- **Product analytics**: Track user events and behaviors
- **User identification**: Associate events with users via person properties (`$set`)
- **Feature flags**: Control feature rollouts with PostHog feature flags
- **Error tracking**: Capture exceptions with `capture_exception`
- **Server-side tracking**: All tracking happens server-side with the async Rust SDK
- **Single client per process**: One PostHog client for the whole app, flushed on shutdown

> **Note on SDK scope:** the `posthog-rs` server SDK does **not** provide an
> `alias` helper, surveys, or session replay. This example does not scaffold or
> promise any of those. It uses only documented methods: `capture`,
> `evaluate_flags`, `capture_exception_with`, `flush`, and `shutdown`.

## Getting started

### 1. Configure environment variables

Copy `.env.example` to `.env`, fill in your values, and export them:

```bash
export POSTHOG_PROJECT_TOKEN=your_posthog_project_token
export POSTHOG_HOST=https://us.i.posthog.com
```

Get your PostHog project token from your [PostHog project settings](https://app.posthog.com/project/settings).

### 2. Run the app

```bash
cargo run
```

Open [http://localhost:8000](http://localhost:8000) with your browser to see the app.

## Project structure

```
rust/
├── Cargo.toml          # Crate + the posthog-rs dependency
├── .env.example        # Environment variable template
├── .gitignore          # Ignores /target and .env
└── src/
    └── main.rs         # Axum app: client init, routes, identify, events, flags, errors
```

## Key integration points

### PostHog client init (src/main.rs)

Build **one client per process** and share it through Axum state as an `Arc<Client>`. Never construct a new client per request.

```rust
let options = ClientOptions::from((token.as_str(), host.as_str()));
let client: Arc<Client> = Arc::new(posthog_rs::client(options).await);

let app = Router::new()
    // ...routes...
    .with_state(client.clone());
```

### Configuration from the environment (src/main.rs)

Read the token and host from the environment so secrets never live in source. A blank token logs a clear warning and the app still boots — fail loudly, but never break the app.

```rust
let token = std::env::var("POSTHOG_PROJECT_TOKEN").unwrap_or_default();
let host = std::env::var("POSTHOG_HOST")
    .unwrap_or_else(|_| "https://us.i.posthog.com".to_string());

if token.trim().is_empty() {
    tracing::warn!("POSTHOG_PROJECT_TOKEN is not set. PostHog events will NOT be delivered.");
}
```

The `(api_key, host)` tuple converts into `ClientOptions`, which is how this example applies `POSTHOG_HOST`.

### User identification (src/main.rs)

The server SDK identifies a user by attaching person properties to a capture with the `$set` property. The distinct id (2nd argument to `Event::new`) is the stable user id and must match the id your frontend `posthog.identify(...)` call uses.

```rust
let mut event = Event::new("user_logged_in", &user_id);
event.insert_prop("$set", serde_json::json!({ "email": email }))?;
event.insert_prop("login_method", "email")?;
client.capture(event); // fire-and-forget
```

### Event tracking (src/main.rs)

```rust
let mut event = Event::new("burrito_considered", &user_id);
event.insert_prop("total_considerations", count)?;
client.capture(event);
```

### Feature flags (src/main.rs)

Evaluate flags once per request with `evaluate_flags(...)`, then read individual flags off the returned snapshot. Avoid the deprecated per-flag helpers.

```rust
let flags = client
    .evaluate_flags(user_id, EvaluateFlagsOptions::default())
    .await?;
let show_new_feature = flags.is_enabled("new-dashboard-feature");
```

### Error tracking (src/main.rs)

Unlike some PostHog server SDKs, `posthog-rs` **does** capture exceptions. Report any `std::error::Error` with `capture_exception_with`, attaching the distinct id and context.

```rust
let options = CaptureExceptionOptions::new()
    .distinct_id(user_id)
    .property("source", "profile_view")?;
client.capture_exception_with(&err, options).await?;
```

### Flush and shutdown (src/main.rs)

`capture` is fire-and-forget, so queued events must be flushed before the process exits or they are lost. On graceful shutdown (Ctrl+C), flush and then shut the client down.

```rust
client.flush().await;
client.shutdown().await;
```

## Learn more

- [PostHog Rust SDK](https://posthog.com/docs/libraries/rust)
- [PostHog feature flags](https://posthog.com/docs/feature-flags)
- [PostHog documentation](https://posthog.com/docs)
- [Axum documentation](https://docs.rs/axum/latest/axum/)

---

## .env.example

```example
# Copy this file to `.env` and fill in your values, then export them
# (e.g. `export $(grep -v '^#' .env | xargs)`) before running the app.

# Your PostHog project token (from Project settings).
POSTHOG_PROJECT_TOKEN=your_posthog_project_token

# PostHog host. Defaults to https://us.i.posthog.com when unset.
POSTHOG_HOST=https://us.i.posthog.com

```

---

## Cargo.toml

```toml
[package]
name = "posthog-rust-example"
version = "0.1.0"
edition = "2021"

# A tiny "burrito" web service that mirrors the other PostHog example apps,
# built on Axum and the official `posthog-rs` server SDK.
[dependencies]
# posthog-rs 0.21 enables the "async-client" and "error-tracking" features by
# default, which is exactly what this example uses (async client + capture_exception).
posthog-rs = "0.21"
axum = "0.8"
# Cookie jar for a minimal per-browser session (stores the user's distinct id).
axum-extra = { version = "0.10", features = ["cookie"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tracing = "0.1"
tracing-subscriber = "0.3"
html-escape = "0.2.14"

```

---

## src/main.rs

```rs
//! A tiny "burrito" web service that mirrors the other PostHog example apps.
//!
//! Each route shows one integration point of the `posthog-rs` server SDK:
//!   * `/`          — home / login page
//!   * `/login`     — user identification (attach person properties)
//!   * `/burrito`   — event tracking (`burrito_considered`)
//!   * `/dashboard` — feature flags (`new-dashboard-feature`, snapshot API)
//!   * `/profile`   — error tracking (`capture_exception`)
//!
//! The PostHog client is built **once per process** and shared through Axum
//! state (an `Arc<Client>`). It is never constructed per request.

use std::io::{Error as IoError, ErrorKind};
use std::sync::Arc;

use axum::{
    extract::State,
    response::{Html, IntoResponse, Redirect},
    routing::{get, post},
    Form, Router,
};
use axum_extra::extract::cookie::{Cookie, CookieJar};
use posthog_rs::{
    CaptureExceptionOptions, Client, ClientOptions, EvaluateFlagsOptions, Event,
};
use serde::Deserialize;

/// Shared application state. `Arc<Client>` is cheap to clone and lets every
/// request handler reuse the single process-wide PostHog client.
type AppState = Arc<Client>;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    // --- Config from the environment (never hardcode secrets) --------------
    let token = std::env::var("POSTHOG_PROJECT_TOKEN").unwrap_or_default();
    let host = std::env::var("POSTHOG_HOST")
        .unwrap_or_else(|_| "https://us.i.posthog.com".to_string());

    // Fail loudly, but don't break the app: a blank token logs a clear warning
    // and the server still boots (captures simply won't be delivered).
    if token.trim().is_empty() {
        tracing::warn!(
            "POSTHOG_PROJECT_TOKEN is not set. PostHog events will NOT be delivered. \
             Set it in your environment (see .env.example) to enable analytics."
        );
    }

    // --- One client per process --------------------------------------------
    // `client()` takes anything convertible into `ClientOptions`. The tuple
    // form `(api_key, host)` sets both, so we honor POSTHOG_HOST. We build the
    // client once here and share it via Axum state for the whole process.
    let options = ClientOptions::from((token.as_str(), host.as_str()));
    let client: AppState = Arc::new(posthog_rs::client(options).await);

    let app = Router::new()
        .route("/", get(home))
        .route("/login", post(login))
        .route("/burrito", post(consider_burrito))
        .route("/dashboard", get(dashboard))
        .route("/profile", get(profile))
        .with_state(client.clone());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000")
        .await
        .expect("failed to bind 0.0.0.0:8000");
    tracing::info!("listening on http://localhost:8000");

    // Serve until Ctrl+C, then flush and shut the client down cleanly.
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("server error");

    // --- Explicit flush + shutdown -----------------------------------------
    // `capture` is fire-and-forget, so queued events must be flushed before the
    // process exits or they are lost. `shutdown` stops the background worker.
    tracing::info!("flushing PostHog events before exit...");
    client.flush().await;
    client.shutdown().await;
}

/// Resolve a stable distinct id from the session cookie, or "anonymous".
///
/// This id must match the id your frontend `posthog.identify(...)` uses so that
/// server-side and client-side events attribute to the same person.
fn distinct_id(jar: &CookieJar) -> String {
    jar.get("user_id")
        .map(|c| c.value().to_string())
        .unwrap_or_else(|| "anonymous".to_string())
}

// ---------------------------------------------------------------------------
// Home / login page
// ---------------------------------------------------------------------------
async fn home(jar: CookieJar) -> Html<String> {
    let user = distinct_id(&jar);
    // Escape user-controlled values before putting them in HTML (prevents XSS).
    let user = html_escape::encode_text(&user);
    Html(format!(
        r#"<h1>Burrito app</h1>
<p>Signed in as: <strong>{user}</strong></p>
<form method="post" action="/login">
  <input name="user_id" placeholder="user id" required>
  <input name="email" placeholder="email (optional)">
  <button type="submit">Log in</button>
</form>
<hr>
<form method="post" action="/burrito"><button>Consider a burrito</button></form>
<p><a href="/dashboard">Dashboard (feature flag)</a> &middot;
   <a href="/profile">Profile (error tracking)</a></p>"#
    ))
}

#[derive(Deserialize)]
struct LoginForm {
    user_id: String,
    email: Option<String>,
}

// ---------------------------------------------------------------------------
// User identification
// ---------------------------------------------------------------------------
// The server SDK "identifies" a user by attaching person properties to a
// capture. `$set` writes person properties; the distinct id (2nd arg to
// `Event::new`) is the stable user id shared with the frontend.
async fn login(
    State(client): State<AppState>,
    jar: CookieJar,
    Form(form): Form<LoginForm>,
) -> impl IntoResponse {
    let email = form.email.unwrap_or_default();

    let mut event = Event::new("user_logged_in", &form.user_id);
    let _ = event.insert_prop("$set", serde_json::json!({ "email": email }));
    let _ = event.insert_prop("login_method", "email");
    client.capture(event); // fire-and-forget

    // Persist the distinct id for later requests.
    let jar = jar.add(Cookie::new("user_id", form.user_id));
    (jar, Redirect::to("/"))
}

// ---------------------------------------------------------------------------
// Event tracking
// ---------------------------------------------------------------------------
async fn consider_burrito(
    State(client): State<AppState>,
    jar: CookieJar,
) -> impl IntoResponse {
    let user = distinct_id(&jar);

    let count: u32 = jar
        .get("burrito_count")
        .and_then(|c| c.value().parse().ok())
        .unwrap_or(0)
        + 1;

    let mut event = Event::new("burrito_considered", &user);
    let _ = event.insert_prop("total_considerations", count);
    client.capture(event);

    let jar = jar.add(Cookie::new("burrito_count", count.to_string()));
    (
        jar,
        Html(format!(
            "<h1>Burrito considered</h1><p>You have considered {count} burrito(s).</p>\
             <p><a href=\"/\">Back</a></p>"
        )),
    )
}

// ---------------------------------------------------------------------------
// Feature flags
// ---------------------------------------------------------------------------
// Evaluate flags once with `evaluate_flags(...)`, then read individual flags
// off the returned snapshot. Avoid deprecated per-flag helpers.
async fn dashboard(State(client): State<AppState>, jar: CookieJar) -> Html<String> {
    let user = distinct_id(&jar);

    let show_new_feature = match client
        .evaluate_flags(user.clone(), EvaluateFlagsOptions::default())
        .await
    {
        Ok(flags) => flags.is_enabled("new-dashboard-feature"),
        Err(e) => {
            // Never break the page if flag evaluation fails — fall back to off.
            tracing::warn!("evaluate_flags failed: {e}");
            false
        }
    };

    let body = if show_new_feature {
        "<p>✨ The new dashboard feature is <strong>enabled</strong>.</p>"
    } else {
        "<p>The new dashboard feature is disabled.</p>"
    };
    // Escape the distinct id before rendering it (the raw value went to the SDK above).
    let user = html_escape::encode_text(&user);
    Html(format!(
        "<h1>Dashboard</h1><p>User: {user}</p>{body}<p><a href=\"/\">Back</a></p>"
    ))
}

// ---------------------------------------------------------------------------
// Error tracking
// ---------------------------------------------------------------------------
// The Rust SDK CAN capture exceptions. Trigger a failure, then report it with
// `capture_exception_with`, attaching the distinct id and a bit of context.
async fn profile(State(client): State<AppState>, jar: CookieJar) -> Html<String> {
    let user = distinct_id(&jar);

    let message = match risky_operation() {
        Ok(()) => "no error".to_string(),
        Err(err) => {
            tracing::warn!("profile risky_operation failed: {err}");

            // `property` returns a Result (serialization can fail); keep the
            // context if it serializes, otherwise send the exception without it.
            let options = match CaptureExceptionOptions::new()
                .distinct_id(user.clone())
                .property("source", "profile_view")
            {
                Ok(o) => o,
                Err(_) => CaptureExceptionOptions::new().distinct_id(user.clone()),
            };
            if let Err(e) = client.capture_exception_with(&err, options).await {
                tracing::warn!("capture_exception failed: {e}");
            }
            err.to_string()
        }
    };

    // Escape user-controlled values before rendering (the raw id went to the SDK above).
    let user = html_escape::encode_text(&user);
    let message = html_escape::encode_text(&message);
    Html(format!(
        "<h1>Profile</h1><p>User: {user}</p>\
         <p>Triggered error (captured by PostHog): <code>{message}</code></p>\
         <p><a href=\"/\">Back</a></p>"
    ))
}

/// Stand-in for real work that can fail. Returns a `std::error::Error`, which
/// is exactly what `capture_exception_with` accepts.
fn risky_operation() -> Result<(), IoError> {
    Err(IoError::new(
        ErrorKind::Other,
        "profile data source is temporarily unavailable",
    ))
}

/// Resolves when the process receives Ctrl+C, triggering graceful shutdown.
async fn shutdown_signal() {
    let _ = tokio::signal::ctrl_c().await;
    tracing::info!("shutdown signal received");
}

```

---

