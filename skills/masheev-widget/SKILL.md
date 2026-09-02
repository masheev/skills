---
name: masheev-widget
description: >-
  Use when installing, configuring, or troubleshooting the Masheev chat widget
  in any web application. Covers adding the chat widget via script tag, npm
  package (@masheev/embed-sdk), React, Next.js, Vue, and vanilla JavaScript.
  Handles SSR safety ("window is not defined"), SPA route changes, user identity
  with HMAC verification, widget positioning, theming (light/dark/auto, colours, fonts, message
  style), CSP
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
| `colorScheme` | `"light" \| "dark" \| "auto"` | `"light"` | Theme — `"auto"` follows the parent page (`.dark`/`.light` class or `data-theme`) then OS preference |
| `theme` | `WidgetTheme` | - | Colours, font and message style (see [Theming](#theming)). Ignored when the inbox has a saved theme |
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

## Color Scheme (light / dark)

Two ways to theme the widget. Pick based on whether your app has its own theme state.

### Recommended: drive it from your app (deterministic)

If your app already knows its resolved theme, push that value to the widget — no DOM
guessing, no coupling to class names. Seed `colorScheme` at init (avoids a theme flash on
first paint) and re-push on every change with `updateColorScheme`:

```tsx
// React — one source of truth, synced on initial load AND every toggle
const isDark = useIsDark(); // your app's resolved theme (next-themes, custom, etc.)
const colorScheme = isDark ? "dark" : "light";

const { updateColorScheme } = useMasheev({
  inboxId: "...",
  colorScheme, // read once — seeds the first render
});

useEffect(() => {
  updateColorScheme(colorScheme); // keeps the live widget in sync
}, [colorScheme, updateColorScheme]);
```

```js
// Vanilla JS
import { init, updateColorScheme } from "@masheev/embed-sdk/js";
init({ inboxId: "...", colorScheme: isDark ? "dark" : "light" });

document.querySelector("#dark-toggle").addEventListener("click", () => {
  updateColorScheme(nowDark ? "dark" : "light");
});
```

### Zero-config: `colorScheme: "auto"`

For pages where you can't add sync code, `"auto"` makes the widget follow the parent page
automatically. It resolves the scheme in priority order:

1. An explicit `.dark` / `.light` class on `<html>`
2. A `data-theme="dark" | "light"` attribute on `<html>`
3. The OS `prefers-color-scheme` media query

It observes the `<html>` `class` + `data-theme` attributes and the media query, so common
toggles (Tailwind `.dark`, next-themes, etc.) work without extra wiring.

```tsx
const { updateColorScheme } = useMasheev({ inboxId: "...", colorScheme: "auto" });
```

| Value | Behavior |
|-------|----------|
| `"light"` | Force light theme (default) |
| `"dark"` | Force dark theme |
| `"auto"` | Follow parent page: explicit `.dark`/`.light` class or `data-theme`, else OS `prefers-color-scheme` |

> **Prefer the explicit approach when you control the app.** `"auto"` has to *infer* the
> theme from the DOM, which couples the widget to your class naming and can miss
> non-standard toggles. If your toggle sets an explicit `.light` class while the OS is in
> dark mode, you need `@masheev/embed-sdk` ≥ the version that resolves `.light`/`data-theme`
> (older builds fell back to the OS query and stayed dark).

## Theming

Pass a `theme` object to override the widget's appearance. Every field is optional.

```typescript
init({
  inboxId: "YOUR_INBOX_ID",
  colorScheme: "auto",
  theme: {
    template: "minimal",
    primaryColor: "#2563eb",
    userBubbleColor: "#2563eb",
    fontSize: "base",
    messageStyle: "plain",
  },
});
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `template` | `"minimal" \| "modern" \| "corporate" \| "playful" \| "dark" \| "custom"` | `"modern"` | Preset palette; the fields below override individual values |
| `primaryColor` | `string` | from template | Send button, focus ring, unread indicator, selected chips |
| `backgroundColor` | `string` | from template | Panel background; surfaces and hairlines are derived from it |
| `textColor` | `string` | from template | Body text; adjusted if it does not reach 4.5:1 on the background |
| `userBubbleColor` | `string` | `primaryColor` | Background of the visitor's own messages |
| `userBubbleTextColor` | `string` | derived | Text inside the visitor's messages; contrast enforced |
| `fontFamily` | `string` | system stack | Font stack for the widget (see caveat below) |
| `fontSize` | `"sm" \| "base" \| "lg"` | `"base"` | Body text size; every other size scales from it |
| `messageStyle` | `"plain" \| "bubble"` | `"plain"` | `"plain"` renders AI replies as text on the panel surface; `"bubble"` keeps them in a bubble |
| `logoUrl` | `string` | - | Header image instead of the default agent avatar |
| `headerTitle` | `string` | agent name | Header title text |
| `poweredBy` | `boolean` | `true` | Show the "Powered by Masheev" footer line |

**Precedence.** The theme saved on the inbox in the Masheev dashboard wins. The `theme`
passed here applies only when the inbox has no saved theme, so a customer's own appearance
settings are never overridden by embed code. The dashboard's inbox appearance editor shows
a live preview of these fields in light and dark.

**Dark mode.** Each template has a light and a dark preset, and the widget uses the dark
preset when the resolved scheme is dark. Colours you set explicitly are used as given in
both schemes — they are not recoloured for dark mode. Either pick colours that work in
both, or pin the widget with `colorScheme: "light"`.

**`fontFamily` caveat.** The widget runs in an iframe that does not load web fonts. Only
fonts already installed on the visitor's device and the generic families (`sans-serif`,
`serif`, `monospace`) render; anything else falls back to the system stack. The value is
sanitized, so `url()`, braces and semicolons are stripped.

### CSS custom properties

The widget sets these on the iframe's document root. They are useful for advanced styling
and as a naming reference if you build your own UI with the headless SDK.

| Variable | Role |
|----------|------|
| `--masheev-canvas` | Panel background |
| `--masheev-surface` | Raised areas on the canvas |
| `--masheev-surface-muted` | Chips, tool pills, inline code |
| `--masheev-surface-elevated` | Composer pill, cards, jump-to-latest |
| `--masheev-foreground` | Body text |
| `--masheev-foreground-muted` | Meta and legal text |
| `--masheev-border` | Borders |
| `--masheev-border-subtle` | Hairlines and card edges |
| `--masheev-primary` / `--masheev-primary-foreground` | Primary actions |
| `--masheev-ai-accent` | AI accent |
| `--masheev-focus-ring` | Focus ring colour |
| `--masheev-danger` / `--masheev-danger-foreground` | Errors |
| `--masheev-success` / `--masheev-success-foreground` | Success states |
| `--masheev-user-bubble` / `--masheev-user-bubble-text` | Visitor message pill |
| `--masheev-assistant-bubble` | AI bubble background (`messageStyle: "bubble"` only) |
| `--masheev-bg` / `--masheev-text` | Raw `backgroundColor` / `textColor` |
| `--masheev-font` / `--masheev-font-size` | Resolved font stack and body size |
| `--masheev-shadow-panel` / `--masheev-shadow-pill` / `--masheev-shadow-launcher` | Elevation |
| `--masheev-scrollbar-thumb` | Transcript scrollbar |


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

The SDK creates and owns the widget iframe, and resizes it on open, on close, and whenever
the widget posts a `resize` message. The host page sets no dimensions — except in
`embedded` mode, where your container defines the available space.

### chat-widget (default)
Floating launcher in the bottom corner. Opens a chat panel above the launcher; on small
screens the panel fills the viewport. Best for most sites.

### prompt-input
A single input pill docked at the bottom of the page, no launcher. Focusing it reveals the
suggested questions; sending a message opens a transcript panel above the pill while the
pill stays as the composer. Good for AI-first interfaces.

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
