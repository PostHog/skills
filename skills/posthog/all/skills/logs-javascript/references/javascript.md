> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# JavaScript web Logs installation - Docs

Copy page

# JavaScript web Logs installation - Docs

The PostHog JavaScript web SDK ships with first-class support for Logs. Send structured log records with the `posthog.logger` API or opt in to autocapture of `console.*` calls.

> **Minimum version:** `posthog-js@1.368.0` or later. Run `npm update posthog-js` (or your package manager's equivalent) to update.

1.  1

    ## Install posthog-js

    Required

    If you haven't already, install `posthog-js` using your package manager:

    PostHog AI

    ### npm

    ```bash
    npm install --save posthog-js
    ```

    ### Yarn

    ```bash
    yarn add posthog-js
    ```

    ### pnpm

    ```bash
    pnpm add posthog-js
    ```

    ### Bun

    ```bash
    bun add posthog-js
    ```

    > **If your site sets a Content-Security-Policy**, it needs to allow PostHog. This applies to the snippet and to package installs alike: the SDK lazy-loads extra bundles (session replay, surveys) from PostHog's CDN, and sends events to the ingestion host. PostHog serves from subdomains of `posthog.com` that change over time, so allow the wildcard:
    >
    > PostHog AI
    >
    > ```
    > script-src 'self' https://*.posthog.com;
    > connect-src 'self' https://*.posthog.com;
    > worker-src 'self' blob: data:;
    > ```
    >
    > `script-src` covers the snippet and the lazy-loaded bundles, `connect-src` covers event ingestion and feature flags, and `worker-src` covers session replay. The [toolbar needs a few more](/docs/advanced/content-security-policy.md), or use a [reverse proxy](/docs/advanced/proxy.md) so everything is first-party. Failing to do so causes silent failures where `capture` and `identify` calls never send, so the integration looks complete while zero events arrive. Remember `connect-src` falls back to `default-src`, so `default-src 'self'` blocks event delivery even when the script itself is bundled.

2.  2

    ## Configure logs at init

    Required

    Set your service identity in `posthog.init`. These fields map to standard [OpenTelemetry resource attributes](https://opentelemetry.io/docs/specs/semconv/resource/) and apply to every log record this client sends.

    Web

    PostHog AI

    ```javascript
    import posthog from 'posthog-js'
    posthog.init('<ph_project_token>', {
      api_host: 'https://us.i.posthog.com',
      defaults: '2026-05-30',
      logs: {
        serviceName: 'checkout-web',
        environment: 'production',
        serviceVersion: '1.2.3',
      },
    })
    ```

    | Option | Description |
    | --- | --- |
    | serviceName | Identifies the app in the Logs UI. Maps to the OpenTelemetry service.name resource attribute. Defaults to 'unknown_service'. |
    | environment | Deployment environment, e.g. 'production' or 'staging'. Maps to deployment.environment. |
    | serviceVersion | Release version, e.g. '1.2.3'. Maps to service.version. |
    | resourceAttributes | Additional OpenTelemetry resource attributes, e.g. { 'host.name': 'web-01' }. |
    | flushIntervalMs | How often batched log records are flushed. Defaults to 3000. |
    | maxBufferSize | Buffer size before forcing a flush. Defaults to 100. |
    | maxLogsPerInterval | Rate limit per flush window. Excess records are dropped with a single warning. Defaults to 1000. |

    See the [web SDK config reference](/docs/libraries/js/config.md#configuring-logs) for the complete list.

3.  3

    ## Send structured logs with posthog.logger

    Recommended

    `posthog.logger` is the declarative path. Each call produces an OTLP log record with a severity level and typed attributes you can filter and query on in the Logs product.

    Web

    PostHog AI

    ```javascript
    posthog.logger.info('checkout completed', { order_id: 'ord_789', total_cents: 4200 })
    posthog.logger.warn('payment retry', { attempt: 2, gateway: 'stripe' })
    posthog.logger.error('payment failed', { error_code: 'E001', order_id: 'ord_789' })
    ```

    Available severity levels: `trace`, `debug`, `info`, `warn`, `error`, and `fatal`.

    Logger calls don't write to the browser console, they go directly to PostHog as structured records. You can query logs by attribute, such as `total_cents > 1000`, instead of string-searching log output. Nothing extra appears in the user's browser console.

    For full control over a log record, including trace correlation, use `posthog.captureLog`:

    Web

    PostHog AI

    ```javascript
    posthog.captureLog({
      body: 'checkout completed',
      level: 'info',
      attributes: { order_id: 'ord_789', tags: ['checkout', 'v2'] },
      trace_id: '0af7651916cd43dd8448eb211c80319c', // optional, 32 hex chars
      span_id: 'b7ad6b7169203331',                   // optional, 16 hex chars
    })
    ```

    Attribute values can be strings, numbers, booleans, arrays, or plain objects. `null` and `undefined` values are dropped.

4.  4

    ## Autocapture console logs

    Optional

    To forward `console.log`, `console.warn`, `console.error`, and friends without changing your code, set `logs.captureConsoleLogs: true`.

    Web

    PostHog AI

    ```javascript
    posthog.init('<ph_project_token>', {
      api_host: 'https://us.i.posthog.com',
      defaults: '2026-05-30',
      logs: {
        captureConsoleLogs: true,
        serviceName: 'checkout-web',
      },
    })
    ```

    > **Warning:** Overriding a system library like `console` has a large blast radius. Everything your app or its dependencies write to the console gets forwarded to PostHog, including:
    >
    > -   Debug output referencing passwords, tokens, API keys, or session identifiers
    > -   Stack traces containing user input
    > -   Third-party library chatter you don't control
    >
    > This can breach data privacy compliance and is difficult to clean up. Before turning it on:
    >
    > 1.  Audit what your app and its dependencies currently log.
    > 2.  Get sign-off from anyone in your organization whose code runs in the browser.
    > 3.  Prefer `posthog.logger` for anything you actually care about – it's structured, queryable, and doesn't pull in unrelated output.

    `posthog.logger` and `captureConsoleLogs` are independent and can be enabled together. The logger path emits OTLP records directly; the autocapture path scrapes console strings.

5.  5

    ## Link logs to sessions and users

    Recommended

    When `posthog-js` is initialized, the web SDK automatically attaches the current `distinct_id` and `session_id` to every log record. Log entries appear linked to the matching [Session Replay](/docs/session-replay.md) and person without any extra setup.

    See [Link Session Replay](/docs/logs/link-session-replay.md) for how this surfaces in the UI, and how to do the equivalent from server-side SDKs.

6.  6

    ## Test your setup

    Recommended

    Once everything is configured, verify log records are flowing:

    1.  Call `posthog.logger.info('hello from posthog-js')` somewhere your page executes.
    2.  Open the [Logs](https://app.posthog.com/logs) interface and filter by the `serviceName` you set above.
    3.  Confirm the record shows up with the attributes you sent.

    [View your logs in PostHog](https://app.posthog.com/logs)

8.  ## Next steps

    Checkpoint

    *What you can do with your logs*

    | Action | Description |
    | --- | --- |
    | [Why you need logs](/docs/logs/basics.md) | What logs show you that nothing else does |
    | [Search logs](/docs/logs/search.md) | Use the search interface to find specific log entries |
    | Filter by level | Filter by INFO, WARN, ERROR, etc. |
    | [Link session replay](/docs/logs/link-session-replay.md) | Connect logs to users and session replays by passing posthogDistinctId and sessionId |
    | [Link logs to a person](/docs/logs/link-person.md) | Surface every log emitted on behalf of a user on their PostHog person profile |
    | [Logging best practices](/docs/logs/best-practices.md) | Learn what to log, how to structure logs, and patterns that make logs useful in production |

    [Troubleshoot common issues](/docs/logs/troubleshooting.md)

### Still have questions?

Ask PostHog AI

### Was this page useful?

HelpfulCould be better