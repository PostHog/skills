> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# Datadog Logs installation

Canonical URL: https://posthog.com/docs/logs/installation/datadog

> **Cloud region:** This page uses US Cloud hosts. For an EU Cloud project, use `https://eu.i.posthog.com` instead of `https://us.i.posthog.com` (ingestion host), and use `https://eu.posthog.com` instead of `https://app.posthog.com` (app host for links).

## On this page

- [Get your project token](#get-your-project-token)
- [Configure Datadog Agent](#configure-datadog-agent)
- [Dual-ship to Datadog and PostHog](#dual-ship-to-datadog-and-posthog)
- [Other Datadog log exporters](#other-datadog-log-exporters)
- [Test your setup](#test-your-setup)
- [Next steps](#next-steps)

If you're already using Datadog to collect logs, you can forward them to PostHog by configuring your existing Datadog log exporters (like the Datadog Agent) to send logs to PostHog's Datadog-compatible endpoint.

1.  1

    ## Get your project token

    Required

    You'll need your PostHog project token to authenticate log requests. This is the same key you use for capturing events and exceptions with the PostHog SDK.

    > **Important:** Use your **project token** which starts with `phc_`. Do **not** use a personal token (which starts with `phx_`).

    You can find your project token in [Project Settings](https://app.posthog.com/settings/project).

2.  2

    ## Configure Datadog Agent

    Required

    Set the Datadog logs URL to point to PostHog's Datadog-compatible endpoint. The endpoint format is:

    ```
    https://us.i.posthog.com/i/v1/logs/datadog/<ph_project_token>
    ```

    For the **Datadog Agent**, set the `DD_LOGS_CONFIG_LOGS_DD_URL` environment variable:

    ```bash
    export DD_LOGS_CONFIG_LOGS_DD_URL="https://us.i.posthog.com/i/v1/logs/datadog/<ph_project_token>"
    ```

    Alternatively, you can set this in your `datadog.yaml` configuration file:

    ```yaml
    logs_config:
      logs_dd_url: "https://us.i.posthog.com/i/v1/logs/datadog/<ph_project_token>"
    ```

3.  3

    ## Dual-ship to Datadog and PostHog

    Optional

    To compare PostHog and Datadog side by side, send the same logs to both at the same time. Keep `logs_dd_url` set to PostHog as shown in the previous step, then add Datadog as an additional endpoint, as described in Datadog's [dual shipping docs](https://docs.datadoghq.com/agent/configuration/dual-shipping/?tab=helm#logs):

    datadog.yaml

    ```yaml
    logs_config:
      logs_dd_url: "https://us.i.posthog.com/i/v1/logs/datadog/<ph_project_token>"
      force_use_http: true
      additional_endpoints:
        - api_key: "<YOUR_DATADOG_API_KEY>"
          Host: "agent-http-intake.logs.<YOUR_DATADOG_SITE>" # For example, datadoghq.com
          Port: 443
          is_reliable: true
    ```

    With `is_reliable: true`, the Agent treats both endpoints equally. If one is unavailable, logs keep flowing to the other.

    **Get a discounted trial while you test**

    Dual-shipping means you pay for the same logs twice while you compare. [Contact sales](https://posthog.com/talk-to-a-human.md) to get a discounted trial period for the time you're testing.

4.  4

    ## Other Datadog log exporters

    Optional

    If you're using other Datadog log exporters or forwarders, configure them to send logs to the same endpoint:

    ```
    https://us.i.posthog.com/i/v1/logs/datadog/<ph_project_token>
    ```

    The endpoint accepts logs in the standard Datadog log format, so existing integrations should work without additional changes.

5.  5

    ## Test your setup

    Recommended

    Once everything is configured, test that logs are flowing into PostHog:

    1.  Restart the Datadog Agent (or your log forwarder) to apply the configuration
    2.  Generate some log entries in your application
    3.  Check the PostHog Logs interface for your log entries
    4.  Verify the logs appear in your project

    [View your logs in PostHog](https://app.posthog.com/logs)

7.  ## Next steps

    Checkpoint

    *What you can do with your logs*

    | Action | Description |
    | --- | --- |
    | **[Why you need logs](https://posthog.com/docs/logs/basics.md)** | What logs show you that nothing else does |
    | **[Search logs](https://posthog.com/docs/logs/search.md)** | Use the search interface to find specific log entries |
    | **Filter by level** | Filter by `INFO`, `WARN`, `ERROR`, etc. |
    | **[Link session replay](https://posthog.com/docs/logs/link-session-replay.md)** | Connect logs to users and session replays by passing `posthogDistinctId` and `sessionId` |
    | **[Link logs to a person](https://posthog.com/docs/logs/link-person.md)** | Surface every log emitted on behalf of a user on their PostHog person profile |
    | **[Logging best practices](https://posthog.com/docs/logs/best-practices.md)** | Learn what to log, how to structure logs, and patterns that make logs useful in production |

    [Troubleshoot common issues](https://posthog.com/docs/logs/troubleshooting.md)
