# Masheev Skills

Official [Agent Skills](https://agentskills.io) for [Masheev](https://masheev.com). This repository is the
single source for every Masheev skill and the agent-host manifests that ship them.

| For | Skills | What they do |
|-----|--------|--------------|
| Developers | [masheev-integrate](./skills/masheev-integrate/) and the [specialist skills](#skills) | Help AI coding agents (Claude Code, Cursor, Copilot, Codex, and 40+ others) implement Masheev chat, API access, and AI agents in your codebase |
| Operators | [Operator skills](#operate-your-workspace-from-an-ai-assistant) | Let an AI assistant work a connected Masheev workspace: triage the inbox, draft replies a human approves, tune AI agents |

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

## Operate your workspace from an AI assistant

These skills drive a connected Masheev workspace through the Masheev MCP server
(`https://api.masheev.com/api/agents/mcp`, OAuth) or the `masheev` CLI. Replies always go
through a draft that a human approves before anything is sent.

| Skill | Description |
|-------|-------------|
| [masheev-inbox-triage](./skills/masheev-inbox-triage/) | Find conversations that need a human, then assign, tag, set status and leave notes; never messages customers |
| [masheev-reply-with-review](./skills/masheev-reply-with-review/) | Draft a reply, show it, and send only after a human approves that exact draft |
| [masheev-agent-tuning](./skills/masheev-agent-tuning/) | Review an AI agent against real conversations and apply approved instruction or knowledge changes |
| [masheev-cli](./skills/masheev-cli/) | Operate Masheev from the terminal with the `masheev` CLI |

## Install by host

| Host | Install |
|------|---------|
| Any agent ([skills.sh](https://skills.sh)) | `npx skills add masheev/skills --skill masheev-inbox-triage --skill masheev-reply-with-review` |
| Claude Code | `/plugin install masheev --marketplace masheev/skills` (operator skills plus the MCP server); developer bundles: `masheev-integrate`, `masheev-essentials`, `masheev-advanced` |
| Codex | `codex plugin marketplace add masheev/skills`, then `codex plugin add masheev@masheev` (all skills plus the MCP server; [`plugin.json`](./plugin.json) and [`mcp.json`](./mcp.json)) |
| Grok Build | install `masheev` once listed in the [xAI plugin marketplace](https://github.com/xai-org/plugin-marketplace) (all skills plus the MCP server; [`.grok-plugin/plugin.json`](./.grok-plugin/plugin.json) and [`.mcp.json`](./.mcp.json)) |
| OpenClaw | `openclaw plugins install clawhub:@masheev/masheev` once listed on [ClawHub](https://clawhub.ai/masheev). The plugin is [`openclaw.plugin.json`](./openclaw.plugin.json): the hosted MCP server plus the operator skills |
| Hermes Agent | `hermes skills tap add masheev/skills`; merge [`hermes/config.yaml`](./hermes/config.yaml) into `~/.hermes/config.yaml`, then `hermes mcp login masheev` |

Operator skills need the MCP server connected in the host. Setup per host:
https://docs.masheev.com/agents

## Links

- [Masheev Documentation](https://docs.masheev.com)
- [Masheev Dashboard](https://app.masheev.com)
- [npm: @masheev/embed-sdk](https://www.npmjs.com/package/@masheev/embed-sdk)
- [npm: @masheev/client](https://www.npmjs.com/package/@masheev/client)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on adding or improving skills.

## License

Apache-2.0 in this repository. ClawHub distributes every published skill under
[MIT-0](https://spdx.org/licenses/MIT-0.html), so copies installed from ClawHub carry MIT-0.
