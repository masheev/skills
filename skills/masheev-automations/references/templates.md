# Automation Templates

Pre-built automation templates with complete API calls.

## Auto-Assign VIP Contacts

Route enterprise customers to a dedicated support agent.

```typescript
import { apiClient } from "@masheev/client/server";

await apiClient.automations.create.mutate({
  name: "Auto-assign VIP contacts",
  trigger: "conversation.created",
  conditions: [
    { field: "contact.customAttributes.plan", operator: "equals", value: "enterprise" },
  ],
  actions: [
    { type: "set_priority", value: "high" },
    { type: "add_label", labelId: "label_vip" },
    { type: "assign_to", assigneeType: "agent", assigneeId: "agt_senior_support" },
    { type: "notify", channel: "slack", message: "VIP conversation from {{contact.name}} ({{contact.company}})" },
  ],
});
```

## Escalate After N Unanswered Messages

If a contact sends 3+ messages without a response, escalate.

```typescript
await apiClient.automations.create.mutate({
  name: "Escalate unanswered conversations",
  trigger: "message.created",
  conditions: [
    { field: "message.role", operator: "equals", value: "contact" },
    { field: "conversation.unansweredCount", operator: "greater_than", value: "2" },
    { field: "conversation.status", operator: "not_equals", value: "resolved" },
  ],
  actions: [
    { type: "set_priority", value: "urgent" },
    { type: "assign_to", assigneeType: "agent", assigneeId: "agt_team_lead" },
    { type: "add_note", content: "Auto-escalated: 3+ unanswered messages from contact." },
    { type: "notify", channel: "email", recipientId: "agt_team_lead", message: "Conversation {{conversation.id}} needs attention." },
  ],
});
```

## Auto-Resolve After Inactivity

Close conversations with no activity for 24 hours when status is `pending`.

```typescript
await apiClient.automations.create.mutate({
  name: "Auto-resolve inactive conversations",
  trigger: "time.schedule",
  schedule: "0 */6 * * *",  // Every 6 hours
  conditions: [
    { field: "conversation.status", operator: "equals", value: "pending" },
    { field: "conversation.lastActivityAt", operator: "less_than", value: "{{now - 24h}}" },
  ],
  actions: [
    { type: "send_canned_response", content: "It looks like this issue has been resolved. Feel free to reach out again anytime!" },
    { type: "set_status", value: "resolved" },
  ],
});
```

## Welcome Message for New Conversations

Greet every new conversation with an AI-generated message.

```typescript
await apiClient.automations.create.mutate({
  name: "Welcome message",
  trigger: "conversation.created",
  conditions: [
    { field: "conversation.channel", operator: "not_equals", value: "voice" },
  ],
  actions: [
    { type: "trigger_ai", instructions: "Send a brief, friendly welcome. Introduce yourself and ask how you can help. Keep it to 1-2 sentences." },
  ],
});
```

## SLA Breach Notification

Alert the team when a conversation approaches or breaches its SLA.

```typescript
// Warning (approaching breach)
await apiClient.automations.create.mutate({
  name: "SLA breach alert",
  trigger: "sla.warning",
  conditions: [],
  actions: [
    { type: "set_priority", value: "urgent" },
    { type: "add_label", labelId: "label_sla_risk" },
    { type: "notify", channel: "slack", message: "SLA warning: {{conversation.id}} from {{contact.name}} will breach in {{sla.timeRemaining}}." },
    { type: "notify", channel: "email", recipientId: "{{conversation.assigneeId}}", message: "Respond to {{contact.name}} within {{sla.timeRemaining}}." },
  ],
});

// Breach (reassign to manager)
await apiClient.automations.create.mutate({
  name: "SLA breach escalation",
  trigger: "sla.breach",
  conditions: [],
  actions: [
    { type: "assign_to", assigneeType: "agent", assigneeId: "agt_manager" },
    { type: "add_note", content: "SLA breached. Escalated to manager. Original assignee: {{conversation.assigneeName}}." },
    { type: "notify", channel: "slack", message: "SLA BREACHED: {{conversation.id}} reassigned to manager." },
  ],
});
```

## After-Hours Auto-Reply

Send an automatic response outside business hours.

```typescript
await apiClient.automations.create.mutate({
  name: "After-hours auto-reply",
  trigger: "conversation.created",
  conditions: [
    { field: "time.hour", operator: "less_than", value: "9" },
    { field: "time.hour", operator: "greater_than", value: "17" },
    { field: "time.dayOfWeek", operator: "equals", value: "saturday" },
    { field: "time.dayOfWeek", operator: "equals", value: "sunday" },
  ],
  conditionLogic: "any",
  actions: [
    { type: "send_canned_response", content: "Thanks for reaching out! Our team is offline. Hours: Mon-Fri, 9 AM - 5 PM EST. We will reply next business day." },
    { type: "set_status", value: "pending" },
    { type: "snooze", until: "next_business_day_9am" },
  ],
});
```

## Combining Templates

Automations run independently. Multiple can share the same trigger. Control execution order with `priority` (1-100, higher runs first):

```typescript
await apiClient.automations.create.mutate({
  name: "VIP routing (runs first)",
  trigger: "conversation.created",
  priority: 90,
  // ...
});

await apiClient.automations.create.mutate({
  name: "Welcome message (runs after routing)",
  trigger: "conversation.created",
  priority: 50,
  // ...
});
```

## Managing Automations

```typescript
// List all
const rules = await apiClient.automations.list.query({});

// Deactivate without deleting
await apiClient.automations.activate.mutate({ id: "rule_...", active: false });

// View run history
const runs = await apiClient.automations.listRuns.query({ automationId: "rule_...", limit: 50 });
```
