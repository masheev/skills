# Conversations API

## List Conversations

```typescript
const result = await apiClient.conversations.list.query({
  status: "open",                    // Optional: "open" | "pending" | "snoozed" | "resolved"
  assigneeId: "agt_...",             // Optional: filter by assigned agent
  inboxId: "inb_...",               // Optional: filter by inbox
  priority: "high",                  // Optional: "low" | "medium" | "high" | "urgent"
  limit: 50,                         // Default: 50, max: 200
  cursor: undefined,                 // Cursor from previous page
});
// result: { items: Conversation[], nextCursor?: string }
```

## Get Conversation

```typescript
const conversation = await apiClient.conversations.get.query({
  id: "conv_...",
});
```

## Update Conversation

```typescript
await apiClient.conversations.update.mutate({
  id: "conv_...",
  status: "resolved",
  priority: "low",
  assigneeId: "agt_...",           // Assign to a specific agent
  labelIds: ["label_...", "label_..."],
});
```

## Batch Update

```typescript
await apiClient.conversations.batchUpdate.mutate({
  ids: ["conv_...", "conv_...", "conv_..."],
  status: "resolved",
});
```

## Archive Conversation

```typescript
await apiClient.conversations.archive.mutate({
  id: "conv_...",
});
```

## Conversation Schema

```typescript
interface Conversation {
  id: string;                      // "conv_..."
  orgId: string;
  inboxId: string;
  contactId: string;
  displayId: number;               // Human-readable #123
  subject?: string;
  status: "open" | "pending" | "snoozed" | "resolved";
  priority?: "low" | "medium" | "high" | "urgent";
  assigneeType: "ai" | "agent" | "unassigned";
  assigneeId?: string;
  channel: "voice" | "sms" | "whatsapp" | "chat" | "email" | "instagram" | "google_reviews";
  inbound: boolean;
  lastActivityAt: string;
  firstResponseAt?: string;
  resolvedAt?: string;
  labelIds: string[];
  messageCount: number;
  unreadCount: number;
  outcome?: string;
  outcomeData?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}
```
