---
name: masheev-api
description: >-
  Use when calling the Masheev API for contacts, conversations, messages,
  inboxes, AI agents, knowledge base, or any server-to-server integration.
  Covers authentication with API keys, the @masheev/client tRPC client, REST
  endpoints, pagination, rate limiting, and common CRUD operations. Use this
  skill whenever someone asks to "call the Masheev API", "create contacts",
  "list conversations", "send messages", "manage inboxes", or integrate Masheev
  into their backend. Also use when setting up @masheev/client in Node.js,
  React, Next.js, or React Native.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev API

Server-side API for managing contacts, conversations, messages, inboxes, AI agents, and more. The API uses tRPC — install `@masheev/client` for type-safe access.

## Quick Start

```bash
npm install @masheev/client
```

### Server-Side (Node.js / API Routes)

```typescript
import { apiClient, authClient } from "@masheev/client/server";

// List conversations
const conversations = await apiClient.conversations.list.query({
  status: "open",
  limit: 20,
});

// Send a message
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  role: "agent",
  content: "Thanks for reaching out! Let me help with that.",
});
```

### React (Client-Side)

```typescript
import { apiClient, authClient } from "@masheev/client/react";

function ConversationList() {
  const { data } = apiClient.conversations.list.useQuery({ status: "open" });
  return data?.map((c) => <div key={c.id}>{c.subject}</div>);
}
```

### Next.js (TanStack Start)

```typescript
import { apiClient } from "@masheev/client/tanstack";
```

### React Native

```typescript
import { apiClient } from "@masheev/client/native";
```

## Authentication

The API uses session-based authentication via Better Auth. For server-to-server integrations, use API keys:

```typescript
// API key in Authorization header
fetch("https://api.masheev.com/api/...", {
  headers: {
    Authorization: "Bearer YOUR_API_KEY",
  },
});
```

Generate API keys in the Masheev dashboard: **Settings > Developers > API Keys**

## API Reference

Each domain is a separate reference file with full endpoint details, input schemas, and response types.

| Domain | Endpoints | Reference |
|--------|-----------|-----------|
| Contacts | list, get, create, update, merge, GDPR delete | [references/contacts.md](./references/contacts.md) |
| Conversations | list, get, update, batchUpdate, archive | [references/conversations.md](./references/conversations.md) |
| Messages | list, get, create | [references/messages.md](./references/messages.md) |
| Inboxes | list, get, create, update, delete | [references/inboxes.md](./references/inboxes.md) |
| AI Agents | list, get, create, update, delete | [references/ai-agents.md](./references/ai-agents.md) |
| Webhooks | list, create, update, delete, test, regenerateSecret | See masheev-webhooks skill |
| Knowledge | list, create, sync, delete, search | [references/knowledge.md](./references/knowledge.md) |
| Automations | list, get, create, update, delete, activate | [references/automations.md](./references/automations.md) |
| Billing | plans, balance, budget, topup, invoices | [references/billing.md](./references/billing.md) |
| Organization | list, get, update, inviteUser, removeUser | [references/org.md](./references/org.md) |

## Data Model

### Key Entities

| Entity | ID Prefix | Description |
|--------|-----------|-------------|
| Organization | `org_` | Your account / workspace |
| Inbox | `inb_` | A channel endpoint (chat, WhatsApp, email, etc.) |
| Contact | `con_` | A customer or visitor |
| Conversation | `conv_` | A thread between a contact and your team/AI |
| Message | `msg_` | A single message within a conversation |
| AI Agent | `aia_` | An AI agent configuration |
| Webhook | `wh_` | A webhook subscription |

### Common Enums

```typescript
type Channel = "voice" | "sms" | "whatsapp" | "chat" | "email" | "instagram" | "google_reviews";
type ConversationStatus = "open" | "pending" | "snoozed" | "resolved";
type Priority = "low" | "medium" | "high" | "urgent";
type MessageRole = "contact" | "ai" | "agent" | "system";
type MessageStatus = "pending" | "sent" | "delivered" | "read" | "failed";
type AssigneeType = "ai" | "agent" | "unassigned";
```

## Common Patterns

### Pagination

```typescript
// Cursor-based pagination
let cursor: string | undefined;
const allContacts = [];

do {
  const page = await apiClient.contacts.list.query({
    limit: 100,
    cursor,
  });
  allContacts.push(...page.items);
  cursor = page.nextCursor;
} while (cursor);
```

### Rate Limiting

The API enforces rate limits per IP and per user. When rate-limited, you receive a 429 response.

```typescript
async function withRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      if (error.data?.httpStatus === 429 && attempt < maxRetries - 1) {
        const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
        await new Promise((r) => setTimeout(r, delay));
        continue;
      }
      throw error;
    }
  }
  throw new Error("Max retries exceeded");
}
```

### Error Handling

tRPC errors include structured data:

```typescript
try {
  await apiClient.contacts.create.mutate({ ... });
} catch (error) {
  if (error instanceof TRPCClientError) {
    console.error(error.message);       // Human-readable message
    console.error(error.data?.code);    // "NOT_FOUND", "FORBIDDEN", etc.
    console.error(error.data?.zodError); // Validation errors (if input was invalid)
  }
}
```
