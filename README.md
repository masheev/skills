# Masheev Skills

Official [Agent Skills](https://agentskills.io) for integrating [Masheev](https://masheev.com) into your applications.

These skills help AI coding agents (Claude Code, Cursor, Copilot, Codex, and 40+ others) guide you through adding Masheev chat, webhooks, API, AI agents, and more to your codebase.

## Install

```bash
# All skills
npx skills add masheev/skills

# Essentials only (widget + webhooks + API)
npx skills add masheev/skills --skill masheev-widget --skill masheev-webhooks --skill masheev-api
```

## Skills

### Essentials

| Skill | Description |
|-------|-------------|
| [masheev-widget](./skills/masheev-widget/) | Install and configure the Masheev chat widget in any framework |
| [masheev-webhooks](./skills/masheev-webhooks/) | Set up and verify Masheev webhook events |
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
