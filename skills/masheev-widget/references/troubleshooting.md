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

## Widget Theme Not Following the Page Toggle

The widget's light/dark doesn't update when the host page's theme changes.

Common causes, in order of likelihood:

1. **You're relying on `colorScheme: "auto"` but your toggle sets an explicit `.light`
   class.** `"auto"` infers the theme from the DOM. Older `@masheev/embed-sdk` only checked
   for `.dark` and otherwise fell back to `prefers-color-scheme`, so choosing light while the
   OS was dark left the widget dark. Fixed in newer builds (now also honors `.light` /
   `data-theme`). **Better: drive it explicitly** — call `updateColorScheme(isDark ? "dark" :
   "light")` from your resolved theme state (see "Color Scheme" in SKILL.md). This avoids the
   DOM heuristic entirely.

2. **The host page bundle is stale.** The parent-page SDK (`setupDarkModeSync` /
   `updateColorScheme`) is bundled into *your* site at build time. If theme sync was added
   after your last deploy, the deployed page won't send updates even though the widget iframe
   handles them. Rebuild and redeploy the host page.

3. **The widget iframe host is stale.** The receiving side lives in the widget app. If the
   host page sends `updateColorScheme` (verify by posting it to the iframe manually) but the
   widget ignores it, the iframe deployment predates the handler.

Quick bisection: in the page console, post the message the SDK would send straight to the
iframe. If the widget flips, the iframe is fine and the problem is the parent not sending:

```js
document.querySelector('iframe[title="Masheev Chat Widget"]')
  .contentWindow.postMessage({ type: "updateColorScheme", payload: { colorScheme: "dark" } }, "*");
```
