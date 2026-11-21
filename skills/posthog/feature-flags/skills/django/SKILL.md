---
name: feature-flags-django
description: PostHog feature flags for Django applications
metadata:
  author: PostHog
  version: dev
---

# PostHog feature flags for Django

This skill helps you add PostHog feature flags to Django applications.

## Reference files

- `references/python.md` - Python feature flags installation - docs
- `references/django.md` - Django - docs
- `references/adding-feature-flag-code.md` - Adding feature flag code - docs
- `references/best-practices.md` - Best practices for production-ready flags - docs
- `references/COMMANDMENTS.md` - Framework-specific rules the integration must follow

Consult the documentation for API details and framework-specific patterns.

## Key principles

- **Environment variables**: Always use environment variables for PostHog keys. Never hardcode them.
- **Minimal changes**: Add feature flag code alongside existing logic. Don't replace or restructure existing code.
- **Boolean flags first**: Default to boolean flag checks unless the user specifically asks for multivariate flags.
- **Server-side when possible**: Prefer server-side flag evaluation to avoid UI flicker.

## PostHog MCP tools

Check if a PostHog MCP server is connected. If available, look for tools related to feature flag management (creating, listing, updating, deleting flags). Use these tools to manage flags directly in PostHog rather than requiring the user to do it manually in the dashboard.

## Framework guidelines

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Add 'posthog.integrations.django.PosthogContextMiddleware' to MIDDLEWARE, after AuthenticationMiddleware, it auto-extracts tracing headers and captures exceptions
- Initialize PostHog in AppConfig.ready() with api_key and host from environment variables
- The middleware identifies the request context from the X-POSTHOG-DISTINCT-ID header or the authenticated user's pk, so in a view where the user is already logged in a plain capture() is already attributed - do not wrap it in a context of its own
- The middleware reads the user once, before the view runs, so a login request's context is identified as whoever the user was beforehand - nobody - and calling login() does not update it. A bare capture there is personless. Hook Django's user_logged_in signal and call identify_context(str(user.pk)) inside it: the signal runs inside the login request, so it fixes the ambient context and every later capture in that request is attributed. Logout views need no special handling, the user is still authenticated when the middleware runs - capture before calling logout()
- Do NOT create custom middleware, distinct_id helpers, or conditional checks - the SDK handles these
- Remember that source code is available in the venv/site-packages directory
- posthog is the Python SDK package name
- Install dependencies with `pip install posthog` or `pip install -r requirements.txt` and do NOT use unquoted version specifiers like `>=` directly in shell commands
- In CLIs and scripts: MUST call posthog.shutdown() before exit or all events are lost
- Always use the Posthog() class constructor (instance-based API) instead of module-level posthog.api_key config
- Always include enable_exception_autocapture=True in the Posthog() constructor to automatically track exceptions
- NEVER send PII in capture() event properties — no emails, full names, phone numbers, physical addresses, IP addresses, or user-generated content
- PII belongs in identify() person properties, NOT in capture() event properties. Safe event properties are metadata like message_length, form_type, boolean flags.
- Register posthog_client.shutdown with atexit.register() to ensure all events are flushed on exit
- The Python SDK has NO identify() method — use posthog_client.set(distinct_id=user_id, properties={...}) to set person properties, or use identify_context(user_id) within a context
