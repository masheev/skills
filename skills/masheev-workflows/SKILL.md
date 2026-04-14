---
name: masheev-workflows
description: >-
  Use when building multi-step conversational workflows with Masheev. Covers
  WorkflowConfig, WorkflowStepConfig, step definitions with instructions
  and tool scoping, context interpolation with {{context.KEY}}, step
  completion events, resume logic, session modes, and A/B testing with
  variants. Use this skill when someone wants to build a "conversational
  flow", "onboarding wizard", "guided conversation", "multi-step form",
  or asks about sessionMode "workflow" in @masheev/embed-sdk.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Workflows

Workflows are multi-step conversational flows where the AI agent follows a script. Each step has instructions, optional tools, and collects structured data before advancing.

## Quick Start

```typescript
import { init } from "@masheev/embed-sdk/js";

init({
  inboxId: "YOUR_INBOX_ID",
  sessionMode: "workflow",
  workflow: {
    id: "booking_flow",
    name: "Restaurant Booking",
    steps: [
      {
        id: "greeting",
        name: "Welcome",
        instructions: "Greet {{context.customerName}} and ask what date they'd like to book.",
      },
      {
        id: "select_date",
        name: "Date Selection",
        instructions: "Help them pick a date and time. Use check_availability to show open slots.",
        tools: ["check_availability"],
      },
      {
        id: "confirm",
        name: "Confirmation",
        instructions: "Summarize the booking details and confirm. Use create_booking to finalize.",
        tools: ["create_booking"],
      },
    ],
    context: {
      customerName: "Jane",
      partySize: 4,
    },
  },
});
```

## WorkflowConfig

```typescript
interface WorkflowConfig {
  id: string;                 // Unique ID (alphanumeric + _ -), max 64 chars
  name?: string;              // Display name, max 100 chars
  steps?: WorkflowStepConfig[];  // Ordered steps, max 20
  resumeAtStep?: string;      // Step ID to resume returning users at
  context?: Record<string, string | number | boolean>;  // Max 20 keys, 500 chars/value
  variant?: string;           // A/B test variant name
}
```

## WorkflowStepConfig

```typescript
interface WorkflowStepConfig {
  id: string;                 // Step ID (alphanumeric + _ -), max 64 chars
  name: string;               // Display name, max 100 chars
  instructions?: string;      // AI instructions, max 1000 chars
  allowSkip?: boolean;        // Can the AI skip this step?
  tools?: string[];           // Tool names available in this step only
}
```

## Context Interpolation

Use `{{context.KEY}}` in step instructions to inject dynamic data:

```typescript
{
  id: "personalized_greeting",
  name: "Greeting",
  instructions: "Welcome {{context.customerName}}! They are on the {{context.plan}} plan with {{context.credits}} credits remaining.",
}
```

Context can be updated mid-conversation:

```typescript
import { updateWorkflow } from "@masheev/embed-sdk/js";

updateWorkflow({
  context: { credits: 42, lastAction: "viewed_pricing" },
});
```

## Step Completion Events

Listen for step and workflow completion:

```typescript
import { on } from "@masheev/embed-sdk/js";

on("workflow:stepComplete", ({ workflowId, stepId, data }) => {
  console.log(`Step ${stepId} completed with data:`, data);
  // data contains structured output from the step
});

on("workflow:complete", ({ workflowId, outcome, data }) => {
  console.log(`Workflow ${workflowId} finished: ${outcome}`);
  // outcome: "completed", "abandoned", etc.
});
```

## Session Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `"persistent"` | Conversations resume across page loads | General support chat |
| `"ephemeral"` | Fresh conversation each visit | Anonymous feedback |
| `"workflow"` | Workflow-driven, follows defined steps | Guided flows, onboarding |

## Tool Scoping

Tools listed in a step's `tools` array are only available during that step. This prevents the AI from using booking tools during the greeting step:

```typescript
steps: [
  { id: "greet", name: "Greeting", instructions: "..." },
  // No tools — AI can only chat
  
  { id: "search", name: "Search", instructions: "...", tools: ["search_products"] },
  // Only search_products available
  
  { id: "checkout", name: "Checkout", instructions: "...", tools: ["create_order", "apply_discount"] },
  // Only create_order and apply_discount available
]
```

## Resume Logic

For returning users, set `resumeAtStep` to skip completed steps:

```typescript
// Check user's progress from your backend
const progress = await getWorkflowProgress(userId);

init({
  inboxId: "...",
  sessionMode: "workflow",
  workflow: {
    id: "onboarding",
    resumeAtStep: progress.lastCompletedStep,
    steps: [...],
    context: progress.collectedData,
  },
});
```

## A/B Testing

Use `variant` to test different workflow configurations:

```typescript
const variant = Math.random() > 0.5 ? "short" : "detailed";

init({
  inboxId: "...",
  sessionMode: "workflow",
  workflow: {
    id: "signup_flow",
    variant,
    steps: variant === "short"
      ? [{ id: "quick", name: "Quick Signup", instructions: "..." }]
      : [
          { id: "step1", name: "Details", instructions: "..." },
          { id: "step2", name: "Preferences", instructions: "..." },
          { id: "step3", name: "Confirm", instructions: "..." },
        ],
  },
});
```

Track which variant performed better via `workflow:complete` events.

See [references/step-types.md](./references/step-types.md) for common workflow patterns (lead qualification, booking, support triage, onboarding).
