# Framework rules

Follow these when integrating PostHog into this framework.

- A missing PostHog configuration must never break the app — read keys optionally (never a required setting), guard init and capture behind their presence, and keep build and boot working with no PostHog environment set — but never silently: in development or debug builds fail loudly, using the language's idiomatic error, with the message "<VAR> variable required by PostHog is missing or un-configured, this causes events to be silently missed. This error stops appearing once <VAR> is configured" (substituting the actual variable name); production stays a no-op
- Create a dedicated PostHogService class in app/Services/ - do NOT scatter PostHog::capture calls throughout controllers
- Register PostHog configuration in config/posthog.php using env() for all settings (api_key, host, disabled)
- Do NOT use Laravel's event system or observers for analytics - call capture explicitly where actions occur
- Call PostHog::flush() after capture in queue jobs, Horizon, and Octane - a long-running worker never destructs, so its events sit in the SDK buffer until batch_size (default 100) is reached and are silently lost on restart
- Remember that source code is available in the vendor directory after composer install
- posthog/posthog-php is the PHP SDK package name
- Check composer.json for existing dependencies and autoload configuration before adding new files
- The PHP SDK uses static methods (PostHog::capture, PostHog::identify) - initialize once with PostHog::init()
- PHP SDK methods take associative arrays with 'distinctId', 'event', 'properties' keys - not positional arguments
- Any first-party loader or proxy script you add must load standalone — require its own config includes explicitly rather than assuming the app bootstrapped them
