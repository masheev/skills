# Webhook Event Payloads

## Conversation Events

### conversation.created

```typescript
{
  id: string;
  type: "conversation.created";
  timestamp: number;
  payload: {
    conversationId: string;   // "conv_..."
    contactId: string;        // "con_..."
    inboxId: string;          // "inb_..."
    orgId: string;            // "org_..."
    channel: "voice" | "sms" | "whatsapp" | "chat" | "email" | "instagram" | "google_reviews";
    status: "open";
    assigneeType: "ai" | "agent" | "unassigned";
    assigneeId?: string;
    createdAt: string;        // ISO 8601
  };
}
```

### conversation.updated

```typescript
{
  id: string;
  type: "conversation.updated";
  timestamp: number;
  payload: {
    conversationId: string;
    status: "open" | "pending" | "snoozed" | "resolved";
    priority?: "low" | "medium" | "high" | "urgent";
    assigneeType?: "ai" | "agent" | "unassigned";
    assigneeId?: string;
    labelIds?: string[];
    updatedAt: string;
  };
}
```

### conversation.closed

```typescript
{
  id: string;
  type: "conversation.closed";
  timestamp: number;
  payload: {
    conversationId: string;
    contactId: string;
    resolvedAt: string;
    outcome?: string;          // "resolved_by_agent", "auto_resolved", etc.
    outcomeData?: Record<string, unknown>;
  };
}
```

### conversation.assigned

```typescript
{
  id: string;
  type: "conversation.assigned";
  timestamp: number;
  payload: {
    conversationId: string;
    assigneeType: "ai" | "agent" | "unassigned";
    assigneeId?: string;       // agent or AI agent ID
    previousAssigneeType?: string;
    previousAssigneeId?: string;
  };
}
```

## Message Events

### message.received

Fired when a contact sends a message.

```typescript
{
  id: string;
  type: "message.received";
  timestamp: number;
  payload: {
    messageId: string;         // "msg_..."
    conversationId: string;
    contactId: string;
    role: "contact";
    content: string;
    contentType: "text" | "attachment";
    attachments?: {
      id: string;
      type: "image" | "audio" | "video" | "file";
      name: string;
      mimeType: string;
      size: number;
      url: string;
    }[];
    createdAt: string;
  };
}
```

### message.sent

Fired when an agent or AI sends a message.

```typescript
{
  id: string;
  type: "message.sent";
  timestamp: number;
  payload: {
    messageId: string;
    conversationId: string;
    role: "ai" | "agent";
    senderId?: string;
    senderName?: string;
    content: string;
    status: "sent" | "delivered";
    createdAt: string;
  };
}
```

### message.failed

```typescript
{
  id: string;
  type: "message.failed";
  timestamp: number;
  payload: {
    messageId: string;
    conversationId: string;
    status: "failed";
    error?: string;
  };
}
```

## Contact Events

### contact.created

```typescript
{
  id: string;
  type: "contact.created";
  timestamp: number;
  payload: {
    contactId: string;         // "con_..."
    orgId: string;
    name?: string;
    email?: string;
    phone?: string;
    company?: string;
    customAttributes?: Record<string, unknown>;
    firstSeenAt: string;
  };
}
```

### contact.updated

```typescript
{
  id: string;
  type: "contact.updated";
  timestamp: number;
  payload: {
    contactId: string;
    name?: string;
    email?: string;
    phone?: string;
    company?: string;
    customAttributes?: Record<string, unknown>;
    updatedAt: string;
  };
}
```

## Escalation Events

### escalation.created

```typescript
{
  id: string;
  type: "escalation.created";
  timestamp: number;
  payload: {
    escalationId: string;      // "esc_..."
    conversationId: string;
    reason: string;
    status: "open";
    createdAt: string;
  };
}
```

### escalation.resolved

```typescript
{
  id: string;
  type: "escalation.resolved";
  timestamp: number;
  payload: {
    escalationId: string;
    conversationId: string;
    status: "resolved";
    resolvedAt: string;
  };
}
```
