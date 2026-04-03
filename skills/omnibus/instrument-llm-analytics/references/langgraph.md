# LangGraph LLM analytics installation - Docs

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

    ## Install LangGraph

    Required

    Install LangGraph and LangChain. PostHog instruments your LLM calls through LangChain-compatible callback handlers that LangGraph supports.

    PostHog AI

    ### Python

    ```bash
    pip install langgraph langchain-openai
    ```

    ### Node

    ```bash
    npm install @langchain/langgraph @langchain/openai @langchain/core
    ```

3.  3

    ## Initialize PostHog

    Required

    Initialize PostHog with your project token and host from [your project settings](https://app.posthog.com/settings/project), then create a LangChain `CallbackHandler`.

    PostHog AI

    ### Python

    ```python
    from posthog.ai.langchain import CallbackHandler
    from posthog import Posthog
    posthog = Posthog(
        "<ph_project_token>",
        host="https://us.i.posthog.com"
    )
    callback_handler = CallbackHandler(
        client=posthog,
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
    });
    ```

    **How this works**

    LangGraph is built on LangChain, so it supports LangChain-compatible callback handlers. PostHog's `CallbackHandler` captures `$ai_generation` events and trace hierarchy automatically without proxying your calls.

4.  4

    ## Run your graph

    Required

    Pass the `callback_handler` in the `config` when invoking your LangGraph graph. PostHog automatically captures generation events for each LLM call.

    PostHog AI

    ### Python

    ```python
    from langgraph.prebuilt import create_react_agent
    from langchain_openai import ChatOpenAI
    from langchain_core.tools import tool
    @tool
    def get_weather(city: str) -> str:
        """Get the weather for a given city."""
        return f"It's always sunny in {city}!"
    model = ChatOpenAI(api_key="your_openai_api_key")
    agent = create_react_agent(model, tools=[get_weather])
    result = agent.invoke(
        {"messages": [{"role": "user", "content": "What's the weather in Paris?"}]},
        config={"callbacks": [callback_handler]}
    )
    print(result["messages"][-1].content)
    ```

    ### Node

    ```typescript
    import { createReactAgent } from '@langchain/langgraph/prebuilt';
    import { ChatOpenAI } from '@langchain/openai';
    import { tool } from '@langchain/core/tools';
    import { z } from 'zod';
    const getWeather = tool(
      (input) => `It's always sunny in ${input.city}!`,
      {
        name: 'get_weather',
        description: 'Get the weather for a given city',
        schema: z.object({
          city: z.string().describe('The city to get the weather for'),
        }),
      }
    );
    const model = new ChatOpenAI({ apiKey: 'your_openai_api_key' });
    const agent = createReactAgent({ llm: model, tools: [getWeather] });
    const result = await agent.invoke(
      { messages: [{ role: 'user', content: "What's the weather in Paris?" }] },
      { callbacks: [callbackHandler] }
    );
    console.log(result.messages[result.messages.length - 1].content);
    phClient.shutdown();
    ```

    PostHog automatically captures `$ai_generation` events and creates a trace hierarchy based on how LangGraph components are nested. You can expect captured events to have the following properties:

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