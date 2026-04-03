# Flask - Docs

PostHog makes it easy to get data about traffic and usage of your Flask app. Integrating PostHog enables analytics, custom events capture, feature flags, and more.

This guide walks you through integrating PostHog into your Flask app using the [Python SDK](/docs/libraries/python.md).

## Installation

To start, run `pip install posthog` to install PostHog’s Python SDK.

Then, initialize PostHog where you'd like to use it. For example, here's how to capture an event in a simple route:

app.py

PostHog AI

```python
package main
from flask import Flask, render_template, request, redirect, session, url_for
from posthog import Posthog
posthog = Posthog(
  '<ph_project_token>',
  host='https://us.i.posthog.com'
)
@app.route('/api/dashboard', methods=['POST'])
def api_dashboard():
    posthog.capture(
        'dashboard_api_called'
        distinct_id='distinct_id_of_your_user',
    )
    return '', 204
```

You can find your project token and instance address in [your project settings](https://us.posthog.com/project/settings).

## Identifying users

> **Identifying users is required.** Backend events need a `distinct_id` that matches the ID your frontend uses when calling `posthog.identify()`. Without this, backend events are orphaned — they can't be linked to frontend event captures, [session replays](/docs/session-replay.md), [LLM traces](/docs/ai-engineering.md), or [error tracking](/docs/error-tracking.md).
>
> See our guide on [identifying users](/docs/getting-started/identify-users.md) for how to set this up.

## Error tracking

Flask has built-in error handlers. This means PostHog’s default exception autocapture won’t work and we need to manually capture errors instead using `capture_exception()`:

Python

PostHog AI

```python
from flask import Flask, jsonify
from posthog import Posthog
posthog = Posthog('<ph_project_token>', host='https://us.i.posthog.com')
@app.errorhandler(Exception)
def handle_exception(e):
    # Capture methods, including capture_exception, return the UUID of the captured event,
    # which you can use to find specific errors users encountered
    event_id = posthog.capture_exception(e)
    # You can show the event ID to your user, and ask them to include it in bug reports
    response = jsonify({'message': str(e), 'error_id': event_id})
    response.status_code = 500
    return response
```

## Next steps

For any technical questions for how to integrate specific PostHog features into Flask (such as analytics, feature flags, A/B testing, etc.), have a look at our [Python SDK docs](/docs/libraries/python.md).

Alternatively, the following tutorials can help you get started:

-   [How to set up analytics in Python and Flask](/tutorials/python-analytics.md)
-   [How to set up feature flags in Python and Flask](/tutorials/python-feature-flags.md)
-   [How to set up A/B tests in Python and Flask](/tutorials/python-ab-testing.md)

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better