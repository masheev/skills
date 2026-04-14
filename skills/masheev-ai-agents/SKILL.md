---
name: masheev-ai-agents
description: >-
  Use when configuring Masheev AI agents — system prompts, model selection,
  tool assignment, knowledge base integration, guardrails, escalation
  triggers, and voice agent setup with ElevenLabs. Covers the AI agent
  entity, how agents connect to inboxes, prompt engineering for support
  agents, and the relationship between AI agents (intelligence) and
  voice agents (TTS/STT). Use this skill when someone asks to "set up an
  AI agent", "configure the chatbot", "write a system prompt", "add tools
  to the agent", "connect knowledge base", or "set up voice AI".
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev AI Agents

AI Agents are the intelligence layer behind Masheev conversations. An agent defines what the AI knows, what tools it can use, when to escalate, and how it behaves.

## Architecture

```
Inbox (channel endpoint)
  └── AI Agent (intelligence)
        ├── System prompt
        ├── Tools (built-in + integration + client)
        ├── Knowledge base sources
        ├── Guardrails
        └── Voice config → Voice Agent (ElevenLabs TTS/STT)
```

- **Inbox** = where conversations arrive (chat, WhatsApp, email, etc.)
- **AI Agent** = the brain (prompt, tools, knowledge, rules)
- **Voice Agent** = the voice (text-to-speech, speech-to-text via ElevenLabs)
- One inbox has one AI agent. One AI agent can serve multiple inboxes.

## Managing AI Agents

### Via Dashboard

**Settings > AI Agents > Create Agent**

### Via API

```typescript
import { apiClient } from "@masheev/client/server";

// Create
const agent = await apiClient.aiAgents.create.mutate({
  name: "Support Bot",
  model: "claude-sonnet-4-5",
  instructions: "You are a helpful support agent for Acme Inc...",
});

// Assign to inbox
await apiClient.inboxes.update.mutate({
  id: "inb_...",
  aiAgentId: agent.id,
});

// Update
await apiClient.aiAgents.update.mutate({
  id: agent.id,
  instructions: "Updated system prompt...",
});

// List
const agents = await apiClient.aiAgents.list.query({});
```

## System Prompt Best Practices

Structure your system prompt with clear sections:

```
You are [Agent Name], a support agent for [Company].

## Role
- Help customers with [domain] questions
- Be friendly, concise, and accurate

## Knowledge
- Use the knowledge base to answer product questions
- If you don't know something, say so — don't guess

## Guardrails
- Never share internal pricing or competitor comparisons
- Never promise features that don't exist
- Never share other customers' data

## Escalation
- Escalate to a human when:
  - The customer is upset or frustrated
  - The issue requires account access you don't have
  - You've been unable to resolve after 3 attempts

## Tools
- Use check_availability before suggesting appointment times
- Use create_booking only after the customer confirms
```

## Tool Tiers

| Tier | Source | Examples | Configured Via |
|------|--------|----------|----------------|
| Built-in | Platform | resolve_conversation, set_priority, assign_to_human, send_message | Dashboard (always available) |
| Integration | Third-party adapters | Google Calendar, Tableport, Google Reviews | Dashboard > Integrations |
| Client | Browser-side SDK | search_products, create_order (your code) | `tools` in SDK config |

## Knowledge Base Integration

Connect knowledge sources so the AI can answer questions from your docs:

```typescript
// Add a knowledge source
await apiClient.knowledge.create.mutate({
  inboxId: "inb_...",
  type: "webpage",
  url: "https://docs.myapp.com",
});

// Trigger re-crawl
await apiClient.knowledge.sync.mutate({ id: "knowledge_source_id" });
```

The AI automatically searches the knowledge base when it doesn't have an answer from its system prompt.

## Escalation

The AI automatically escalates when:
- Confidence drops below 0.7 (configurable)
- Customer sentiment is negative after multiple exchanges
- The system prompt's escalation rules are triggered

Escalation assigns the conversation to a human agent or team, and fires the `escalation.created` webhook event.

## Voice Agents

Voice agents handle speech-to-text and text-to-speech via ElevenLabs:

- **AI Agent** = what to say (prompt, tools, knowledge)
- **Voice Agent** = how to say it (voice selection, latency settings, language)
- Link them: `aiAgent.channelConfig.voice.voiceAgentId`

Voice agents are configured in the dashboard: **Settings > Voice Agents**

See [references/prompts.md](./references/prompts.md) for example system prompts by industry.
See [references/tools.md](./references/tools.md) for built-in tool reference.
