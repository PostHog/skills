# Ruby on Rails - Docs

PostHog makes it easy to get data about traffic and usage of your Ruby on Rails app. Integrating PostHog enables analytics, custom events capture, feature flags, and automatic exception tracking.

This guide walks you through integrating PostHog into your Rails app using the [posthog-rails gem](https://github.com/PostHog/posthog-ruby/tree/main/posthog-rails).

## Beta: integration via LLM

Install PostHog for Rails in seconds with our wizard by running this prompt with [LLM coding agents](/blog/envoy-wizard-llm-agent.md) like Cursor and Bolt, or by running it in your terminal.

`npx @posthog/wizard@latest`

[Learn more](/wizard.md)

Or, to integrate manually, continue with the rest of this guide.

## Features

-   **Automatic exception tracking** – Captures unhandled and rescued exceptions
-   **ActiveJob instrumentation** – Tracks background job exceptions
-   **User context** – Automatically associates exceptions with the current user
-   **Smart filtering** – Excludes common Rails exceptions (404s, etc.) by default
-   **Rails 7.0+ error reporter** – Integrates with Rails' built-in error reporting

## Installation

Add both gems to your Gemfile:

Gemfile

PostHog AI

```ruby
gem 'posthog-ruby'
gem 'posthog-rails'
```

Then run:

Terminal

PostHog AI

```bash
bundle install
```

## Identifying users

> **Identifying users is required.** Backend events need a `distinct_id` that matches the ID your frontend uses when calling `posthog.identify()`. Without this, backend events are orphaned — they can't be linked to frontend event captures, [session replays](/docs/session-replay.md), [LLM traces](/docs/ai-engineering.md), or [error tracking](/docs/error-tracking.md).
>
> See our guide on [identifying users](/docs/getting-started/identify-users.md) for how to set this up.

### Generate the initializer

Run the install generator to create the PostHog initializer:

Terminal

PostHog AI

```bash
rails generate posthog:install
```

This creates `config/initializers/posthog.rb` with sensible defaults and documentation.

## Configuration

The generated initializer includes all available options:

config/initializers/posthog.rb

PostHog AI

```ruby
# Core PostHog client initialization
PostHog.init do |config|
  # Required: Your PostHog API key
  config.api_key = '<ph_project_token>'
  # Optional: Your PostHog instance URL
  config.host = 'https://us.i.posthog.com'
  # Optional: Personal API key for feature flags
  config.personal_api_key = 'phx_xxxxxxxxx'
  # Error callback to detect misconfiguration
  config.on_error = proc { |status, msg|
    Rails.logger.error("PostHog error: #{msg}")
  }
end
# Rails-specific configuration
PostHog::Rails.configure do |config|
  config.auto_capture_exceptions = true           # Enable automatic exception capture
  config.report_rescued_exceptions = true         # Report exceptions Rails rescues
  config.auto_instrument_active_job = true        # Instrument background jobs
  config.capture_user_context = true              # Include user info in exceptions
  config.current_user_method = :current_user      # Method to get current user
  # Add additional exceptions to ignore
  config.excluded_exceptions = ['MyCustomError']
end
```

You can find your project token and instance address in [your project settings](https://us.posthog.com/project/settings).

> **Tip:** Use [`Rails.application.credentials`](https://guides.rubyonrails.org/security.html#custom-credentials) to avoid hardcoding API keys. First, add your keys and then reference them in your initializer:
>
> Terminal
>
> PostHog AI
>
> ```bash
> rails credentials:edit
> ```
>
> config/credentials.yml.enc
>
> PostHog AI
>
> ```yaml
> posthog:
>   api_key: <ph_project_token>
>   host: https://us.i.posthog.com
>   personal_api_key: phx_xxxxxxxxx
> ```
>
> config/initializers/posthog.rb
>
> PostHog AI
>
> ```ruby
> config.api_key = Rails.application.credentials.posthog[:api_key]
> config.host = Rails.application.credentials.posthog[:host]
> config.personal_api_key = Rails.application.credentials.posthog[:personal_api_key]
> ```

## Capturing events

Track custom events anywhere in your Rails app:

Ruby

PostHog AI

```ruby
# Track an event
PostHog.capture(
  distinct_id: current_user.id,
  event: 'post_created',
  properties: { title: @post.title }
)
# Identify a user
PostHog.identify(
  distinct_id: current_user.id,
  properties: {
    email: current_user.email,
    plan: current_user.plan
  }
)
```

## Error tracking

For full details on setting up error tracking with Rails, see our [Rails error tracking installation guide](/docs/error-tracking/installation/ruby-on-rails.md).

### Automatic exception tracking

When `auto_capture_exceptions` is enabled, exceptions are automatically captured:

Ruby

PostHog AI

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    # Any exception here is automatically captured
  end
end
```

### Manual exception capture

You can also manually capture exceptions:

Ruby

PostHog AI

```ruby
PostHog.capture_exception(
  exception,
  current_user.id,
  { custom_property: 'value' }
)
```

### Background job exceptions

When `auto_instrument_active_job` is enabled, ActiveJob exceptions are automatically captured with job context:

Ruby

PostHog AI

```ruby
class EmailJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
    # Exceptions are automatically captured
  end
end
```

#### Associating jobs with users

By default, PostHog extracts a `distinct_id` from job arguments by looking for a `user_id` key:

Ruby

PostHog AI

```ruby
# PostHog will automatically use options[:user_id] as the distinct_id
ProcessOrderJob.perform_later(order.id, user_id: current_user.id)
```

For more control, use the `posthog_distinct_id` class method:

Ruby

PostHog AI

```ruby
class SendWelcomeEmailJob < ApplicationJob
  posthog_distinct_id ->(user, options) { user.id }
  def perform(user, options = {})
    UserMailer.welcome(user).deliver_now
  end
end
```

### Rails 7.0+ error reporter

PostHog integrates with Rails' built-in error reporting:

Ruby

PostHog AI

```ruby
# These errors are automatically sent to PostHog
Rails.error.handle do
  # Code that might raise an error
end
Rails.error.record(exception, context: { user_id: current_user.id })
```

PostHog automatically extracts the user's distinct ID from `user_id` or `distinct_id` in the context hash.

### User context

PostHog Rails automatically captures user information from your controllers. If your user method has a different name, configure it:

Ruby

PostHog AI

```ruby
PostHog::Rails.config.current_user_method = :logged_in_user
```

#### User ID extraction

By default, PostHog Rails auto-detects the user's distinct ID by trying these methods:

1.  `posthog_distinct_id` – Define this on your User model for full control
2.  `distinct_id` – Common analytics convention
3.  `id` – Standard ActiveRecord primary key

You can configure a specific method:

Ruby

PostHog AI

```ruby
PostHog::Rails.config.user_id_method = :email
```

Or define a method on your User model:

Ruby

PostHog AI

```ruby
class User < ApplicationRecord
  def posthog_distinct_id
    "user_#{id}"  # or external_id, or any unique identifier
  end
end
```

### Excluded exceptions

The following exceptions are not reported by default (common 4xx errors):

-   `AbstractController::ActionNotFound`
-   `ActionController::BadRequest`
-   `ActionController::InvalidAuthenticityToken`
-   `ActionController::RoutingError`
-   `ActionController::UnknownFormat`
-   `ActiveRecord::RecordNotFound`

Add more with:

Ruby

PostHog AI

```ruby
PostHog::Rails.config.excluded_exceptions = ['MyException']
```

## Feature flags

Use feature flags in your Rails app:

Ruby

PostHog AI

```ruby
class PostsController < ApplicationController
  def show
    if PostHog.is_feature_enabled('new-post-design', current_user.id)
      render 'posts/show_new'
    else
      render 'posts/show'
    end
  end
end
```

For local evaluation, ensure you've set `personal_api_key`:

Ruby

PostHog AI

```ruby
config.personal_api_key = Rails.application.credentials.posthog[:personal_api_key]
```

See our [Ruby SDK docs](/docs/libraries/ruby.md#local-evaluation) for details on local evaluation with Puma and Unicorn servers.

## Testing

In your test environment, disable PostHog or use test mode:

config/environments/test.rb

PostHog AI

```ruby
PostHog.init do |config|
  config.test_mode = true  # Events are queued but not sent
end
```

Or in your specs:

spec/rails\_helper.rb

PostHog AI

```ruby
RSpec.configure do |config|
  config.before(:each) do
    allow(PostHog).to receive(:capture)
  end
end
```

## Configuration reference

### Core PostHog options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| api_key | String | required | Your PostHog project token |
| host | String | https://us.i.posthog.com | PostHog instance URL |
| personal_api_key | String | nil | For feature flag evaluation |
| test_mode | Boolean | false | Don't send events (for testing) |
| on_error | Proc | nil | Error callback |

### Rails-specific options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| auto_capture_exceptions | Boolean | false | Automatically capture exceptions |
| report_rescued_exceptions | Boolean | false | Report exceptions Rails rescues |
| auto_instrument_active_job | Boolean | false | Instrument ActiveJob |
| capture_user_context | Boolean | true | Include user info |
| current_user_method | Symbol | :current_user | Controller method for user |
| user_id_method | Symbol | nil | Method to extract ID from user object |
| excluded_exceptions | Array | [] | Additional exceptions to ignore |

## Troubleshooting

### Exceptions not being captured

1.  Verify PostHog is initialized:

    Ruby

    PostHog AI

    ```ruby
    Rails.console
    > PostHog.initialized?
    => true
    ```

2.  Check your excluded exceptions list

3.  Verify middleware is installed:

    Ruby

    PostHog AI

    ```ruby
    Rails.application.middleware
    ```

### User context not working

1.  Verify `current_user_method` matches your controller method
2.  Check that the user object responds to `posthog_distinct_id`, `distinct_id`, or `id`
3.  If using a custom identifier, set `PostHog::Rails.config.user_id_method = :your_method`

### Feature flags not working

Ensure you've set `personal_api_key` in your configuration.

## Next steps

For any technical questions for how to integrate specific PostHog features into Rails (such as analytics, feature flags, A/B testing, etc.), have a look at our [Ruby SDK docs](/docs/libraries/ruby.md).

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better