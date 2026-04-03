# Django - Docs

PostHog makes it easy to get data about traffic and usage of your Django app. Integrating PostHog enables analytics, custom events capture, feature flags, and more.

This guide walks you through integrating PostHog into your Django app using the [Python SDK](/docs/libraries/python.md).

## Beta: integration via LLM

Install PostHog for Django in seconds with our wizard by running this prompt with [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt, or by running it in your terminal.

`npx @posthog/wizard@latest`

[Learn more](/wizard.md)

Or, to integrate manually, continue with the rest of this guide.

## Installation

To start, run `pip install posthog` to install PostHog’s Python SDK.

Then, set the PostHog API key and host in your `AppConfig` in your `your_app/apps.py` so that's it's available everywhere:

your\_app/apps.py

PostHog AI

```python
from django.apps import AppConfig
import posthog
class YourAppConfig(AppConfig):
    name = "your_app_name"
    def ready(self):
        posthog.api_key = '<ph_project_token>'
        posthog.host = 'https://us.i.posthog.com'
```

You can find your project token and instance address in [your project settings](https://us.posthog.com/project/settings).

Next, if you haven't done so already, make sure you add your `AppConfig` to your `settings.py` under `INSTALLED_APPS`:

settings.py

PostHog AI

```python
INSTALLED_APPS = [
    # other apps
    'your_app_name.apps.MyAppConfig',  # Add your app config
]
```

Lastly, to access PostHog in any file, simply `import posthog` and call the method you'd like. For example, to capture an event:

Python

PostHog AI

```python
import posthog
def some_request(request):
    with posthog.new_context():
        posthog.identify_context(request.user.id)
        posthog.capture('event_name')
```

## Identifying users

> **Identifying users is required.** Backend events need a `distinct_id` that matches the ID your frontend uses when calling `posthog.identify()`. Without this, backend events are orphaned — they can't be linked to frontend event captures, [session replays](/docs/session-replay.md), [LLM traces](/docs/ai-engineering.md), or [error tracking](/docs/error-tracking.md).
>
> See our guide on [identifying users](/docs/getting-started/identify-users.md) for how to set this up.

## Django contexts middleware

The Python SDK provides a Django middleware that automatically wraps all requests with a [context](/docs/libraries/python.md#contexts). This middleware extracts session and user information from request headers and tags all events captured during the request with relevant metadata.

### Basic setup

Add the middleware to your Django settings:

Python

PostHog AI

```python
MIDDLEWARE = [
    # ... other middleware
    'posthog.integrations.django.PosthogContextMiddleware',
    # ... other middleware
]
```

The middleware automatically extracts and uses:

-   **Session ID** from the `X-POSTHOG-SESSION-ID` header, if present
-   **Distinct ID** from the `X-POSTHOG-DISTINCT-ID` header, if present
-   **Current URL** as `$current_url`
-   **Request method** as `$request_method`

All events captured during the request (including exceptions) will include these properties and be associated with the extracted session and distinct ID.

If you are using PostHog on your frontend, the JavaScript Web SDK will add the session and distinct ID headers automatically if you enable tracing headers.

JavaScript

PostHog AI

```javascript
posthog.init('<ph_project_token>', {
    __add_tracing_headers: ['your-backend-domain.com']
})
```

### Exception capture

By default, the middleware captures exceptions and sends them to PostHog's error tracking. Disable this by setting:

Python

PostHog AI

```python
# settings.py
POSTHOG_MW_CAPTURE_EXCEPTIONS = False
```

### Adding custom tags

Use `POSTHOG_MW_EXTRA_TAGS` to add custom properties to all requests:

Python

PostHog AI

```python
# settings.py
def add_user_tags(request):
    # type: (HttpRequest) -> Dict[str, Any]
    tags = {}
    if hasattr(request, 'user') and request.user.is_authenticated:
        tags['user_id'] = request.user.id
        tags['email'] = request.user.email
    return tags
POSTHOG_MW_EXTRA_TAGS = add_user_tags
```

#### Filtering requests

Skip tracking for certain requests using `POSTHOG_MW_REQUEST_FILTER`:

Python

PostHog AI

```python
# settings.py
def should_track_request(request):
    # type: (HttpRequest) -> bool
    # Don't track health checks or admin requests
    if request.path.startswith('/health') or request.path.startswith('/admin'):
        return False
    return True
POSTHOG_MW_REQUEST_FILTER = should_track_request
```

### Modifying default tags

Use `POSTHOG_MW_TAG_MAP` to modify or remove default tags:

Python

PostHog AI

```python
# settings.py
def customize_tags(tags):
    # type: (Dict[str, Any]) -> Dict[str, Any]
    # Remove URL for privacy
    tags.pop('$current_url', None)
    # Add custom prefix to method
    if '$request_method' in tags:
        tags['http_method'] = tags.pop('$request_method')
    return tags
POSTHOG_MW_TAG_MAP = customize_tags
```

### Complete configuration example

Python

PostHog AI

```python
# settings.py
def add_request_context(request):
    # type: (HttpRequest) -> Dict[str, Any]
    tags = {}
    if hasattr(request, 'user') and request.user.is_authenticated:
        tags['user_type'] = 'authenticated'
        tags['user_id'] = str(request.user.id)
    else:
        tags['user_type'] = 'anonymous'
    # Add request info
    tags['user_agent'] = request.META.get('HTTP_USER_AGENT', '')
    return tags
def filter_tracking(request):
    # type: (HttpRequest) -> bool
    # Skip internal endpoints
    return not request.path.startswith(('/health', '/metrics', '/admin'))
def clean_tags(tags):
    # type: (Dict[str, Any]) -> Dict[str, Any]
    # Remove sensitive data
    tags.pop('user_agent', None)
    return tags
POSTHOG_MW_EXTRA_TAGS = add_request_context
POSTHOG_MW_REQUEST_FILTER = filter_tracking
POSTHOG_MW_TAG_MAP = clean_tags
POSTHOG_MW_CAPTURE_EXCEPTIONS = True
```

All events captured within the request context automatically include the configured tags and are associated with the session and user identified from the request headers.

## Next steps

For any technical questions for how to integrate specific PostHog features into Django (such as analytics, feature flags, A/B testing, etc.), have a look at our [Python SDK docs](/docs/libraries/python.md).

Alternatively, the following tutorials can help you get started:

-   [Setting up Django analytics, feature flags, and more](/tutorials/django-analytics.md)
-   [How to set up A/B tests in Django](/tutorials/django-ab-tests.md)

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better