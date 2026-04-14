# Built-In Platform Tools

Built-in tools are available to every AI agent by default. They execute server-side within the Masheev platform.

## Tool Reference

### resolve_conversation

Mark the current conversation as resolved.

```typescript
// AI decides to call this when the issue is fully handled
{
  name: "resolve_conversation",
  parameters: {
    resolution?: string;    // Brief resolution summary
    outcome?: string;       // "resolved" | "no_action_needed" | "duplicate"
  }
}
```

**When the AI uses it**: After confirming the customer's issue is fully addressed, or when the customer says "thanks, that's all."

**What happens**: Conversation status changes to `resolved`. Fires `conversation.closed` webhook. Customer sees a satisfaction survey if enabled.

### set_priority

Set the priority level of the current conversation.

```typescript
{
  name: "set_priority",
  parameters: {
    priority: "low" | "medium" | "high" | "urgent";
    reason?: string;       // Why the priority was changed
  }
}
```

**When the AI uses it**: Based on the nature of the issue — billing problems default to `high`, general questions to `low`, service outages to `urgent`.

**What happens**: Updates conversation priority. If automations are configured for priority changes, they fire (e.g., urgent conversations notify the on-call team).

### assign_to_human

Route the conversation to a human agent or team.

```typescript
{
  name: "assign_to_human",
  parameters: {
    reason: string;            // Why the AI is escalating
    teamId?: string;           // Specific team (e.g., "team_billing")
    agentId?: string;          // Specific agent (e.g., "agt_jane")
    priority?: "low" | "medium" | "high" | "urgent";
    preserveContext?: boolean; // Include AI conversation summary (default: true)
  }
}
```

**When the AI uses it**: When escalation rules in the system prompt are triggered — customer frustration, complex issues, sensitive requests.

**What happens**:
1. Conversation is assigned to the specified agent/team (or round-robin if neither specified)
2. AI sends a handoff message: "I'm connecting you with a team member who can help."
3. Internal note is added with the AI's context summary (if `preserveContext: true`)
4. Fires `conversation.assigned` and `escalation.created` webhooks
5. AI stops responding until the conversation is reassigned back

### send_message

Send a message in the conversation. The AI uses this implicitly for every response, but it can also be called explicitly for structured output.

```typescript
{
  name: "send_message",
  parameters: {
    content: string;           // Message text (markdown supported)
    components?: {
      quickReplies?: { label: string; value: string }[];
      card?: {
        title: string;
        subtitle?: string;
        imageUrl?: string;
        fields?: { label: string; value: string }[];
        actions?: { label: string; url: string }[];
      };
    };
    internal?: boolean;        // If true, sends as internal note (not visible to contact)
  }
}
```

**When the AI uses it explicitly**: To send rich components (cards, quick replies) or internal notes alongside a response.

### report_conversation_status

Report the AI's assessment of the conversation for analytics and routing.

```typescript
{
  name: "report_conversation_status",
  parameters: {
    sentiment: "positive" | "neutral" | "negative";
    resolutionStatus: "resolved" | "in_progress" | "stuck" | "escalation_needed";
    effortLevel: "low" | "medium" | "high";
    topics?: string[];         // Detected topics (e.g., ["billing", "refund"])
    summary?: string;          // Brief conversation summary
  }
}
```

**When the AI uses it**: Periodically during the conversation or at the end. Masheev prompts the AI to report after every 5 exchanges.

**What happens**: Data is stored on the conversation record and surfaced in Dashboard analytics. Automations can trigger on sentiment or status changes.

## Tool Calling Flow

```
1. Customer sends message
2. Masheev sends message + conversation context + available tools to AI
3. AI decides whether to use a tool
   ├── No tool needed → AI responds with text
   └── Tool needed → AI returns tool call request
4. Masheev executes the tool server-side
5. Tool result is sent back to the AI
6. AI incorporates the result into its response
7. Response is sent to the customer
```

For client-side tools, step 4 is different: Masheev sends the tool call to the browser SDK, which executes it locally and returns the result.

## How Tools Are Auto-Selected

The AI selects tools based on:

1. **Tool name and description** — Clear, descriptive names lead to better selection. `check_order_status` is better than `query_db`.
2. **System prompt instructions** — Explicit rules like "Use check_availability before suggesting times" guide tool selection.
3. **Conversation context** — If the customer asks "where is my order?", the AI infers it should use an order-lookup tool.
4. **Workflow step scoping** — In workflow mode, only tools listed in the current step's `tools` array are available.

## Configuring Built-In Tools

Disable specific built-in tools per AI agent in the dashboard:

**Settings > AI Agents > [Agent] > Tools > Built-In**

Or via API:

```typescript
await apiClient.aiAgents.update.mutate({
  id: "agent_...",
  disabledBuiltInTools: ["resolve_conversation"],
  // This agent cannot auto-resolve — human must close conversations
});
```

## Tool Execution Limits

| Limit | Value |
|-------|-------|
| Max tool calls per AI turn | 5 |
| Max sequential tool calls per conversation | 20 |
| Tool execution timeout (built-in) | 10 seconds |
| Tool execution timeout (client) | 60 seconds |
| Tool execution timeout (integration) | 30 seconds |

If a tool times out, the AI receives an error result and can retry or inform the customer.

## Integration Tools

Integration tools connect to third-party services via adapters:

```typescript
// Configured in Dashboard > Integrations
// Available tools depend on the integration type:

// Google Calendar → check_availability, create_event, cancel_event
// Tableport → search_records, get_record, update_record
// Google Reviews → get_reviews, reply_to_review
```

Integration tools are configured per inbox and execute server-side. The AI agent sees them alongside built-in tools.
