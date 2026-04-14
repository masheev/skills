---
name: masheev-mcp
description: >-
  Use when connecting Claude Code, Cursor, Copilot, or other AI coding
  tools to the Masheev API via MCP (Model Context Protocol). Covers
  installing the @masheev/mcp server, configuring authentication, and
  using the 4 available tools: list_api_endpoints, get_api_endpoint_schema,
  execute_api_endpoint, and get_api_categories. Use this skill when
  someone asks to "connect Masheev to Claude", "set up MCP for Masheev",
  or wants to manage Masheev from their AI coding environment.
license: Apache-2.0
metadata:
  author: masheev
  version: "0.1.0"
---

# Masheev MCP Server

Connect AI coding tools to Masheev via the Model Context Protocol. This lets Claude Code, Cursor, Copilot, and other MCP-compatible tools discover and call Masheev API endpoints.

## Installation

```bash
npm install -g @masheev/mcp
```

## Configuration

### Claude Code / Claude Desktop

Add to your MCP config (`.claude/mcp.json` or Claude Desktop settings):

```json
{
  "mcpServers": {
    "masheev": {
      "command": "masheev-mcp",
      "env": {
        "MASHEEV_API_BASE_URL": "https://api.masheev.com",
        "MASHEEV_API_TOKEN": "your_api_key_here"
      }
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "masheev": {
      "command": "npx",
      "args": ["-y", "@masheev/mcp"],
      "env": {
        "MASHEEV_API_BASE_URL": "https://api.masheev.com",
        "MASHEEV_API_TOKEN": "your_api_key_here"
      }
    }
  }
}
```

## Available Tools

| Tool | Description |
|------|-------------|
| `list_api_endpoints` | Search and browse all Masheev API endpoints. Accepts optional `query`, `category`, `tag`, `requiresAuth` filters. |
| `get_api_endpoint_schema` | Get the full OpenAPI schema for a specific endpoint (parameters, request/response types). |
| `execute_api_endpoint` | Execute an API endpoint with parameters. Handles routing (GET/DELETE -> query params, POST/PUT/PATCH -> body). |
| `get_api_categories` | List all API endpoint categories and their descriptions. |

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MASHEEV_API_BASE_URL` | No | `http://localhost:3015` | Masheev API URL |
| `MASHEEV_API_TOKEN` | No | - | API key for authenticated endpoints |
| `API_PORT` | No | `3015` | API port (alternative to full URL) |

## Example Usage

Once configured, ask your AI coding tool:

- "List all Masheev API endpoints related to contacts"
- "Show me the schema for creating a conversation"
- "Create a new webhook subscription for message events"
- "Get the billing balance for my organization"

The AI tool will use the MCP server to discover endpoints, understand their schemas, and execute them on your behalf.
