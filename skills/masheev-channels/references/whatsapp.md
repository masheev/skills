# WhatsApp Business API Integration

## Setup

WhatsApp channels connect via the Meta Business API. Create an inbox with channel `whatsapp`:

```typescript
await apiClient.inboxes.create.mutate({
  name: "WhatsApp Support",
  channel: "whatsapp",
  channelConfig: {
    whatsapp: {
      phoneNumberId: "1234567890",       // Meta phone number ID
      businessAccountId: "9876543210",    // WhatsApp Business Account ID
      accessToken: "EAA...",             // System user token (long-lived)
    },
  },
});
```

Connect your Meta Business app's webhook to `https://api.masheev.com/webhooks/whatsapp/{inboxId}`. Masheev verifies the `X-Hub-Signature-256` header on every request.

## 24-Hour Session Window

WhatsApp enforces a messaging window policy:

| Window | Duration | Message Types | Cost |
|--------|----------|---------------|------|
| Customer-initiated | 24h from last customer message | Free-form text, media, interactive | Per-conversation pricing |
| Business-initiated | Outside 24h window | **Template messages only** | Per-template pricing |

- The 24h window resets each time the customer sends a message.
- Inside the window, you can send any message type (text, media, interactive).
- Outside the window, you must use a pre-approved template message.
- Masheev tracks the window state per conversation and returns `sessionExpired: true` when the window closes.

```typescript
// Check window status before sending
const conv = await apiClient.conversations.get.query({ id: "conv_..." });
if (conv.channelState?.whatsapp?.sessionExpired) {
  // Must use a template message
  await apiClient.messages.sendTemplate.mutate({
    conversationId: "conv_...",
    templateName: "order_update",
    languageCode: "en",
    components: [
      { type: "body", parameters: [{ type: "text", text: "ORD-12345" }] },
    ],
  });
}
```

## Template Messages

Templates must be submitted to Meta for approval before use.

### Approval Requirements

- **Category**: utility, authentication, or marketing
- **Language**: at least one language required; Meta reviews per-language
- **Variables**: use `{{1}}`, `{{2}}` placeholders; no dynamic URLs in body (use URL buttons)
- **No prohibited content**: no threatening, abusive, or misleading text
- **Review time**: typically 24-48 hours; rejections include a reason

### Sending Templates

```typescript
await apiClient.messages.sendTemplate.mutate({
  conversationId: "conv_...",
  templateName: "appointment_reminder",
  languageCode: "en",
  components: [
    {
      type: "header",
      parameters: [{ type: "image", image: { link: "https://..." } }],
    },
    {
      type: "body",
      parameters: [
        { type: "text", text: "Jane" },
        { type: "text", text: "March 15, 2026 at 2:00 PM" },
      ],
    },
    {
      type: "button",
      sub_type: "quick_reply",
      index: 0,
      parameters: [{ type: "payload", payload: "confirm_yes" }],
    },
  ],
});
```

## Supported Media Types

| Type | Max Size | Formats |
|------|----------|---------|
| Image | 5 MB | JPEG, PNG |
| Video | 16 MB | MP4, 3GPP |
| Audio | 16 MB | AAC, MP4, AMR, OGG (Opus) |
| Document | 100 MB | PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT |
| Sticker | 500 KB (static), 100 KB (animated) | WebP |
| Location | N/A | latitude + longitude |
| Contacts | N/A | vCard format |

```typescript
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Here is your invoice:",
  attachments: [
    { type: "document", url: "https://files.myapp.com/invoice-123.pdf", filename: "invoice.pdf" },
  ],
});
```

## Formatting

WhatsApp supports a subset of text formatting:

| Style | Syntax | Example |
|-------|--------|---------|
| Bold | `*text*` | *bold text* |
| Italic | `_text_` | _italic text_ |
| Strikethrough | `~text~` | ~strikethrough~ |
| Monospace | `` ```text``` `` | `monospace` |
| Quote | `> text` | Block quote (single line) |
| Bulleted list | `- item` or `* item` | List items |
| Numbered list | `1. item` | Ordered items |

Masheev automatically converts markdown in AI responses to WhatsApp formatting when the conversation channel is `whatsapp`.

## Opt-In Requirements

WhatsApp requires explicit opt-in from users before you can message them:

- Users must actively consent (pre-checked boxes are not valid)
- You must clearly state what types of messages they will receive
- You must provide a way to opt out
- Record opt-in timestamp and method in contact consent:

```typescript
await apiClient.contacts.update.mutate({
  id: "con_...",
  consent: {
    channels: { whatsapp: "opted_in" },
  },
});
```

## Rate Limits

| Tier | Messages/day | Requirement |
|------|-------------|-------------|
| Unverified | 250 | Default |
| Tier 1 | 1,000 | Verified business + good quality |
| Tier 2 | 10,000 | Sustained quality rating |
| Tier 3 | 100,000 | Sustained quality rating |
| Tier 4 | Unlimited | Sustained quality rating |

Quality rating is based on user feedback (blocks, reports). Masheev surfaces your current tier and quality rating in **Dashboard > Inboxes > WhatsApp**.
