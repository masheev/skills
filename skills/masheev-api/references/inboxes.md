# Inboxes API

## List Inboxes

```typescript
const inboxes = await apiClient.inboxes.list.query({});
```

## Get Inbox

```typescript
const inbox = await apiClient.inboxes.get.query({ id: "inb_..." });
```

## Create Inbox

```typescript
const inbox = await apiClient.inboxes.create.mutate({
  name: "Website Chat",
  channel: "chat",           // "chat" | "whatsapp" | "sms" | "email" | "voice" | "instagram" | "google_reviews"
});
```

## Update Inbox

```typescript
await apiClient.inboxes.update.mutate({
  id: "inb_...",
  name: "Updated Name",
  status: "active",           // "active" | "paused" | "disabled"
  aiAgentId: "aia_...",       // Assign an AI agent
});
```

## Delete Inbox

```typescript
await apiClient.inboxes.delete.mutate({ id: "inb_..." });
```

## Inbox Schema

```typescript
interface Inbox {
  id: string;                  // "inb_..."
  orgId: string;
  name: string;
  channel: Channel;
  status: "active" | "paused" | "disabled";
  aiAgentId?: string;          // Assigned AI agent
  greeting?: string;           // Welcome message for new conversations
  disclosure?: string;         // AI disclosure text (GDPR / AI Act compliance)
  theme?: WidgetTheme;         // Widget appearance settings
  createdAt: string;
  updatedAt: string;
}
```
