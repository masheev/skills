// The Masheev plugin is declarative: openclaw.plugin.json supplies its skills and the hosted
// Masheev MCP server (OAuth). This entry registers nothing at runtime.
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "masheev",
  name: "Masheev",
  description:
    "Work your Masheev customer inbox from OpenClaw through the hosted Masheev MCP server.",
  register() {},
});
