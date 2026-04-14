# SMS Channel Integration

## Setup

Create an SMS inbox connected to your telephony provider:

```typescript
await apiClient.inboxes.create.mutate({
  name: "SMS Support",
  channel: "sms",
  channelConfig: {
    sms: {
      provider: "twilio",            // "twilio" | "telnyx" | "vonage"
      phoneNumber: "+15551234567",   // E.164 format
      accountSid: "AC...",
      authToken: "...",
    },
  },
});
```

Configure the provider's webhook URL to `https://api.masheev.com/webhooks/sms/{inboxId}`.

## TCPA Compliance

The Telephone Consumer Protection Act (TCPA) governs SMS messaging in the US. Violations carry penalties of $500-$1,500 per message.

### Opt-In Requirements

- **Express written consent** is required before sending marketing messages
- **Express consent** (non-written) is sufficient for transactional/informational messages
- Consent must be clear, conspicuous, and voluntary
- Pre-checked boxes do not constitute valid consent
- Record timestamp, method, and exact language shown at consent time

```typescript
// Record opt-in
await apiClient.contacts.update.mutate({
  id: "con_...",
  consent: {
    channels: { sms: "opted_in" },
    marketing: true,  // Only if marketing consent was given
  },
  customAttributes: {
    smsConsentTimestamp: new Date().toISOString(),
    smsConsentMethod: "web_form",
  },
});
```

### Opt-Out Handling

Masheev automatically processes these keywords and marks the contact as opted out:

| Keyword | Action |
|---------|--------|
| `STOP` | Opt out of all messages |
| `STOP ALL` | Opt out of all messages |
| `UNSUBSCRIBE` | Opt out of all messages |
| `CANCEL` | Opt out of all messages |
| `END` | Opt out of all messages |
| `QUIT` | Opt out of all messages |
| `HELP` | Sends help/support info response |
| `INFO` | Sends help/support info response |
| `START` | Re-opt-in (resumes messages) |
| `UNSTOP` | Re-opt-in (resumes messages) |

When a user sends `STOP`, Masheev:
1. Updates `contact.consent.channels.sms` to `"opted_out"`
2. Sends a confirmation: "You have been unsubscribed. Reply START to resubscribe."
3. Blocks all outbound SMS to that contact until they re-opt-in
4. Fires the `contact.updated` webhook

## Character Limits and Segmentation

### GSM-7 Encoding (standard characters)

| Segments | Character Limit |
|----------|----------------|
| 1 | 160 characters |
| 2 | 306 characters (153 per segment) |
| 3 | 459 characters (153 per segment) |
| N | N x 153 characters |

### UCS-2 Encoding (Unicode: emoji, non-Latin scripts)

| Segments | Character Limit |
|----------|----------------|
| 1 | 70 characters |
| 2 | 134 characters (67 per segment) |
| N | N x 67 characters |

A single emoji forces the entire message to UCS-2 encoding, reducing capacity from 160 to 70 characters per segment. Each segment is billed separately.

Masheev calculates segments before sending and exposes the count:

```typescript
const msg = await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Your order ORD-12345 has shipped! Track: https://track.example.com/abc",
});
// msg.channelMeta.sms.segments => 1
```

## Number Types

| Type | Throughput | Use Case | 10DLC Required |
|------|-----------|----------|----------------|
| Long code (10-digit) | 1 msg/sec | Low-volume, conversational | Yes (US) |
| Toll-free (8xx) | 25 msg/sec | Medium-volume, verified | No (verification required) |
| Short code (5-6 digit) | 100+ msg/sec | High-volume, marketing blasts | No |

### 10DLC Registration (US)

US long code SMS requires 10DLC (10-Digit Long Code) registration:

1. Register your brand with The Campaign Registry (TCR)
2. Register your campaign (use case)
3. Assign phone numbers to the campaign
4. Wait for carrier approval (1-5 business days)

Unregistered traffic is heavily filtered and may be blocked entirely.

## Rate Limiting

Masheev enforces provider rate limits to prevent throttling:

| Number Type | Default Rate | Configurable |
|-------------|-------------|-------------|
| Long code | 1 msg/sec | No (carrier limit) |
| Toll-free | 25 msg/sec | No (carrier limit) |
| Short code | 100 msg/sec | Yes (up to carrier limit) |

Messages exceeding the rate are queued and sent at the maximum allowed rate. The queue depth is visible in **Dashboard > Inboxes > SMS > Queue**.

## Sending Messages

```typescript
// Simple text
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Your appointment is confirmed for March 15 at 2 PM.",
});

// With opt-out footer (recommended for marketing)
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Spring sale: 20% off all items! Shop now at example.com\n\nReply STOP to unsubscribe",
});
```

## Delivery Status

Masheev tracks delivery status via provider callbacks:

| Status | Meaning |
|--------|---------|
| `queued` | Accepted by Masheev, waiting to send |
| `sent` | Sent to carrier |
| `delivered` | Confirmed delivered to handset |
| `undelivered` | Carrier rejected (invalid number, opted out, etc.) |
| `failed` | Provider error |

Status updates fire `message.sent` and `message.failed` webhook events.
