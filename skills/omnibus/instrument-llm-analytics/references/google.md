# Google LLM analytics installation - Docs

1.  1

    ## Install the PostHog SDK

    Required

    Setting up analytics starts with installing the PostHog SDK for your language. LLM analytics works best with our Python and Node SDKs.

    PostHog AI

    ### Python

    ```bash
    pip install posthog
    ```

    ### Node

    ```bash
    npm install @posthog/ai posthog-node
    ```

2.  2

    ## Install the Google Gen AI SDK

    Required

    Install the Google Gen AI SDK. The PostHog SDK instruments your LLM calls by wrapping the Google Gen AI client. The PostHog SDK **does not** proxy your calls.

    PostHog AI

    ### Python

    ```bash
    pip install google-genai
    ```

    ### Node

    ```bash
    npm install @google/genai
    ```

    **Proxy note**

    These SDKs **do not** proxy your calls. They only fire off an async call to PostHog in the background to send the data. You can also use LLM analytics with other SDKs or our API, but you will need to capture the data in the right format. See the schema in the [manual capture section](/docs/llm-analytics/installation/manual-capture.md) for more details.

3.  3

    ## Initialize PostHog and Google Gen AI client

    Required

    Initialize PostHog with your project token and host from [your project settings](https://app.posthog.com/settings/project), then pass it to our Google Gen AI wrapper.

    PostHog AI

    ### Python

    ```python
    from posthog.ai.gemini import Client
    from posthog import Posthog
    posthog = Posthog(
        "<ph_project_token>",
        host="https://us.i.posthog.com"
    )
    client = Client(
        api_key="...", # Replace with your Gemini API key
        posthog_client=posthog # This is an optional parameter. If it is not provided, a default client will be used.
    )
    ```

    ### Node

    ```typescript
    import { GoogleGenAI } from '@posthog/ai'
    import { PostHog } from 'posthog-node'
    const phClient = new PostHog(
        '<ph_project_token>',
        { host: 'https://us.i.posthog.com' }
    )
    const client = new GoogleGenAI({
        apiKey: '...', // Replace with your Gemini API key
        posthog: phClient
    })
    ```

    > **Note:** This integration also works with Vertex AI via Google Cloud Platform. You can use the Google Gen AI SDK's Vertex AI client with PostHog analytics.

    **Vertex AI code example:**

    PostHog AI

    ### Python

    ```python
    from posthog import Posthog
    from posthog.ai.gemini import Client
    # Initialize PostHog
    posthog = Posthog(
        project_api_key="<ph_project_token>",
        host="https://us.i.posthog.com"
    )
    # Initialize Gemini client with Vertex AI
    client = Client(
        vertexai=True,
        project="your-gcp-project-id",
        location="us-central1",
        posthog_client=posthog,
        posthog_distinct_id="user-123"
    )
    # Use it
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=["Hello, world!"]
    )
    print(response.text)
    ```

    ### Node

    ```typescript
    import { PostHog } from 'posthog-node'
    import { PostHogGoogleGenAI } from '@posthog/ai'
    // Initialize PostHog
    const posthog = new PostHog(
      '<ph_project_token>',
      { host: 'https://us.i.posthog.com' }
    )
    // Initialize Gemini client with Vertex AI
    const client = new PostHogGoogleGenAI({
      vertexai: true,
      project: 'your-gcp-project-id',
      location: 'us-central1',
      posthog: posthog
    })
    // Use it
    const response = await client.models.generateContent({
      model: 'gemini-2.0-flash',
      contents: 'Hello, world!',
      posthogDistinctId: 'user-123'
    })
    console.log(response.text)
    ```

4.  4

    ## Call Google Gen AI LLMs

    Required

    Now, when you use the Google Gen AI SDK to call LLMs, PostHog automatically captures an `$ai_generation` event. You can enrich the event with additional data such as the trace ID, distinct ID, custom properties, groups, and privacy mode options.

    PostHog AI

    ### Python

    ```python
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=["Tell me a fun fact about hedgehogs"],
        posthog_distinct_id="user_123", # optional
        posthog_trace_id="trace_123", # optional
        posthog_properties={"conversation_id": "abc123", "paid": True}, # optional
        posthog_groups={"company": "company_id_in_your_db"},  # optional
        posthog_privacy_mode=False # optional
    )
    print(response.text)
    ```

    ### Node

    ```typescript
    const response = await client.models.generateContent({
      model: "gemini-2.5-flash",
      contents: ["Tell me a fun fact about hedgehogs"],
      posthogDistinctId: "user_123", // optional
      posthogTraceId: "trace_123", // optional
      posthogProperties: { conversationId: "abc123", paid: true }, // optional
      posthogGroups: { company: "company_id_in_your_db" }, // optional
      posthogPrivacyMode: false // optional
    })
    console.log(response.text)
    phClient.shutdown()
    ```

    > **Note:** If you want to capture LLM events anonymously, **don't** pass a distinct ID to the request. See our docs on [anonymous vs identified events](/docs/data/anonymous-vs-identified-events.md) to learn more.

    You can expect captured `$ai_generation` events to have the following properties:

    | Property | Description |
    | --- | --- |
    | $ai_model | The specific model, like gpt-5-mini or claude-4-sonnet |
    | $ai_latency | The latency of the LLM call in seconds |
    | $ai_time_to_first_token | Time to first token in seconds (streaming only) |
    | $ai_tools | Tools and functions available to the LLM |
    | $ai_input | List of messages sent to the LLM |
    | $ai_input_tokens | The number of tokens in the input (often found in response.usage) |
    | $ai_output_choices | List of response choices from the LLM |
    | $ai_output_tokens | The number of tokens in the output (often found in response.usage) |
    | $ai_total_cost_usd | The total cost in USD (input + output) |
    | [[...]](/docs/llm-analytics/generations.md#event-properties) | See [full list](/docs/llm-analytics/generations.md#event-properties) of properties |

5.  ## Verify traces and generations

    Recommended

    *Confirm LLM events are being sent to PostHog*

    Let's make sure LLM events are being captured and sent to PostHog. Under **LLM analytics**, you should see rows of data appear in the **Traces** and **Generations** tabs.

    ![LLM generations in PostHog](https://res.cloudinary.com/dmukukwp6/image/upload/SCR_20250807_syne_ecd0801880.png)![LLM generations in PostHog](https://res.cloudinary.com/dmukukwp6/image/upload/SCR_20250807_syjm_5baab36590.png)

    [Check for LLM events in PostHog](https://app.posthog.com/llm-analytics/generations)

6.  5

    ## Next steps

    Recommended

    Now that you're capturing AI conversations, continue with the resources below to learn what else LLM Analytics enables within the PostHog platform.

    | Resource | Description |
    | --- | --- |
    | [Basics](/docs/llm-analytics/basics.md) | Learn the basics of how LLM calls become events in PostHog. |
    | [Generations](/docs/llm-analytics/generations.md) | Read about the $ai_generation event and its properties. |
    | [Traces](/docs/llm-analytics/traces.md) | Explore the trace hierarchy and how to use it to debug LLM calls. |
    | [Spans](/docs/llm-analytics/spans.md) | Review spans and their role in representing individual operations. |
    | [Anaylze LLM performance](/docs/llm-analytics/dashboard.md) | Learn how to create dashboards to analyze LLM performance. |

### Community questions

Ask a question

### Was this page useful?

HelpfulCould be better