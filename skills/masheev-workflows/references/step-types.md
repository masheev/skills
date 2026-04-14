# Workflow Patterns

Complete `WorkflowConfig` examples for common conversational flows.

## Lead Qualification

Collect information, qualify the lead, and route to the right team.

```typescript
import { init } from "@masheev/embed-sdk/js";

init({
  inboxId: "YOUR_INBOX_ID",
  sessionMode: "workflow",
  workflow: {
    id: "lead_qualification",
    name: "Lead Qualification",
    steps: [
      {
        id: "greeting",
        name: "Welcome",
        instructions: "Greet the visitor warmly. Ask what brought them to our site and what they are looking for.",
      },
      {
        id: "collect_info",
        name: "Collect Info",
        instructions: "Collect naturally (not as a form): company name, role/title, team size, and primary use case (support, sales, marketing, or other). If they are reluctant, move on with what you have.",
      },
      {
        id: "qualify",
        name: "Qualify",
        instructions: "Team size 50+ and support/sales use case: connect with solutions engineer. Team 10-49: offer a demo. Under 10: recommend self-serve plan. Use set_priority for high-value leads.",
        tools: ["set_priority"],
      },
      {
        id: "handoff",
        name: "Handoff",
        instructions: "For qualified leads: use assign_to_human to route to sales. For self-serve: share the signup link and ask if they have questions.",
        tools: ["assign_to_human"],
      },
    ],
  },
});
```

## Restaurant Booking

Date, time, party size, then confirm the reservation.

```typescript
init({
  inboxId: "YOUR_INBOX_ID",
  sessionMode: "workflow",
  tools: [checkAvailability, createBooking],
  workflow: {
    id: "restaurant_booking",
    name: "Restaurant Booking",
    steps: [
      {
        id: "welcome",
        name: "Welcome",
        instructions: "Welcome the guest to {{context.restaurantName}}. Ask when they would like to dine and for how many people. Hours: {{context.hours}}.",
      },
      {
        id: "find_slot",
        name: "Find a Table",
        instructions: "Use check_availability with the date and party size. Present available slots. If nothing works, suggest nearby dates. Wait for the guest to pick a slot.",
        tools: ["check_availability"],
      },
      {
        id: "collect_details",
        name: "Guest Details",
        instructions: "Ask for name, phone number, and any dietary requirements or special requests.",
      },
      {
        id: "confirm",
        name: "Confirm Booking",
        instructions: "Summarize: date, time, party size, guest name, special requests. Use create_booking only after guest confirms.",
        tools: ["create_booking"],
      },
    ],
    context: { restaurantName: "Bella Tavola", hours: "Tue-Sun, 5:30 PM - 10:30 PM" },
  },
});
```

## Support Triage

Identify the issue, search knowledge base, escalate or resolve.

```typescript
init({
  inboxId: "YOUR_INBOX_ID",
  sessionMode: "workflow",
  workflow: {
    id: "support_triage",
    name: "Support Triage",
    steps: [
      {
        id: "identify",
        name: "Identify Issue",
        instructions: "Ask what they need help with. Classify into: billing, technical, account, or feature_request. Get to the core issue quickly.",
      },
      {
        id: "investigate",
        name: "Investigate",
        instructions: "Technical: ask for error messages and steps to reproduce. Billing: ask for invoice number. Account: ask for email. Search the knowledge base for relevant articles.",
      },
      {
        id: "resolve_or_escalate",
        name: "Resolve or Escalate",
        instructions: "If the knowledge base solved it and customer confirms, resolve. If human attention needed (billing disputes, unreproducible bugs, security), use assign_to_human with a summary. For feature requests, log via report_conversation_status.",
        tools: ["resolve_conversation", "assign_to_human", "report_conversation_status"],
      },
    ],
  },
});
```

## Onboarding Wizard

Welcome new users, collect preferences, walk through setup.

```typescript
init({
  inboxId: "YOUR_INBOX_ID",
  sessionMode: "workflow",
  tools: [updatePreferences, setupWorkspace],
  workflow: {
    id: "user_onboarding",
    name: "New User Onboarding",
    steps: [
      {
        id: "welcome",
        name: "Welcome",
        instructions: "Welcome {{context.userName}} to Masheev. Ask what they want to use it for: customer support, sales outreach, internal helpdesk, or other.",
      },
      {
        id: "preferences",
        name: "Preferences",
        instructions: "Ask about: preferred language, business hours (for auto-replies), and team size. Use update_preferences to save each preference.",
        tools: ["update_preferences"],
      },
      {
        id: "setup",
        name: "Setup",
        instructions: "Walk through initial setup: creating their first inbox. Ask which channel (chat widget, email, WhatsApp). Use setup_workspace to provision. Share the quick-start guide link.",
        tools: ["setup_workspace"],
      },
      {
        id: "complete",
        name: "Complete",
        instructions: "Congratulate them. Summarize what was configured. Next steps: embed widget, invite team, customize AI agent. Ask if they have questions, then resolve.",
        tools: ["resolve_conversation"],
      },
    ],
    context: { userName: "Jane" },
  },
});
```

## Step Design Best Practices

**Keep instructions under 200 words.** One step should do one thing well. If instructions exceed 200 words, split into two steps.

**Scope tools per step.** Only list relevant tools. This prevents the AI from jumping ahead (e.g., creating a booking before collecting details).

**Use context interpolation.** Pass customer name, plan, and data via `context` so the AI personalizes without asking.

**Make the first step low-friction.** Greet naturally. Do not ask for 5 pieces of information at once.

**Design for abandonment.** Use `resumeAtStep` so returning users continue where they left off:

```typescript
workflow: {
  id: "onboarding",
  resumeAtStep: savedProgress.lastStep,
  context: savedProgress.collectedData,
  steps: [...],
}
```

**Test with real conversations.** Run through as a customer. Adjust where the AI gets confused, repeats itself, or skips steps.
