# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Adapt dependency configuration to the appropriate build.gradle(.kts) file according to the project gradle version
- Call `PostHogAndroid.setup()` only once in the Application class's `onCreate()` method, so it's initialized as early as possible and only once.
- Initialize PostHog in the Application class's `onCreate()` method
- Ensure every activity has a `android:label` to accurately track screen views.
