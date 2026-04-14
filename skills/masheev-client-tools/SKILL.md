---
name: masheev-client-tools
description: >-
  Use when defining client-side tools that the Masheev AI agent can invoke
  in the browser. Covers ClientToolDefinition with JSON Schema and Zod,
  the execute function with progress reporting, approval flows
  (needsApproval), rich responses (cards, quick replies), tool
  registration via init() and updateTools(), and the action:invoke /
  action:result event flow. Use this skill when someone asks to "add tools
  to the chat", "let the AI call my functions", "create client tools",
  or "give the AI access to my app data".
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Client Tools

Client tools let the AI agent call functions running in the user's browser. The AI decides when to use a tool based on its name and description, executes it via the SDK, and uses the result to continue the conversation.

## How It Works

1. You define tools with a name, description, JSON Schema parameters, and an `execute` function
2. The SDK sends tool definitions to the server when the session starts
3. During conversation, the AI decides to invoke a tool
4. The SDK calls your `execute` function in the browser
5. The result is sent back to the AI, which uses it to respond

## Defining Tools

### With Zod (recommended)

```typescript
import { clientTool } from "@masheev/embed-sdk/headless";
import { z } from "zod";

const searchProducts = clientTool({
  name: "search_products",
  description: "Search the product catalog by query, category, or price range",
  parameters: z.object({
    query: z.string().describe("Search keywords"),
    category: z.string().optional().describe("Product category"),
    maxPrice: z.number().optional().describe("Maximum price in USD"),
  }),
  execute: async (args, { onProgress }) => {
    onProgress("Searching products...");
    const results = await fetch(`/api/products?q=${args.query}`).then((r) => r.json());
    return {
      success: true,
      data: { products: results.slice(0, 5) },
      display: "card",
      components: {
        card: {
          title: `Found ${results.length} products`,
          fields: results.slice(0, 3).map((p) => ({ label: p.name, value: `$${p.price}` })),
        },
        quickReplies: [
          { label: "Show more", value: "Show me more results" },
          { label: "Filter by price", value: "Only show products under $50" },
        ],
      },
    };
  },
});
```

### With JSON Schema

```typescript
const searchProducts: ClientToolDefinition = {
  name: "search_products",
  description: "Search the product catalog",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string", description: "Search keywords" },
      category: { type: "string", description: "Product category" },
      maxPrice: { type: "number", description: "Max price in USD" },
    },
    required: ["query"],
  },
  execute: async (args, { onProgress }) => {
    // ... same as above
  },
};
```

## Registration

### At initialization

```typescript
init({
  inboxId: "YOUR_INBOX_ID",
  tools: [searchProducts, checkInventory, addToCart],
  instructions: "Use search_products when the user asks about products. Use addToCart when they want to buy.",
});
```

### Dynamic update (mid-conversation)

```typescript
// Add new tools based on user state
if (user.isLoggedIn) {
  sdk.updateTools([...currentTools, orderHistoryTool, accountSettingsTool]);
}
```

## Tool Result Shape

```typescript
interface ClientToolResult {
  success: boolean;               // Did the tool execute successfully?
  data?: Record<string, unknown>; // Structured data for the AI to use
  error?: string;                 // Error message (if success: false)
  display?: "text" | "card" | "silent";  // How to show the result
  components?: {
    card?: {
      title: string;
      subtitle?: string;
      fields?: { label: string; value: string }[];
    };
    quickReplies?: { label: string; value: string }[];
  };
}
```

| `display` | Behavior |
|-----------|----------|
| `"text"` | AI incorporates result into its text response |
| `"card"` | Result shown as a rich card in the chat |
| `"silent"` | Result used by AI but not shown to user |

## Approval Flow

For sensitive actions (payments, data deletion), require user confirmation:

```typescript
const deleteAccount = clientTool({
  name: "delete_account",
  description: "Delete the user's account permanently",
  parameters: z.object({
    confirmationCode: z.string(),
  }),
  needsApproval: true,  // User must confirm before execute runs
  execute: async (args) => {
    await fetch("/api/account", { method: "DELETE", body: JSON.stringify(args) });
    return { success: true, data: { message: "Account deleted" } };
  },
});
```

## Constraints

| Limit | Value |
|-------|-------|
| Max tools per session | 10 |
| Tool name | Alphanumeric + underscore, starts with letter |
| Description length | Max 500 characters |
| Max parameters per tool | 20 |
| Execution timeout | 60 seconds (configurable via `timeout`) |

## Event Flow (for manual handling)

If not using the SDK's automatic execution (e.g., vanilla JS with custom logic):

```typescript
import { on } from "@masheev/embed-sdk/js";

on("action:invoke", async ({ invocationId, toolName, args }) => {
  // Execute your logic
  const result = await myToolHandlers[toolName](args);

  // Send result back — the SDK handles this automatically when using
  // tool definitions with execute functions, but you can do it manually:
  sdk.postMessage({ type: "action:result", invocationId, result });
});
```

See [references/examples.md](./references/examples.md) for complete tool examples (booking, e-commerce, CRM lookup).
