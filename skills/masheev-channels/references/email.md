# Email Channel Integration

## Setup

Create an email inbox by connecting a custom domain or forwarding address:

```typescript
await apiClient.inboxes.create.mutate({
  name: "Support Email",
  channel: "email",
  channelConfig: {
    email: {
      forwardingAddress: "support@myapp.com",
      fromName: "Acme Support",
      replyTo: "support@myapp.com",
    },
  },
});
```

Masheev provides a forwarding address (`{inbox-id}@inbound.masheev.com`). Configure your email provider to forward incoming mail to this address.

## Domain Authentication (SPF/DKIM/DMARC)

Proper authentication is critical for deliverability. Without it, emails land in spam.

### SPF (Sender Policy Framework)

Add Masheev's sending IPs to your domain's SPF record:

```
v=spf1 include:_spf.masheev.com ~all
```

### DKIM (DomainKeys Identified Mail)

Add the CNAME record provided in **Dashboard > Inboxes > Email > Domain Settings**:

```
masheev._domainkey.myapp.com  CNAME  masheev._domainkey.masheev.com
```

### DMARC

Set a DMARC policy to tell receivers how to handle unauthenticated mail:

```
_dmarc.myapp.com  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@myapp.com"
```

### Verification

After adding DNS records, verify domain authentication:

```typescript
const status = await apiClient.inboxes.verifyDomain.mutate({ id: "inb_..." });
// status: { spf: "pass", dkim: "pass", dmarc: "pass" }
```

All three must show `"pass"` before sending. Masheev checks every 15 minutes and emails you when verification completes.

## Sending Email Messages

```typescript
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Hi Jane,\n\nYour order has shipped! Track it here: https://track.example.com/abc\n\nBest,\nAcme Support",
  channelMeta: {
    email: {
      subject: "Your order has shipped",
      htmlBody: `
        <h2>Your order has shipped!</h2>
        <p>Hi Jane,</p>
        <p>Track your package: <a href="https://track.example.com/abc">Click here</a></p>
      `,
    },
  },
});
```

If `htmlBody` is provided, it is sent as the email body. The `content` field is used as the plain-text fallback. If only `content` is provided, Masheev wraps it in a minimal HTML template.

## HTML Email Guidelines

- Use table-based layouts for cross-client compatibility
- Inline CSS styles (no `<style>` blocks; many clients strip them)
- Max width: 600px for reliable rendering
- Images: use absolute URLs, include `alt` text, do not rely on images for critical content
- Test with Litmus or Email on Acid before sending templates at scale

## Attachments

```typescript
await apiClient.messages.create.mutate({
  conversationId: "conv_...",
  content: "Please find your invoice attached.",
  attachments: [
    {
      type: "file",
      url: "https://files.myapp.com/invoices/inv-123.pdf",
      filename: "invoice-2026-03.pdf",
      contentType: "application/pdf",
    },
  ],
  channelMeta: {
    email: { subject: "Your March invoice" },
  },
});
```

| Limit | Value |
|-------|-------|
| Max attachment size (per file) | 10 MB |
| Max attachments per message | 10 |
| Max total attachment size | 25 MB |
| Supported types | PDF, DOC, DOCX, XLS, XLSX, CSV, PNG, JPG, GIF, ZIP |

## Open and Click Tracking

Enable tracking per inbox in **Dashboard > Inboxes > Email > Tracking**:

- **Open tracking**: inserts a 1x1 transparent pixel. Reports `message.opened` webhook event.
- **Click tracking**: wraps links through `track.masheev.com`. Reports `message.link_clicked` with the original URL.

```typescript
// Query tracking stats
const stats = await apiClient.messages.getStats.query({ id: "msg_..." });
// stats: { opens: 3, uniqueOpens: 1, clicks: 2, uniqueClicks: 1 }
```

Tracking is disabled by default. When enabled, the tracking pixel and link wrapping are added automatically.

## Unsubscribe Handling

Masheev adds RFC 8058 `List-Unsubscribe` and `List-Unsubscribe-Post` headers to all outbound marketing emails:

```
List-Unsubscribe: <https://api.masheev.com/unsubscribe/{token}>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

When a recipient clicks "Unsubscribe" in their email client:
1. Masheev updates `contact.consent.channels.email` to `"opted_out"`
2. Fires `contact.updated` webhook
3. Blocks future marketing emails to that contact

For transactional emails (order confirmations, password resets), set `transactional: true` to skip unsubscribe headers:

```typescript
channelMeta: {
  email: {
    subject: "Password reset",
    transactional: true,  // No unsubscribe header
  },
}
```

## Bounce Handling

Masheev processes bounce notifications automatically:

| Type | Meaning | Action |
|------|---------|--------|
| Hard bounce | Invalid address, domain not found | Marks contact email as invalid; stops sending |
| Soft bounce | Mailbox full, server temporarily unavailable | Retries 3 times over 24h; marks as soft bounce |
| Complaint | Recipient marked as spam | Marks contact as `opted_out`; fires webhook |

Bounce and complaint rates are tracked in **Dashboard > Inboxes > Email > Health**. Keep bounce rate under 2% and complaint rate under 0.1% to maintain deliverability.

## Delivery Status

| Status | Description |
|--------|-------------|
| `queued` | Accepted by Masheev |
| `sent` | Sent to recipient's mail server |
| `delivered` | Accepted by recipient's server (not guaranteed inbox) |
| `bounced` | Hard or soft bounce |
| `complained` | Marked as spam by recipient |
| `opened` | Tracking pixel loaded (if tracking enabled) |
| `clicked` | Link clicked (if tracking enabled) |
