# Integration patterns and availability

Availability snapshot: 2026-09-30. Recheck current account eligibility and release
behavior. Source for maintainers: the Masheev product repository's
`packages/shared/src/config/launch-scope.ts`. A schema or installed package can
contain features that are disabled in production.

## Pick the appropriate path

| Business need | Implementation path | Important boundary |
| --- | --- | --- |
| Answer questions on a website | Chat inbox, AI agent, relevant knowledge, standard embed | Start here for web support; no management API key belongs in the browser |
| Look up orders or customer records | Widget client tool → existing authenticated app route → existing service client | The backend derives identity and tenant; do not trust model-supplied ownership |
| Book or change something from web chat | Same app adapter, with server validation and idempotency | Preserve business confirmation; report actual result, not assumed success |
| Configure Masheev resources | Verified supported API or connected MCP; dashboard fallback | Confirm organization, permission, full input schema, and returned resource IDs |
| Sync CRM data into Masheev | Application-owned backend calling supported contact APIs | Define source of truth, stable external IDs and update direction; avoid sync loops |
| React to every Masheev event | Requires a supported event-delivery mechanism | Generic durable outgoing webhooks are currently off; do not promise real-time sync |
| Custom chat interface | Embed SDK headless entry point | More implementation and verification than the standard widget |
| Voice, SMS, or unattended service actions | Supported server-side channel/integration path | Browser tools are not available on these channels |

An app-owned backend integration with Shopify, Stripe, HubSpot, or Salesforce
is custom application code, not a native Masheev connector. Implement it only
when it meets the requested journey and the existing application can authorize it.

## Current scope

- Launch: web chat, AI agents, knowledge, supported organization-scoped API,
  supported immediate automations; configured voice/SMS; TablePort and Twilio/
  ElevenLabs BYOK integrations.
- Beta/account or provider dependent: developer SDK/MCP surfaces, email,
  WhatsApp, Instagram, Google Reviews, Google Calendar/Meet and Microsoft
  calendar/email. A plan entitlement alone does not clear a provider gate.
- Off: generic inbound/durable outgoing custom webhooks, Slack integration,
  native Shopify/HubSpot/Salesforce adapters, customer-facing Stripe agent tools,
  legacy rules evaluator, long-delay workflow steps, proactive campaigns, SSO.

Do not activate off features based on old examples. If a requested journey needs
one, explain the dependency and finish the supported portion without substituting
a materially different behavior silently.

## SDK and API discovery

The public package `@masheev/embed-sdk` has `/js`, `/react`, and `/headless`
entry points. Verify the installed version and exports. Use the project's package
manager to install it, and commit its normal lockfile changes.

Minimal React mount (add the framework's client boundary when required):

```tsx
import { useMasheev } from "@masheev/embed-sdk/react";

export function BusinessAssistant({ inboxId }: { inboxId: string }) {
  useMasheev({ inboxId });
  return null;
}
```

Mount once with a real inbox ID. The inbox ID is public configuration; the inbox
HMAC secret is not. Read the installed SDK's user identity/tool types before
extending the mount. For non-React apps, use `init` and lifecycle cleanup with
`destroy` from `/js` in the browser.

`@masheev/client` is the typed management client. Do not copy old examples that
import `apiClient` from `/server`: the reviewed source exports `serverApi` and
`createServerApiClients`. The 2026-09-30 source also does not pass the factory's
base URL/key into the tRPC transport. Verify the installed release with an
organization read before relying on it for provisioning. Do not change a
customer's application to bypass permission checks.

The reviewed API context verifies organization API keys from `X-API-Key` and
requires organization metadata and permissions. A Bearer session token and an
organization API key are not interchangeable. Verify the deployed schema and
header contract for the intended operation.

`@masheev/mcp` currently exposes endpoint search, schema lookup, execution, and
categories over stdio. Set its API base URL explicitly: its default is localhost.
It is not a hosted OAuth onboarding service. The reviewed implementation sends
Bearer credentials and omits request-body schemas in discovery, so verify its
capabilities rather than treating a successful connection as provisioning access.
Use the API's full OpenAPI specification for missing schemas; if unavailable,
use the dashboard for that resource instead of inventing a payload.

## Read only the documentation needed

- [Developer documentation](https://docs.masheev.com): SDK and API reference;
  use `/llms.txt` to discover clean `.md` versions of the relevant guides.
- [Public skills repository](https://github.com/masheev/skills): optional specialist
  guidance and references, accessible without installing every skill. Verify its
  examples against installed types, current schemas, and availability above.
- [Masheev dashboard](https://app.masheev.com): workspace setup and provider
  authorization when API access is unavailable or a human sign-in is necessary.

If none of these supplies the missing contract, identify that dependency precisely
and continue work that does not require it. Do not invent a `masheev init` CLI,
remote MCP URL, login command, or account capability endpoint.
