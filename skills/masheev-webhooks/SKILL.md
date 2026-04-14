---
name: masheev-webhooks
description: >-
  Use when setting up, verifying, or handling Masheev webhook events in your
  backend. Covers creating webhook subscriptions, HMAC-SHA256 signature
  verification with timingSafeEqual, raw body preservation before JSON parsing,
  idempotent event handling, retry logic, and all 11 event types
  (conversation.created, message.received, contact.updated, etc.). Use this
  skill whenever someone asks to "handle Masheev events", "set up webhooks",
  "verify webhook signatures", or wants real-time notifications from Masheev.
  Also use when debugging webhook delivery failures or missed events.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Webhooks

Receive real-time HTTP callbacks when events happen in Masheev. Every webhook is signed with HMAC-SHA256 so you can verify it came from Masheev.

## Quick Start

### 1. Create a Webhook (Dashboard or API)

Via the Masheev dashboard: **Settings > Developers > Webhooks > Create webhook**

Or via API:

```typescript
import { apiClient } from "@masheev/client/server";

await apiClient.webhooks.create.mutate({
  orgId: "org_...",
  name: "My App Events",
  url: "https://myapp.com/api/webhooks/masheev",
  events: ["conversation.created", "message.received", "contact.updated"],
});
```

### 2. Handle and Verify the Webhook

```typescript
// Next.js App Router — app/api/webhooks/masheev/route.ts
import crypto from "node:crypto";

const WEBHOOK_SECRET = process.env.MASHEEV_WEBHOOK_SECRET!;

export async function POST(request: Request) {
  // Step 1: Get raw body BEFORE parsing JSON
  const rawBody = await request.text();
  const signature = request.headers.get("x-webhook-signature");

  if (!signature) {
    return new Response("Missing signature", { status: 401 });
  }

  // Step 2: Verify HMAC-SHA256 signature
  const expected = crypto
    .createHmac("sha256", WEBHOOK_SECRET)
    .update(rawBody)
    .digest("hex");

  const isValid = crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected),
  );

  if (!isValid) {
    return new Response("Invalid signature", { status: 401 });
  }

  // Step 3: Parse and handle the event
  const event = JSON.parse(rawBody);

  switch (event.type) {
    case "message.received":
      await handleNewMessage(event.payload);
      break;
    case "conversation.created":
      await handleNewConversation(event.payload);
      break;
    case "contact.updated":
      await handleContactUpdate(event.payload);
      break;
  }

  // Step 4: Return 200 quickly (Masheev retries on non-2xx)
  return new Response("OK", { status: 200 });
}
```

## Signature Verification

Every webhook includes an `x-webhook-signature` header containing the HMAC-SHA256 hex digest of the raw request body.

**Correct** (timing-safe comparison):
```typescript
const expected = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
const isValid = crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
```

**Wrong** (vulnerable to timing attacks):
```typescript
// NEVER do this
if (signature === expected) { ... }
```

**Wrong** (body already parsed — signature won't match):
```typescript
// NEVER do this — JSON.stringify reorders keys, changes whitespace
const body = await request.json();
const rawBody = JSON.stringify(body); // This is NOT the original raw body
```

### Framework-Specific Raw Body Access

| Framework | Raw Body Access |
|-----------|----------------|
| Next.js App Router | `await request.text()` |
| Next.js Pages Router | Set `config.api.bodyParser = false`, read `req` as stream |
| Express | `app.use("/webhooks", express.raw({ type: "application/json" }))` |
| Hono | `await c.req.text()` |
| Fastify | `fastify.addContentTypeParser("application/json", { parseAs: "string" }, ...)` |

See [references/frameworks.md](./references/frameworks.md) for complete examples in each framework.

## Event Types

| Event | Trigger | Key Payload Fields |
|-------|---------|--------------------|
| `conversation.created` | New conversation started | `conversationId`, `contactId`, `inboxId`, `channel` |
| `conversation.updated` | Status, priority, or assignment changed | `conversationId`, `status`, `priority`, `assigneeId` |
| `conversation.closed` | Conversation resolved | `conversationId`, `resolvedAt`, `outcome` |
| `conversation.assigned` | Assigned to agent or AI | `conversationId`, `assigneeType`, `assigneeId` |
| `message.received` | Message from contact | `messageId`, `conversationId`, `role: "contact"`, `content` |
| `message.sent` | Message sent by agent or AI | `messageId`, `conversationId`, `role`, `content`, `status` |
| `message.failed` | Message delivery failed | `messageId`, `conversationId`, `status: "failed"`, `error` |
| `contact.created` | New contact identified | `contactId`, `name`, `email`, `phone` |
| `contact.updated` | Contact info changed | `contactId`, changed fields |
| `escalation.created` | Conversation escalated to human | `escalationId`, `conversationId`, `reason` |
| `escalation.resolved` | Escalation handled | `escalationId`, `conversationId`, `status: "resolved"` |

See [references/events.md](./references/events.md) for complete payload schemas.

## Webhook Payload Format

Every webhook delivery has this shape:

```typescript
{
  id: string;          // Unique event ID (for idempotency)
  type: string;        // e.g., "conversation.created"
  timestamp: number;   // Unix ms
  payload: { ... };    // Event-specific data
}
```

## Idempotent Handling

Masheev may deliver the same event more than once (retries on timeout/error). Use the `id` field to deduplicate:

```typescript
// Simple in-memory dedup (use Redis/DB for production)
const processed = new Set<string>();

async function handleWebhook(event: WebhookEvent) {
  if (processed.has(event.id)) return; // Already handled
  processed.add(event.id);

  // Process the event...
}
```

## Retry Behavior

- Masheev retries on non-2xx responses and timeouts
- Retry schedule: 1 min, 5 min, 30 min, 2 hours, 24 hours
- Webhooks are paused after 7 consecutive days of failures
- Respond with 200 within 30 seconds to avoid timeout retries

## Testing Webhooks

```bash
# Test delivery from the Masheev dashboard
# Settings > Developers > Webhooks > [your webhook] > Send Test

# Or via API
await apiClient.webhooks.test.mutate({
  id: "wh_...",
  orgId: "org_...",
});
```

For local development, use a tunnel:

```bash
# ngrok
ngrok http 3000

# Then update your webhook URL to the ngrok URL
```

## Managing Webhooks

```typescript
// List all webhooks
const webhooks = await apiClient.webhooks.list.query({ orgId: "org_..." });

// Update events
await apiClient.webhooks.update.mutate({
  id: "wh_...",
  orgId: "org_...",
  events: ["message.received", "message.sent"],
});

// Rotate the signing secret
await apiClient.webhooks.regenerateSecret.mutate({
  id: "wh_...",
  orgId: "org_...",
});

// Delete
await apiClient.webhooks.delete.mutate({ id: "wh_...", orgId: "org_..." });
```
