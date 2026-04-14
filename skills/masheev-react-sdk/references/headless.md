# Advanced Headless Patterns

## Custom Message Bubble Components

```tsx
import { useWidgetChat, useWidgetSession } from "@masheev/embed-sdk/headless";

function ChatMessages() {
  const { messages, isStreaming } = useWidgetChat();
  const { greeting } = useWidgetSession();

  return (
    <div className="flex flex-col gap-2 p-4">
      {greeting && <SystemBubble text={greeting} />}
      {messages.map((msg) => {
        switch (msg.role) {
          case "contact": return <UserBubble key={msg.id} message={msg} />;
          case "ai": return <AIBubble key={msg.id} message={msg} isLast={msg === messages.at(-1)} />;
          case "agent": return <AgentBubble key={msg.id} message={msg} />;
          default: return null;
        }
      })}
      {isStreaming && <TypingIndicator />}
    </div>
  );
}

function UserBubble({ message }: { message: ChatMessage }) {
  return (
    <div className="ml-auto max-w-[80%] rounded-2xl rounded-br-sm bg-blue-600 px-4 py-2 text-white">
      {message.content}
      <span className="mt-1 block text-xs opacity-60">{new Date(message.createdAt).toLocaleTimeString()}</span>
    </div>
  );
}

function AIBubble({ message, isLast }: { message: ChatMessage; isLast: boolean }) {
  return (
    <div className="mr-auto max-w-[80%] rounded-2xl rounded-bl-sm bg-gray-100 px-4 py-2">
      <MarkdownRenderer content={message.content} />
      {message.components?.quickReplies && isLast && <QuickReplies replies={message.components.quickReplies} />}
      {message.components?.card && <CardComponent card={message.components.card} />}
    </div>
  );
}
```

## Streaming Message Display

Show AI responses character-by-character as they stream in:

```tsx
function StreamingChat() {
  const { messages, isStreaming, streamingContent } = useWidgetChat();

  return (
    <div className="flex flex-col gap-2">
      {messages.map((msg) => <MessageBubble key={msg.id} message={msg} />)}
      {isStreaming && streamingContent && (
        <div className="mr-auto max-w-[80%] rounded-2xl bg-gray-100 px-4 py-2">
          <MarkdownRenderer content={streamingContent} />
          <span className="inline-block h-4 w-1 animate-pulse bg-gray-400" />
        </div>
      )}
    </div>
  );
}
```

`streamingContent` updates in real-time. Once complete, it moves to `messages` and becomes `null`.

## Reconnection Handling

```tsx
import { useWidgetSocket, useWidgetChat } from "@masheev/embed-sdk/headless";

function ConnectionAwareChat() {
  const { status, reconnect } = useWidgetSocket();
  const { messages, sendMessage } = useWidgetChat();

  if (status === "disconnected") {
    return (
      <div className="p-8 text-center">
        <p className="text-gray-500">Connection lost.</p>
        <button onClick={reconnect} className="mt-3 rounded-lg bg-blue-600 px-4 py-2 text-white">Reconnect</button>
      </div>
    );
  }

  return (
    <div>
      {status === "reconnecting" && <div className="bg-yellow-50 px-3 py-1 text-center text-xs text-yellow-700">Reconnecting...</div>}
      <MessageList messages={messages} />
      <ChatInput onSend={sendMessage} disabled={status !== "connected"} />
    </div>
  );
}
```

States: `"connecting"` | `"connected"` | `"reconnecting"` | `"disconnected"`. Auto-reconnects with exponential backoff (max 30s). After 5 failures, stops. Call `reconnect()` to restart.

## Custom File Upload UI

```tsx
function FileUploadInput() {
  const { sendMessage, uploadFile } = useWidgetChat();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const attachment = await uploadFile(file, { onProgress: (pct) => setProgress(pct) });
      await sendMessage("", { attachments: [attachment] });
    } finally {
      setUploading(false);
      setProgress(0);
    }
  };

  return (
    <>
      <input ref={fileInputRef} type="file" onChange={handleFileSelect} className="hidden" accept="image/*,.pdf,.doc,.docx" />
      <button onClick={() => fileInputRef.current?.click()} disabled={uploading}>{uploading ? `${progress}%` : "Attach"}</button>
    </>
  );
}
```

Supported: images (PNG, JPG, GIF, WebP), documents (PDF, DOC, DOCX), spreadsheets (XLS, XLSX, CSV). Max 10 MB.

## Markdown Rendering

```tsx
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

function MarkdownRenderer({ content }: { content: string }) {
  return (
    <ReactMarkdown remarkPlugins={[remarkGfm]} components={{
      a: ({ href, children }) => <a href={href} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">{children}</a>,
      code: ({ className, children }) => className?.startsWith("language-")
        ? <pre className="my-2 overflow-x-auto rounded-lg bg-gray-900 p-3 text-sm text-gray-100"><code>{children}</code></pre>
        : <code className="rounded bg-gray-200 px-1 py-0.5 text-sm">{children}</code>,
      ul: ({ children }) => <ul className="ml-4 list-disc">{children}</ul>,
      ol: ({ children }) => <ol className="ml-4 list-decimal">{children}</ol>,
    }}>{content}</ReactMarkdown>
  );
}
```

## Theming with CSS Variables

The headless SDK injects no styles. Use CSS variables for theming. For dark mode, swap the values:

```tsx
function ChatContainer({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ "--chat-primary": "#2563eb", "--chat-bg": "#fff", "--chat-bubble-user": "#2563eb", "--chat-bubble-ai": "#f3f4f6", "--chat-text": "#111827", "--chat-border": "#e5e7eb" } as React.CSSProperties}>
      {children}
    </div>
  );
}
```

## Quick Replies Component

```tsx
function QuickReplies({ replies }: { replies: { label: string; value: string }[] }) {
  const { sendMessage } = useWidgetChat();
  return (
    <div className="mt-2 flex flex-wrap gap-2">
      {replies.map((r) => (
        <button key={r.value} onClick={() => sendMessage(r.value)} className="rounded-full border border-blue-200 bg-white px-3 py-1 text-sm text-blue-600 hover:bg-blue-50">{r.label}</button>
      ))}
    </div>
  );
}
```

## Card Component

Render rich card responses from tool results:

```tsx
function CardComponent({ card }: { card: { title: string; subtitle?: string; fields?: { label: string; value: string }[]; actions?: { label: string; url: string }[] } }) {
  return (
    <div className="mt-2 rounded-xl border border-gray-200 p-3">
      <h4 className="font-semibold">{card.title}</h4>
      {card.subtitle && <p className="text-sm text-gray-500">{card.subtitle}</p>}
      {card.fields?.map((f) => <div key={f.label} className="mt-1 flex justify-between text-sm"><span className="text-gray-500">{f.label}</span><span className="font-medium">{f.value}</span></div>)}
      {card.actions && <div className="mt-3 flex gap-2">{card.actions.map((a) => <a key={a.url} href={a.url} target="_blank" rel="noopener noreferrer" className="rounded-lg bg-blue-600 px-3 py-1.5 text-sm text-white">{a.label}</a>)}</div>}
    </div>
  );
}
```
