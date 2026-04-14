# Contacts API

## List Contacts

```typescript
const result = await apiClient.contacts.list.query({
  search: "jane",          // Optional: search by name, email, phone
  limit: 50,               // Default: 50, max: 200
  cursor: undefined,       // Cursor from previous page
});
// result: { items: Contact[], nextCursor?: string }
```

## Get Contact

```typescript
const contact = await apiClient.contacts.get.query({ id: "con_..." });
```

## Create Contact

```typescript
const contact = await apiClient.contacts.create.mutate({
  name: "Jane Doe",
  email: "jane@example.com",
  phone: "+1234567890",
  company: "Acme Inc",
  customAttributes: {
    plan: "pro",
    signupDate: "2026-01-15",
  },
});
```

## Update Contact

```typescript
await apiClient.contacts.update.mutate({
  id: "con_...",
  name: "Jane Smith",
  customAttributes: {
    plan: "enterprise",
  },
});
```

## Merge Contacts

Merge duplicate contacts. The winner keeps all data; the loser's conversations move to the winner.

```typescript
await apiClient.contacts.merge.mutate({
  winnerId: "con_...",   // Contact that survives
  loserId: "con_...",    // Contact that gets merged in
});
```

## GDPR Delete

Anonymize a contact and all their data. Irreversible.

```typescript
await apiClient.contacts.gdpr.delete.mutate({
  contactId: "con_...",
});
```

This anonymizes:
- Contact name, email, phone -> `[DELETED]`
- All message content from this contact -> `[DELETED_USER]`
- Audit log references -> `[DELETED_USER]`

## Contact Schema

```typescript
interface Contact {
  id: string;                    // "con_..."
  orgId: string;
  name?: string;
  email?: string;
  phone?: string;
  avatar?: string;
  company?: string;
  firstSeenAt: string;           // ISO 8601
  lastSeenAt: string;
  conversationCount: number;
  lifecycleStage?: string;
  tags: string[];
  customAttributes: Record<string, unknown>;
  consent: {
    dataProcessing?: boolean;
    marketing?: boolean;
    channels?: Record<string, "opted_in" | "opted_out" | "not_set">;
  };
  externalIds: Record<string, string>;  // e.g., { stripe: "cus_...", hubspot: "123" }
  createdAt: string;
  updatedAt: string;
}
```
