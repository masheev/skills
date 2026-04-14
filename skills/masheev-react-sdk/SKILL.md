---
name: masheev-react-sdk
description: >-
  Use when building custom chat UIs with the Masheev React SDK instead of
  the default widget. Covers the useMasheev hook, MasheevProvider for headless
  mode, useWidgetSession, useWidgetChat, useWidgetSocket, useReadAloud,
  custom message rendering, event handling, and building chat interfaces
  from scratch. Use this skill when someone wants a "custom chat UI",
  "headless integration", "build their own chat component", or references
  @masheev/embed-sdk/react or @masheev/embed-sdk/headless.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev React SDK

Build fully custom chat UIs using React hooks. Two approaches:

1. **`@masheev/embed-sdk/react`** — Widget in an iframe, controlled via hooks
2. **`@masheev/embed-sdk/headless`** — No iframe, direct WebSocket connection, full UI control

## When to Use Which

| Need | Use |
|------|-----|
| Default chat bubble with some customization | `useMasheev` from `/react` |
| Embed widget in a specific area of the page | `useMasheev` with `mode: "embedded"` |
| Fully custom chat UI (own message bubbles, layout) | `MasheevProvider` + hooks from `/headless` |
| Chat on React Native | `/headless` (no iframe available) |

## Widget Hook (`/react`)

```tsx
import { useMasheev } from "@masheev/embed-sdk/react";

function App() {
  const {
    open, close, toggle,
    hide, show,
    sendMessage,
    setInputValue,
    updateContext,
    updateContact,
    updateTools,
    updateWorkflow,
    setQuestions,
    setListening,
    resetConversation,
    on, off,
    containerRef,     // For embedded mode — attach to a DOM element
    isReady,
  } = useMasheev({
    inboxId: "YOUR_INBOX_ID",
    mode: "chat-widget",
    user: { name: "Jane", email: "jane@example.com" },
  });

  return (
    <div>
      <button onClick={open} disabled={!isReady}>Open Chat</button>
    </div>
  );
}
```

**Singleton pattern**: Multiple `useMasheev()` calls with the same `inboxId` share a single SDK instance and iframe. The iframe is destroyed only when the last consumer unmounts.

## Headless Mode (`/headless`)

```tsx
import {
  MasheevProvider,
  useWidgetSession,
  useWidgetChat,
  useWidgetSocket,
  useReadAloud,
} from "@masheev/embed-sdk/headless";

function App() {
  return (
    <MasheevProvider config={{
      inboxId: "YOUR_INBOX_ID",
      apiBase: "https://api.masheev.com",
      customerInfo: { name: "Jane", email: "jane@example.com" },
    }}>
      <CustomChat />
    </MasheevProvider>
  );
}

function CustomChat() {
  const { conversationId, greeting, workflowRunState } = useWidgetSession();
  const { messages, sendMessage, isStreaming } = useWidgetChat();
  const { status: connectionStatus } = useWidgetSocket();

  return (
    <div>
      <div className="messages">
        {messages.map((msg) => (
          <div key={msg.id} className={msg.role}>
            {msg.content}
          </div>
        ))}
        {isStreaming && <div className="typing">AI is typing...</div>}
      </div>
      <input
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            sendMessage(e.currentTarget.value);
            e.currentTarget.value = "";
          }
        }}
      />
    </div>
  );
}
```

## Provider Config

```typescript
interface MasheevProviderConfig {
  inboxId: string;                          // Required
  apiBase?: string;                         // Default: "https://api.masheev.com"
  turnstileSiteKey?: string;                // Cloudflare Turnstile (anti-bot)
  customerInfo?: {
    name?: string;
    email?: string;
    phone?: string;
  };
  tools?: readonly ClientToolDefinition[];  // Client-side tools
  instructions?: string;                    // Tool usage instructions for AI
  workflow?: WorkflowConfig;                // Conversational workflow
  onStepComplete?: (payload: WorkflowStepCompletePayload) => void;
  onWorkflowComplete?: (payload: WorkflowCompletePayload) => void;
}
```

## Headless Hooks Reference

| Hook | Returns | Purpose |
|------|---------|---------|
| `useWidgetSession()` | `{ conversationId, contactId, greeting, workflowRunState, status }` | Session lifecycle |
| `useWidgetChat()` | `{ messages, sendMessage, resolve, isStreaming, history }` | Message operations |
| `useWidgetSocket()` | `{ status, subscribe, unsubscribe }` | WebSocket connection state |
| `useReadAloud()` | `{ play, pause, stop, isPlaying, currentMessageId }` | Text-to-speech controls |

## Defining Tools with Zod

```typescript
import { clientTool } from "@masheev/embed-sdk/headless";
import { z } from "zod";

const bookingTool = clientTool({
  name: "check_availability",
  description: "Check appointment availability for a given date",
  parameters: z.object({
    date: z.string().describe("ISO date string"),
    service: z.string().describe("Service type"),
  }),
  execute: async (args, { onProgress }) => {
    onProgress("Checking calendar...");
    const slots = await fetchSlots(args.date, args.service);
    return { success: true, data: { slots } };
  },
});

// Pass to provider
<MasheevProvider config={{ inboxId: "...", tools: [bookingTool] }}>
```

## Workflow Helpers

```typescript
import { defineWorkflow, validateWorkflowConfig } from "@masheev/embed-sdk/headless";

const onboardingFlow = defineWorkflow({
  id: "user_onboarding",
  name: "New User Onboarding",
  steps: [
    { id: "greeting", name: "Welcome", instructions: "Greet the user by name: {{context.name}}" },
    { id: "collect_info", name: "Collect Details", tools: ["check_availability"] },
    { id: "confirm", name: "Confirm Booking", instructions: "Summarize and confirm" },
  ],
  context: { name: "Jane" },
});

// Validate before passing to provider
const result = validateWorkflowConfig(onboardingFlow);
if (!result.valid) console.error(result.errors);
```

See [references/headless.md](./references/headless.md) for advanced patterns (custom message components, streaming, reconnection).
