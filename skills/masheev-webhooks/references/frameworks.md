# Webhook Handlers by Framework

## Express

```typescript
import express from "express";
import crypto from "node:crypto";

const app = express();

// Raw body is required for signature verification
app.post(
  "/webhooks/masheev",
  express.raw({ type: "application/json" }),
  (req, res) => {
    const rawBody = req.body.toString();
    const signature = req.headers["x-webhook-signature"] as string;

    const expected = crypto
      .createHmac("sha256", process.env.MASHEEV_WEBHOOK_SECRET!)
      .update(rawBody)
      .digest("hex");

    if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
      return res.status(401).send("Invalid signature");
    }

    const event = JSON.parse(rawBody);
    console.log(`Received ${event.type}:`, event.payload);

    res.sendStatus(200);
  },
);
```

## Hono

```typescript
import { Hono } from "hono";
import crypto from "node:crypto";

const app = new Hono();

app.post("/webhooks/masheev", async (c) => {
  const rawBody = await c.req.text();
  const signature = c.req.header("x-webhook-signature");

  if (!signature) return c.text("Missing signature", 401);

  const expected = crypto
    .createHmac("sha256", process.env.MASHEEV_WEBHOOK_SECRET!)
    .update(rawBody)
    .digest("hex");

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    return c.text("Invalid signature", 401);
  }

  const event = JSON.parse(rawBody);
  console.log(`Received ${event.type}:`, event.payload);

  return c.text("OK");
});
```

## Next.js App Router

```typescript
// app/api/webhooks/masheev/route.ts
import crypto from "node:crypto";

export async function POST(request: Request) {
  const rawBody = await request.text();
  const signature = request.headers.get("x-webhook-signature");

  if (!signature) {
    return new Response("Missing signature", { status: 401 });
  }

  const expected = crypto
    .createHmac("sha256", process.env.MASHEEV_WEBHOOK_SECRET!)
    .update(rawBody)
    .digest("hex");

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    return new Response("Invalid signature", { status: 401 });
  }

  const event = JSON.parse(rawBody);
  console.log(`Received ${event.type}:`, event.payload);

  return new Response("OK", { status: 200 });
}
```

## Next.js Pages Router

```typescript
// pages/api/webhooks/masheev.ts
import type { NextApiRequest, NextApiResponse } from "next";
import crypto from "node:crypto";

// Disable body parsing to get raw body
export const config = { api: { bodyParser: false } };

function getRawBody(req: NextApiRequest): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks).toString()));
    req.on("error", reject);
  });
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") return res.status(405).end();

  const rawBody = await getRawBody(req);
  const signature = req.headers["x-webhook-signature"] as string;

  if (!signature) return res.status(401).send("Missing signature");

  const expected = crypto
    .createHmac("sha256", process.env.MASHEEV_WEBHOOK_SECRET!)
    .update(rawBody)
    .digest("hex");

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    return res.status(401).send("Invalid signature");
  }

  const event = JSON.parse(rawBody);
  console.log(`Received ${event.type}:`, event.payload);

  res.status(200).send("OK");
}
```

## Fastify

```typescript
import Fastify from "fastify";
import crypto from "node:crypto";

const fastify = Fastify();

// Parse JSON as string to preserve raw body
fastify.addContentTypeParser(
  "application/json",
  { parseAs: "string" },
  (req, body, done) => done(null, body),
);

fastify.post("/webhooks/masheev", async (request, reply) => {
  const rawBody = request.body as string;
  const signature = request.headers["x-webhook-signature"] as string;

  if (!signature) return reply.code(401).send("Missing signature");

  const expected = crypto
    .createHmac("sha256", process.env.MASHEEV_WEBHOOK_SECRET!)
    .update(rawBody)
    .digest("hex");

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    return reply.code(401).send("Invalid signature");
  }

  const event = JSON.parse(rawBody);
  console.log(`Received ${event.type}:`, event.payload);

  return reply.code(200).send("OK");
});
```
