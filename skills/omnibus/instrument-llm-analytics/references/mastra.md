# Mastra LLM analytics installation - Docs

1.  1

    ## Install the PostHog SDK

    Required

    Setting up analytics starts with installing the PostHog SDK.

    ```bash
    npm install @posthog/ai posthog-node
    ```

2.  2

    ## Install Mastra

    Required

    Install Mastra and a model provider SDK. Mastra uses the Vercel AI SDK under the hood, so you can use any Vercel AI-compatible model provider.

    ```bash
    npm install @mastra/core @ai-sdk/openai
    ```

    **Proxy note**

    These SDKs **do not** proxy your calls. They only fire off an async call to PostHog in the background to send the data. You can also use LLM analytics with other SDKs or our API, but you will need to capture the data in the right format. See the schema in the [manual capture section](/docs/llm-analytics/installation/manual-capture.md) for more details.

3.  3

    ## Initialize PostHog and wrap your model

    Required

    Initialize PostHog with your project token and host from [your project settings](https://app.posthog.com/settings/project), then use `withTracing` from `@posthog/ai` to wrap the model you pass to your Mastra agent.

    ```typescript
    import { Agent } from "@mastra/core/agent";
    import { PostHog } from "posthog-node";
    import { withTracing } from "@posthog/ai";
    import { createOpenAI } from "@ai-sdk/openai";
    const phClient = new PostHog(
      '<ph_project_token>',
      { host: 'https://us.i.posthog.com' }
    );
    const openaiClient = createOpenAI({
      apiKey: 'your_openai_api_key',
      compatibility: 'strict'
    });
    const agent = new Agent({
      name: "my-agent",
      instructions: "You are a helpful assistant.",
      model: withTracing(openaiClient("gpt-4o"), phClient, {
        posthogDistinctId: "user_123", // optional
        posthogTraceId: "trace_123", // optional
        posthogProperties: { conversationId: "abc123" }, // optional
        posthogPrivacyMode: false, // optional
        posthogGroups: { company: "companyIdInYourDb" }, // optional
      }),
    });
    ```

    You can enrich LLM events with additional data by passing parameters such as the trace ID, distinct ID, custom properties, groups, and privacy mode options.

4.  4

    ## Use your Mastra agent

    Required

    Now, when your Mastra agent makes LLM calls, PostHog automatically captures an `$ai_generation` event for each one.

    ```typescript
    const result = await agent.generate("What is the capital of France?");
    console.log(result.text);
    phClient.shutdown();
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