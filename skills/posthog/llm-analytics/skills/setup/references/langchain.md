# LangChain LLM analytics installation - Docs

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

    ## Install LangChain and OpenAI SDKs

    Required

    Install LangChain. The PostHog SDK instruments your LLM calls by wrapping LangChain. The PostHog SDK **does not** proxy your calls.

    PostHog AI

    ### Python

    ```bash
    pip install langchain openai langchain-openai
    ```

    ### Node

    ```bash
    npm install langchain @langchain/core @langchain/openai @posthog/ai
    ```

    **Proxy note**

    These SDKs **do not** proxy your calls. They only fire off an async call to PostHog in the background to send the data. You can also use LLM analytics with other SDKs or our API, but you will need to capture the data in the right format. See the schema in the [manual capture section](/docs/llm-analytics/installation/manual-capture.md) for more details.

3.  3

    ## Initialize PostHog and LangChain

    Required

    Initialize PostHog with your project token and host from [your project settings](https://app.posthog.com/settings/project), then pass it to the LangChain `CallbackHandler` wrapper. Optionally, you can provide a user distinct ID, trace ID, PostHog properties, [groups](/docs/product-analytics/group-analytics.md), and privacy mode.

    PostHog AI

    ### Python

    ```python
    from posthog.ai.langchain import CallbackHandler
    from langchain_openai import ChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from posthog import Posthog
    posthog = Posthog(
        "<ph_project_token>",
        host="https://us.i.posthog.com"
    )
    callback_handler = CallbackHandler(
        client=posthog, # This is an optional parameter. If it is not provided, a default client will be used.
        distinct_id="user_123", # optional
        trace_id="trace_456", # optional
        properties={"conversation_id": "abc123"}, # optional
        groups={"company": "company_id_in_your_db"}, # optional
        privacy_mode=False # optional
    )
    ```

    ### Node

    ```typescript
    import { PostHog } from 'posthog-node';
    import { LangChainCallbackHandler } from '@posthog/ai';
    import { ChatOpenAI } from '@langchain/openai';
    import { ChatPromptTemplate } from '@langchain/core/prompts';
    const phClient = new PostHog(
      '<ph_project_token>',
      { host: 'https://us.i.posthog.com' }
    );
    const callbackHandler = new LangChainCallbackHandler({
      client: phClient,
      distinctId: 'user_123', // optional
      traceId: 'trace_456', // optional
      properties: { conversationId: 'abc123' }, // optional
      groups: { company: 'company_id_in_your_db' }, // optional
      privacyMode: false, // optional
      debug: false // optional - when true, logs all events to console
    });
    ```

    > **Note:** If you want to capture LLM events anonymously, **don't** pass a distinct ID to the `CallbackHandler`. See our docs on [anonymous vs identified events](/docs/data/anonymous-vs-identified-events.md) to learn more.

4.  4

    ## Call LangChain

    Required

    When you invoke your chain, pass the `callback_handler` in the `config` as part of your `callbacks`:

    PostHog AI

    ### Python

    ```python
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful assistant."),
        ("user", "{input}")
    ])
    model = ChatOpenAI(openai_api_key="your_openai_api_key")
    chain = prompt | model
    # Execute the chain with the callback handler
    response = chain.invoke(
        {"input": "Tell me a joke about programming"},
        config={"callbacks": [callback_handler]}
    )
    print(response.content)
    ```

    ### Node

    ```typescript
    const prompt = ChatPromptTemplate.fromMessages([
      ["system", "You are a helpful assistant."],
      ["user", "{input}"]
    ]);
    const model = new ChatOpenAI({
      apiKey: "your_openai_api_key"
    });
    const chain = prompt.pipe(model);
    // Execute the chain with the callback handler
    const response = await chain.invoke(
      { input: "Tell me a joke about programming" },
      { callbacks: [callbackHandler] }
    );
    console.log(response.content);
    phClient.shutdown();
    ```

    PostHog automatically captures an `$ai_generation` event along with these properties:

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

    It also automatically creates a trace hierarchy based on how LangChain components are nested.

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