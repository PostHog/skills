# Ruby on Rails error tracking installation - Docs

1.  1

    ## Install the gems

    Required

    Add the `posthog-ruby` and `posthog-rails` gems to your Gemfile:

    Gemfile

    PostHog AI

    ```ruby
    gem "posthog-ruby"
    gem "posthog-rails"
    ```

    Then run:

    Terminal

    PostHog AI

    ```bash
    bundle install
    ```

2.  2

    ## Generate the initializer

    Required

    Run the install generator to create the PostHog initializer:

    Terminal

    PostHog AI

    ```bash
    rails generate posthog:install
    ```

    This will create `config/initializers/posthog.rb` with sensible defaults and documentation.

3.  3

    ## Configure PostHog

    Required

    Update `config/initializers/posthog.rb` with your project token and host:

    config/initializers/posthog.rb

    PostHog AI

    ```ruby
    PostHog.init do |config|
      config.api_key = '<ph_project_token>'
      config.host = 'https://us.i.posthog.com'
    end
    ```

4.  4

    ## Send events

    Recommended

    Once installed, you can manually send events to test your integration:

    Ruby

    PostHog AI

    ```ruby
    PostHog.capture({
        distinct_id: 'user_123',
        event: 'button_clicked',
        properties: {
            button_name: 'signup'
        }
    })
    ```

5.  5

    ## Configure error tracking

    Required

    Update `config/initializers/posthog.rb` to enable automatic exception capture:

    config/initializers/posthog.rb

    PostHog AI

    ```ruby
    PostHog::Rails.configure do |config|
      config.auto_capture_exceptions = true
      config.report_rescued_exceptions = true
      config.auto_instrument_active_job = true
      config.capture_user_context = true
      config.current_user_method = :current_user
    end
    ```

6.  6

    ## Automatic exception capture

    Recommended

    With `auto_capture_exceptions` enabled, exceptions are automatically captured from your controllers:

    app/controllers/posts\_controller.rb

    PostHog AI

    ```ruby
    class PostsController < ApplicationController
      def show
        @post = Post.find(params[:id])
        # Any exception here is automatically captured
      end
    end
    ```

7.  7

    ## Background jobs

    Optional

    When `auto_instrument_active_job` is enabled, ActiveJob exceptions are automatically captured:

    app/jobs/email\_job.rb

    PostHog AI

    ```ruby
    class EmailJob < ApplicationJob
      def perform(user_id)
        user = User.find(user_id)
        UserMailer.welcome(user).deliver_now
        # Exceptions are automatically captured with job context
      end
    end
    ```

8.  8

    ## Manually capture exceptions

    Optional

    You can also manually capture exceptions that you handle in your application:

    Ruby

    PostHog AI

    ```ruby
    PostHog.capture_exception(
      exception,
      current_user.id,
      { custom_property: 'value' }
    )
    ```

9.  ## Verify error tracking

    Recommended

    *Confirm events are being sent to PostHog*

    Before proceeding, let's make sure exception events are being captured and sent to PostHog. You should see events appear in the activity feed.

    ![Activity feed with events](https://res.cloudinary.com/dmukukwp6/image/upload/SCR_20250729_ouxl_f788dd8cd2.png)![Activity feed with events](https://res.cloudinary.com/dmukukwp6/image/upload/SCR_20250729_owae_7c3490822c.png)

    [Check for exceptions in PostHog](https://app.posthog.com/activity/explore)

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better