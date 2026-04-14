# Messages API

## List Messages

```typescript
const result = await apiClient.messages.list.query({
  conversationId: "conv_...",
  limit: 50,                        // Default: 50, max: 200
  before: "msg_...",                // Cursor: messages before this ID
  after: "msg_...",                 // Cursor: messages after this ID
});
// result: { items: Message[], hasMore: boolean }
```

## Get Message

```typescript
const message = await apiClient.messages.get.query({ id: "msg_..." });
```

## Send Message

```typescript
const message = await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  role: "agent",                    // "agent" for human agents
  content: "Thanks for reaching out! How can I help?",
  attachments: [                    // Optional
    {
      type: "image",
      name: "screenshot.png",
      url: "https://...",
      mimeType: "image/png",
      size: 102400,
    },
  ],
});
```

## Message Schema

```typescript
interface Message {
  id: string;                       // "msg_..."
  conversationId: string;
  role: "contact" | "ai" | "agent" | "system";
  senderId?: string;
  senderName?: string;
  content: string;
  contentType: "text" | "attachment" | "system";
  status: "pending" | "sent" | "delivered" | "read" | "failed";
  attachments?: Attachment[];
  aiMetadata?: {
    model?: string;
    provider?: string;
    toolCalls?: ToolCall[];
    usage?: { inputTokens: number; outputTokens: number };
    latencyMs?: number;
    components?: {
      quickReplies?: { label: string; value: string }[];
      card?: { title: string; subtitle?: string; fields?: { label: string; value: string }[] };
    };
  };
  createdAt: string;
  updatedAt: string;
}
```
