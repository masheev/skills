---
name: masheev-widget
description: >-
  Use when installing, configuring, or troubleshooting the Masheev chat widget
  in any web application. Covers adding the chat widget via script tag, npm
  package (@masheev/embed-sdk), React, Next.js, Vue, and vanilla JavaScript.
  Handles SSR safety ("window is not defined"), SPA route changes, user identity
  with HMAC verification, widget positioning, theming (light/dark/auto), CSP
  headers, GDPR consent gating, embedded mode, prompt-input mode, and common
  errors. Use this skill whenever someone asks to "add Masheev", "install the
  chat widget", "embed Masheev", or mentions @masheev/embed-sdk.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Widget Integration

Add the Masheev chat widget to any web application. The widget runs in an iframe, communicates via `postMessage`, and requires only an `inboxId` to start.

## Quick Start

### Script Tag (simplest)

```html
<script>
  (function(m,a,s,h,e,v){
    m.MasheevConfig=e;m[e]={inboxId:v};
    s=a.createElement('script');s.async=1;
    s.src='https://cdn.masheev.com/widget.js';
    a.head.appendChild(s);
  })(window,document,0,0,'masheev','YOUR_INBOX_ID');
</script>
```

### npm Package

```bash
npm install @masheev/embed-sdk
```

```typescript
import { init } from "@masheev/embed-sdk/js";

init({
  inboxId: "YOUR_INBOX_ID",
  mode: "chat-widget",         // "chat-widget" | "prompt-input" | "embedded"
  position: "right",           // "left" | "right"
  colorScheme: "auto",         // "light" | "dark" | "auto"
});
```

### React

```tsx
import { useMasheev } from "@masheev/embed-sdk/react";

function App() {
  const { open, close, isReady } = useMasheev({
    inboxId: "YOUR_INBOX_ID",
  });

  return <button onClick={open} disabled={!isReady}>Chat with us</button>;
}
```

### Next.js (SSR-safe)

```tsx
"use client";

import dynamic from "next/dynamic";
import { useMasheev } from "@masheev/embed-sdk/react";

// Option A: Use the hook directly in a client component
function ChatWidget() {
  useMasheev({ inboxId: "YOUR_INBOX_ID" });
  return null;
}

// Option B: Dynamic import if widget has side effects at import time
const ChatWidget = dynamic(
  () => import("../components/chat-widget"),
  { ssr: false }
);

// In your layout:
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <ChatWidget />
      </body>
    </html>
  );
}
```

## Configuration Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `inboxId` | `string` | **required** | Your inbox ID from the Masheev dashboard |
| `mode` | `"chat-widget" \| "prompt-input" \| "embedded"` | `"chat-widget"` | Widget display mode |
| `position` | `"left" \| "right"` | `"right"` | Launcher position (chat-widget mode only) |
| `colorScheme` | `"light" \| "dark" \| "auto"` | `"light"` | Theme (auto follows OS preference) |
| `sessionMode` | `"persistent" \| "ephemeral" \| "workflow"` | `"persistent"` | Conversation persistence across page loads |
| `user` | `UserContext` | - | Identify the logged-in user |
| `placeholder` | `string` | - | Custom input placeholder text |
| `agentName` | `string` | - | Override AI agent display name |
| `agentTitle` | `string` | - | Agent role/title shown in header |
| `questions` | `string[]` | - | Suggested conversation starters |
| `privacyUrl` | `string` | - | Link to your privacy policy |
| `requireConsent` | `boolean` | `false` | Require explicit consent before starting chat |
| `hideHeader` | `boolean` | `false` | Hide chat header (embedded mode only) |
| `tools` | `ClientToolDefinition[]` | - | Client-side tools (see masheev-client-tools skill) |
| `workflow` | `WorkflowConfig` | - | Conversational workflow (see masheev-workflows skill) |
| `debug` | `boolean` | `false` | Log all postMessage traffic to console |

## User Identity (HMAC Verification)

Pass authenticated user data to link conversations to your users. Use `userHash` to prevent spoofing:

```typescript
// Server-side: generate HMAC hash
import crypto from "node:crypto";

const userHash = crypto
  .createHmac("sha256", process.env.MASHEEV_INBOX_SECRET)
  .update(userId)
  .digest("hex");

// Client-side: pass to widget
init({
  inboxId: "YOUR_INBOX_ID",
  user: {
    userId: "user_123",
    userHash: userHash,  // computed server-side
    name: "Jane Doe",
    email: "jane@example.com",
    company: "Acme Inc",
    customAttributes: {
      plan: "pro",
      signupDate: "2026-01-15",
    },
  },
});
```

## SDK Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `open()` | `() => void` | Open the widget |
| `close()` | `() => void` | Close the widget |
| `toggle()` | `() => void` | Toggle open/closed |
| `hide()` | `() => void` | Hide from DOM (`display: none`) |
| `show()` | `() => void` | Show in DOM |
| `sendMessage` | `(text: string) => void` | Send a message programmatically |
| `setInputValue` | `(text: string, opts?: { append?: boolean }) => void` | Pre-fill the input field |
| `updateContext` | `(ctx: Partial<UserContext>) => void` | Update user identity mid-session |
| `updateContact` | `(fields: { name?, email?, phone?, company? }) => void` | Update contact (persists server-side) |
| `setQuestions` | `(questions: string[]) => void` | Update suggested questions |
| `setListening` | `(listening: boolean) => void` | Enable/disable speech input |
| `updateTools` | `(tools: ClientToolDefinition[]) => void` | Add/replace client tools |
| `updateWorkflow` | `(updates: { context?, name? }) => void` | Update workflow context or name |
| `resetConversation` | `() => void` | Start a new conversation |
| `destroy()` | `() => void` | Remove widget and clean up |
| `on(event, cb)` | Returns unsubscribe `() => void` | Subscribe to widget events |
| `off(event, cb)` | `void` | Unsubscribe from event |

## Events

| Event | Payload | When |
|-------|---------|------|
| `ready` | - | Widget iframe loaded and initialized |
| `open` | - | Widget opened |
| `close` | - | Widget closed |
| `message` | `{ role: "user" \| "ai", content: string }` | New message sent or received |
| `error` | `{ message: string, code?: string }` | Error occurred |
| `resolved` | `{ conversationId, reason? }` | Conversation marked resolved |
| `newConversation` | `{ previousConversationId? }` | Fresh conversation started |
| `unreadCount` | `{ count: number }` | Unread message count changed |
| `action:invoke` | `{ invocationId, toolName, args }` | AI requests client tool execution |
| `workflow:stepComplete` | `{ workflowId, stepId, data? }` | Workflow step completed |
| `workflow:complete` | `{ workflowId, outcome, data? }` | Entire workflow completed |

## Widget Modes

### chat-widget (default)
Floating chat bubble in bottom corner. Opens to full chat panel. Best for most sites.

### prompt-input
Persistent input bar (no floating bubble). Good for AI-first interfaces.

### embedded
Mount inside a specific DOM element. No floating UI. Full control over layout.

```tsx
// React embedded mode
function SupportPage() {
  const { containerRef, isReady } = useMasheev({
    inboxId: "YOUR_INBOX_ID",
    mode: "embedded",
    hideHeader: true,
  });

  return <div ref={containerRef} style={{ height: "500px", width: "100%" }} />;
}
```

```typescript
// Vanilla JS embedded mode
init({
  inboxId: "YOUR_INBOX_ID",
  mode: "embedded",
  containerId: "masheev-container", // DOM element ID
  hideHeader: true,
});
```

## Troubleshooting

See [references/troubleshooting.md](./references/troubleshooting.md) for:
- "window is not defined" in SSR
- Widget not appearing after SPA navigation
- CSP header configuration
- z-index conflicts with other UI elements
- Cross-origin cookie issues
- GDPR-compliant deferred loading
