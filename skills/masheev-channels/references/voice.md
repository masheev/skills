# Voice Channel Integration

## Architecture

Voice in Masheev uses a two-layer design:

- **AI Agent** = the brain (system prompt, tools, knowledge, guardrails)
- **Voice Agent** = the mouth and ears (TTS/STT via ElevenLabs)

The AI Agent decides *what* to say. The Voice Agent controls *how* it sounds. One AI Agent can power both text and voice conversations across multiple inboxes.

```
Incoming call (SIP/phone)
  └── Voice Agent (ElevenLabs)
        ├── Speech-to-Text (STT) → transcribes caller
        ├── AI Agent (Masheev) → generates response
        └── Text-to-Speech (TTS) → speaks response
```

## Voice Agent Setup

### Via Dashboard

**Settings > Voice Agents > Create Voice Agent**

Select a voice, configure latency and language, then link to an AI Agent.

### Via API

```typescript
const voiceAgent = await apiClient.voiceAgents.create.mutate({
  name: "Support Voice",
  voiceId: "rachel",                // ElevenLabs voice ID
  model: "eleven_turbo_v2_5",      // ElevenLabs model
  language: "en",
  firstMessage: "Hello, thank you for calling Acme support. How can I help you?",
  stability: 0.5,                  // 0-1: lower = more expressive
  similarityBoost: 0.75,           // 0-1: higher = closer to original voice
});
```

### Linking Voice Agent to AI Agent

```typescript
await apiClient.aiAgents.update.mutate({
  id: "agent_...",
  channelConfig: {
    voice: {
      voiceAgentId: voiceAgent.id,
    },
  },
});
```

### Linking AI Agent to Inbox

```typescript
await apiClient.inboxes.create.mutate({
  name: "Phone Support",
  channel: "voice",
  aiAgentId: "agent_...",
  channelConfig: {
    voice: {
      phoneNumber: "+15551234567",
      provider: "twilio",           // SIP provider
    },
  },
});
```

## Voice Selection

ElevenLabs provides pre-made and cloned voices:

| Voice | Style | Best For |
|-------|-------|----------|
| `rachel` | Calm, professional | Customer support |
| `adam` | Confident, clear | Sales, outbound |
| `bella` | Warm, friendly | Hospitality, healthcare |
| `antoni` | Energetic | Marketing, promotions |
| `custom` | Cloned from audio | Brand-specific voice |

Browse all available voices in **Dashboard > Voice Agents > Voice Library** or via the ElevenLabs voice library.

### Custom Voice Cloning

Upload audio samples (minimum 30 seconds of clean speech) through the ElevenLabs dashboard. Use the resulting voice ID in your voice agent config.

## ElevenLabs Models

| Model | Latency | Quality | Use Case |
|-------|---------|---------|----------|
| `eleven_turbo_v2_5` | ~300ms | Good | Real-time conversations (recommended) |
| `eleven_multilingual_v2` | ~500ms | Best | Multi-language, highest quality |
| `eleven_monolingual_v1` | ~250ms | Good | English-only, lowest latency |

For phone conversations, `eleven_turbo_v2_5` is recommended. The latency difference is noticeable in real-time dialogue.

## SIP Integration

Masheev connects to phone networks via SIP (Session Initiation Protocol):

```
PSTN (phone network) → SIP trunk (Twilio/Telnyx) → Masheev → ElevenLabs
```

### Twilio SIP Trunk Setup

1. Create a SIP trunk in Twilio console
2. Point the trunk's origination URI to `sip:{inboxId}@voice.masheev.com`
3. Configure the inbox with your Twilio credentials
4. Assign a phone number to the SIP trunk

Caller ID is available via `system__caller_id` in the SIP headers. ElevenLabs receives this automatically for personalized greetings.

## Latency Considerations

Total voice response latency = STT + AI processing + TTS + network:

| Component | Typical Latency |
|-----------|----------------|
| STT (speech-to-text) | 100-200ms |
| AI response generation | 200-500ms |
| TTS (text-to-speech) | 200-400ms |
| Network round-trip | 50-100ms |
| **Total** | **550-1200ms** |

### Reducing Latency

- Use `eleven_turbo_v2_5` model (fastest TTS)
- Keep system prompts concise (shorter prompts = faster AI inference)
- Use `claude-haiku-3-5` for the AI agent model when speed matters more than depth
- Enable streaming TTS (default) so speech starts before the full response is generated
- Deploy in the region closest to your users

## Language Support

ElevenLabs supports 29 languages. Set the language on the voice agent:

```typescript
await apiClient.voiceAgents.update.mutate({
  id: voiceAgent.id,
  language: "es",  // Spanish
  model: "eleven_multilingual_v2",  // Required for non-English
});
```

Common languages: `en`, `es`, `fr`, `de`, `it`, `pt`, `nl`, `pl`, `ja`, `ko`, `zh`, `ar`, `hi`, `tr`, `ru`, `sv`, `da`, `fi`, `no`.

Use `eleven_multilingual_v2` for non-English languages. The monolingual model only supports English.

## Voice-Specific Prompt Tips

When writing system prompts for voice agents:

- Keep responses short (1-3 sentences). Long responses sound unnatural in speech.
- Avoid markdown, links, or formatted lists. The TTS reads them literally.
- Use conversational phrasing: "Let me check that for you" not "Querying database..."
- Include filler phrases for long operations: "One moment please..." before tool calls.
- Spell out abbreviations the TTS might mispronounce: "appointment" not "appt".
- Use SSML tags sparingly for emphasis or pauses when needed:

```
<break time="500ms"/> Let me look that up for you.
```

## Call Events

Voice conversations fire standard conversation and message events, plus:

| Event | When |
|-------|------|
| `conversation.created` | Call connected |
| `message.received` | Caller speech transcribed |
| `message.sent` | AI response spoken |
| `conversation.closed` | Call ended |

The `message.received` payload includes the STT transcript in `content`. The `message.sent` payload includes the AI-generated text that was spoken.
