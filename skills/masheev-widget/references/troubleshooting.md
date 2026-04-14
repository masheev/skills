# Widget Troubleshooting

## "window is not defined" (SSR/Next.js)

The SDK accesses `window` and `document` on import. In SSR environments:

**Next.js App Router** — use `"use client"` directive:
```tsx
"use client";
import { useMasheev } from "@masheev/embed-sdk/react";
```

**Next.js dynamic import** (if the module has side effects at import time):
```tsx
import dynamic from "next/dynamic";
const ChatWidget = dynamic(() => import("./chat-widget"), { ssr: false });
```

**Vanilla JS in SSR** — guard with `typeof window !== "undefined"`:
```typescript
if (typeof window !== "undefined") {
  const { init } = await import("@masheev/embed-sdk/js");
  init({ inboxId: "YOUR_INBOX_ID" });
}
```

## Widget Not Appearing After SPA Navigation

The widget initializes once on `init()`. In SPAs, if you unmount and remount the component, the React hook handles this automatically (singleton per `inboxId`).

If using vanilla JS, call `destroy()` before reinitializing:
```typescript
import { destroy, init } from "@masheev/embed-sdk/js";

// On route change
destroy();
init({ inboxId: "YOUR_INBOX_ID" });
```

## CSP Header Configuration

If your site uses Content-Security-Policy headers, add these directives:

```
script-src 'self' https://cdn.masheev.com;
frame-src 'self' https://app.masheev.com;
connect-src 'self' https://api.masheev.com wss://api.masheev.com;
```

## z-index Conflicts

The widget uses `z-index: 2147483647` (max). If another element overlaps:

```css
/* Override the widget container z-index */
#masheev-widget-container {
  z-index: 999999 !important;
}
```

## Cross-Origin Cookie Issues

The widget iframe runs on `app.masheev.com`. If third-party cookies are blocked:
- Sessions use the session token (Authorization header), not cookies
- No cookie issues in modern browsers — the SDK uses `postMessage` for all communication

## GDPR-Compliant Deferred Loading

Load the widget only after the user consents to cookies/data processing:

```typescript
// Wait for consent
cookieConsent.on("accept", () => {
  import("@masheev/embed-sdk/js").then(({ init }) => {
    init({
      inboxId: "YOUR_INBOX_ID",
      requireConsent: true, // Shows consent prompt in widget too
      privacyUrl: "https://myapp.com/privacy",
    });
  });
});
```

## Widget Not Connecting / Infinite Loading

1. Check `inboxId` is correct (find it in Dashboard > Inboxes)
2. Check the inbox status is `active` (not `paused` or `disabled`)
3. Check browser console for errors (enable `debug: true` in config)
4. Verify your domain is not blocked by the inbox CORS settings
5. Check if a content blocker or ad blocker is intercepting requests

## Embedded Mode Not Rendering

The container element must exist in the DOM before `init()` is called:

```typescript
// Wrong — element doesn't exist yet
init({ inboxId: "...", mode: "embedded", containerId: "chat" });

// Right — wait for DOM
document.addEventListener("DOMContentLoaded", () => {
  init({ inboxId: "...", mode: "embedded", containerId: "chat" });
});
```

For React, use the `containerRef` from the hook:
```tsx
const { containerRef } = useMasheev({ inboxId: "...", mode: "embedded" });
return <div ref={containerRef} style={{ height: 500 }} />;
```
