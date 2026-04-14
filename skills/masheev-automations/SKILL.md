---
name: masheev-automations
description: >-
  Use when building automation rules and workflows in Masheev. Covers
  triggers (conversation.created, message.created, SLA breach, time-based),
  conditions (equals, contains, greater_than), and actions (set status,
  assign, add labels, send responses, trigger AI, webhook calls,
  notifications). Also covers the workflow builder with AI invoke steps,
  action steps, conditional steps, and delay steps. Use this skill when
  someone asks to "automate conversations", "set up rules", "auto-assign",
  "auto-resolve", "trigger AI", or "build a workflow" in Masheev.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Automations

Automations run server-side rules that react to events in Masheev. They consist of triggers, conditions, and actions.

## Quick Start

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
    { type: "assign_to", assigneeType: "agent", assigneeId: "agt_..." },
    { type: "add_label", labelId: "label_vip" },
  ],
});
```

## Triggers

| Trigger | When |
|---------|------|
| `conversation.created` | New conversation starts |
| `conversation.updated` | Conversation status/priority/assignment changes |
| `conversation.assigned` | Conversation assigned to agent/AI |
| `message.created` | New message in any conversation |
| `sla.warning` | SLA warning threshold reached |
| `sla.breach` | SLA breached |
| `time.schedule` | Cron-based scheduled trigger |

## Conditions

| Operator | Description | Example |
|----------|-------------|---------|
| `equals` | Exact match | `channel equals "whatsapp"` |
| `not_equals` | Not equal | `status not_equals "resolved"` |
| `contains` | String contains | `content contains "urgent"` |
| `matches` | Regex match | `email matches "@enterprise.com$"` |
| `greater_than` | Numeric comparison | `messageCount greater_than 10` |
| `less_than` | Numeric comparison | `priority less_than "high"` |
| `is_set` | Field has a value | `assigneeId is_set` |

## Actions

| Action | Description |
|--------|-------------|
| `set_status` | Change conversation status (open, pending, resolved) |
| `set_priority` | Set priority (low, medium, high, urgent) |
| `assign_to` | Assign to agent, AI, or unassign |
| `add_label` / `remove_label` | Tag management |
| `send_canned_response` | Send a pre-written message |
| `send_template` | Send a channel template (WhatsApp, email) |
| `add_note` | Add internal note |
| `snooze` | Snooze conversation for a duration |
| `trigger_ai` | Hand to AI agent |
| `stop_ai` | Take back from AI |
| `webhook` | Call external URL (GET/POST with headers/payload) |
| `notify` | Send notification (email, Slack, in-app) |

## Managing Automations

```typescript
// List
const rules = await apiClient.automations.list.query({});

// Activate/deactivate
await apiClient.automations.activate.mutate({ id: "rule_...", active: false });

// View execution history
const runs = await apiClient.automations.listRuns.query({ automationId: "rule_..." });

// Pre-built templates
const templates = await apiClient.automations.listTemplates.query();
```

## Workflow Builder

For complex multi-step automations, use the workflow builder (see masheev-workflows skill for client-side workflows). Server-side workflows support:

- **AI invoke steps** — Generate text/objects with tools
- **Action steps** — Execute platform skills
- **Conditional steps** — Branch based on conversation state
- **Delay steps** — Wait before next action

See [references/templates.md](./references/templates.md) for pre-built automation templates.
