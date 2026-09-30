# Masheev Skills

Official [Agent Skills](https://agentskills.io) for integrating [Masheev](https://masheev.com) into your applications.

These skills help AI coding agents (Claude Code, Cursor, Copilot, Codex, and 40+ others) plan and implement Masheev chat, business tools, API access, and AI agents in your codebase.

## Start here: integrate your business

Install the entry skill in your application's repository:

```bash
npx skills add masheev/skills --skill masheev-integrate
```

Then ask your coding agent:

> Integrate Masheev into my business. Inspect this repository and its existing
> services, plan the integration, implement it, and verify it works. Ask me only
> for information or access you cannot discover.

[masheev-integrate](./skills/masheev-integrate/) discovers the app, chooses an
integration path, implements it, and checks the customer journey. It includes
its own references; installing the other skills is optional. It reuses existing
resources and identifies any account sign-in or provider approval still needed.

Developer SDK/MCP access is beta. Generic custom webhooks, legacy rules, long-delay
steps and several native connectors are currently unavailable. Some older
specialist examples predate these limits; verify account capabilities and current
API/package contracts before using them.

Prefer one link instead? Give your agent [the integration guide](https://docs.masheev.com/integrate.md).

## Optional specialist skills

```bash
# All skills
npx skills add masheev/skills

# Widget and API reference skills
npx skills add masheev/skills --skill masheev-widget --skill masheev-api
```

## Skills

### Essentials

| Skill | Description |
|-------|-------------|
| [masheev-integrate](./skills/masheev-integrate/) | Start here: inspect, plan, implement and verify a business integration |
| [masheev-widget](./skills/masheev-widget/) | Install and configure the Masheev chat widget in any framework |
| [masheev-webhooks](./skills/masheev-webhooks/) | Historical webhook reference; custom delivery is not launched |
| [masheev-api](./skills/masheev-api/) | Server-side API for contacts, conversations, messages, and more |

### Advanced

| Skill | Description |
|-------|-------------|
| [masheev-react-sdk](./skills/masheev-react-sdk/) | Build custom chat UIs with the React SDK and headless hooks |
| [masheev-client-tools](./skills/masheev-client-tools/) | Define browser-side tools the AI agent can invoke |
| [masheev-workflows](./skills/masheev-workflows/) | Multi-step conversational workflows with context and branching |
| [masheev-ai-agents](./skills/masheev-ai-agents/) | Configure AI agents, prompts, tools, guardrails, and escalation |
| [masheev-mcp](./skills/masheev-mcp/) | Connect Claude, Cursor, or other AI tools to Masheev via MCP |
| [masheev-channels](./skills/masheev-channels/) | WhatsApp, SMS, email, voice, and Instagram channel integration |
| [masheev-automations](./skills/masheev-automations/) | Rules, triggers, and automation workflows |

## Links

- [Masheev Documentation](https://docs.masheev.com)
- [Masheev Dashboard](https://app.masheev.com)
- [npm: @masheev/embed-sdk](https://www.npmjs.com/package/@masheev/embed-sdk)
- [npm: @masheev/client](https://www.npmjs.com/package/@masheev/client)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on adding or improving skills.

## License

Apache-2.0
