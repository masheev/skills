---
name: masheev-channels
description: >-
  Use when integrating WhatsApp, SMS, email, voice, Instagram, or Google
  Reviews channels with Masheev. Covers channel-specific configuration,
  WhatsApp Business API template approval and 24-hour session windows,
  SMS compliance (TCPA opt-in/opt-out), email deliverability
  (SPF/DKIM/DMARC), voice agent setup with ElevenLabs, and Instagram
  webhook integration via Meta. Use this skill when someone asks about
  multi-channel messaging, channel-specific formatting, or setting up
  a new communication channel in Masheev.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev Channels

Masheev supports 7 communication channels. Each has unique setup requirements, message formatting rules, and compliance considerations.

## Supported Channels

| Channel | ID | Inbound | Outbound | Rich Media | Notes |
|---------|-----|---------|----------|------------|-------|
| Chat (Web Widget) | `chat` | Yes | Yes | Quick replies, cards | Default channel, via embed SDK |
| WhatsApp | `whatsapp` | Yes | Yes | Templates, media | Meta Business API, 24h session window |
| SMS | `sms` | Yes | Yes | Text only | TCPA compliance required |
| Email | `email` | Yes | Yes | HTML, attachments | SPF/DKIM/DMARC setup |
| Voice | `voice` | Yes | Yes | Audio | ElevenLabs integration |
| Instagram | `instagram` | Yes | Yes | Media, stories | Meta Graph API |
| Google Reviews | `google_reviews` | Yes | Yes | Text | Review response management |

## Channel Setup

Each channel is configured through an inbox. Create an inbox with the desired channel type:

```typescript
await apiClient.inboxes.create.mutate({
  name: "WhatsApp Support",
  channel: "whatsapp",
  // Channel-specific config varies
});
```

## Channel-Specific Details

See the reference file for each channel:

| Channel | Reference | Key Topics |
|---------|-----------|------------|
| WhatsApp | [references/whatsapp.md](./references/whatsapp.md) | Template approval, 24h windows, media types |
| SMS | [references/sms.md](./references/sms.md) | TCPA compliance, opt-in/opt-out, character limits |
| Email | [references/email.md](./references/email.md) | SPF/DKIM/DMARC, tracking, unsubscribe |
| Voice | [references/voice.md](./references/voice.md) | ElevenLabs setup, voice selection, SIP |

## Message Formatting by Channel

| Channel | Max Length | Media Support | Formatting |
|---------|-----------|---------------|------------|
| Chat | Unlimited | Images, files, cards, quick replies | Markdown |
| WhatsApp | 4096 chars | Images, video, documents, location | WhatsApp formatting (*bold*, _italic_) |
| SMS | 160 chars (1 segment) | None | Plain text |
| Email | Unlimited | HTML, inline images, attachments | HTML |
| Voice | N/A | Audio stream | Spoken text (TTS) |
| Instagram | 1000 chars | Images, video | Plain text |
| Google Reviews | 4096 chars | None | Plain text |

When sending messages via the API, Masheev automatically adapts formatting for the target channel. You send markdown; the channel receives the appropriate format.
