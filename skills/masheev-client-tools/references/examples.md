# Client Tool Examples

Complete examples of client-side tools for common use cases. All examples use `clientTool` from `@masheev/embed-sdk/headless` and Zod schemas.

```typescript
import { clientTool } from "@masheev/embed-sdk/headless";
import { z } from "zod";
```

## E-Commerce: search_products

```typescript
const searchProducts = clientTool({
  name: "search_products",
  description: "Search the product catalog by keyword, category, or price range.",
  parameters: z.object({
    query: z.string().describe("Search keywords"),
    category: z.string().optional().describe("Product category slug"),
    maxPrice: z.number().optional().describe("Maximum price in USD"),
  }),
  execute: async (args, { onProgress }) => {
    onProgress("Searching products...");
    const params = new URLSearchParams({ q: args.query });
    if (args.category) params.set("category", args.category);
    if (args.maxPrice) params.set("max_price", String(args.maxPrice));
    const { products, total } = await fetch(`/api/products/search?${params}`).then((r) => r.json());
    return {
      success: true,
      data: { products, total },
      display: "card",
      components: {
        card: { title: `Found ${total} products`, fields: products.slice(0, 3).map((p: any) => ({ label: p.name, value: `$${p.price.toFixed(2)}` })) },
        quickReplies: [{ label: "Show more", value: "Show me more results" }],
      },
    };
  },
});
```

## E-Commerce: add_to_cart

```typescript
const addToCart = clientTool({
  name: "add_to_cart",
  description: "Add a product to the shopping cart.",
  parameters: z.object({
    productId: z.string().describe("Product ID"),
    quantity: z.number().optional().describe("Quantity, default 1"),
    variantId: z.string().optional().describe("Variant ID for size/color"),
  }),
  needsApproval: true,
  execute: async (args) => {
    const res = await fetch("/api/cart/items", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ productId: args.productId, quantity: args.quantity ?? 1, variantId: args.variantId }) });
    if (!res.ok) return { success: false, error: (await res.json()).message ?? "Failed to add to cart" };
    const cart = await res.json();
    return { success: true, data: { cartTotal: cart.total, itemCount: cart.items.length }, display: "card", components: { card: { title: "Added to cart", fields: [{ label: "Items", value: String(cart.items.length) }, { label: "Total", value: `$${cart.total.toFixed(2)}` }], actions: [{ label: "View cart", url: "/cart" }] } } };
  },
});
```

## E-Commerce: check_order_status

```typescript
const checkOrderStatus = clientTool({
  name: "check_order_status",
  description: "Check order status by order number. Returns shipping status and tracking info.",
  parameters: z.object({ orderNumber: z.string().describe("Order number, e.g. ORD-12345") }),
  execute: async (args) => {
    const res = await fetch(`/api/orders/${args.orderNumber}`);
    if (!res.ok) return { success: false, error: "Order not found." };
    const order = await res.json();
    return { success: true, data: { status: order.status, trackingNumber: order.trackingNumber, estimatedDelivery: order.estimatedDelivery }, display: "card", components: { card: { title: `Order ${args.orderNumber}`, subtitle: `Status: ${order.status}`, fields: [{ label: "Tracking", value: order.trackingNumber ?? "Not yet shipped" }, { label: "Est. delivery", value: order.estimatedDelivery ?? "Pending" }] } } };
  },
});
```

## Booking: check_availability

```typescript
const checkAvailability = clientTool({
  name: "check_availability",
  description: "Check available appointment slots for a given date and service type.",
  parameters: z.object({
    date: z.string().describe("Date in YYYY-MM-DD format"),
    service: z.string().describe("Service type, e.g. 'haircut', 'consultation'"),
    providerId: z.string().optional().describe("Specific provider/staff ID"),
  }),
  execute: async (args, { onProgress }) => {
    onProgress("Checking availability...");
    const params = new URLSearchParams({ date: args.date, service: args.service });
    if (args.providerId) params.set("provider", args.providerId);
    const { slots } = await fetch(`/api/availability?${params}`).then((r) => r.json());
    return {
      success: true,
      data: { date: args.date, availableSlots: slots },
      display: "text",
      components: { quickReplies: slots.slice(0, 4).map((s: any) => ({ label: s.time, value: `Book me for ${s.time} on ${args.date}` })) },
    };
  },
});
```

## Booking: create_booking

```typescript
const createBooking = clientTool({
  name: "create_booking",
  description: "Create a confirmed booking for a specific date, time, and service.",
  parameters: z.object({
    date: z.string().describe("Date in YYYY-MM-DD format"),
    time: z.string().describe("Time in HH:MM format (24h)"),
    service: z.string().describe("Service type"),
    customerName: z.string().describe("Customer full name"),
    notes: z.string().optional().describe("Special requests"),
  }),
  needsApproval: true,
  execute: async (args, { onProgress }) => {
    onProgress("Creating your booking...");
    const res = await fetch("/api/bookings", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(args) });
    if (!res.ok) return { success: false, error: (await res.json()).message ?? "Could not create booking" };
    const booking = await res.json();
    return { success: true, data: { bookingId: booking.id, confirmationCode: booking.code }, display: "card", components: { card: { title: "Booking Confirmed", fields: [{ label: "Date", value: `${args.date} at ${args.time}` }, { label: "Service", value: args.service }, { label: "Confirmation", value: booking.code }] } } };
  },
});
```

## Booking: cancel_booking

```typescript
const cancelBooking = clientTool({
  name: "cancel_booking",
  description: "Cancel an existing booking by confirmation code.",
  parameters: z.object({
    confirmationCode: z.string().describe("Booking confirmation code"),
    reason: z.string().optional().describe("Cancellation reason"),
  }),
  needsApproval: true,
  execute: async (args) => {
    const res = await fetch(`/api/bookings/${args.confirmationCode}`, { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ reason: args.reason }) });
    if (!res.ok) return { success: false, error: "Booking not found or already cancelled." };
    return { success: true, data: { cancelled: true, code: args.confirmationCode }, display: "text" };
  },
});
```

## CRM: lookup_customer

```typescript
const lookupCustomer = clientTool({
  name: "lookup_customer",
  description: "Look up customer details by email or phone number.",
  parameters: z.object({
    email: z.string().optional().describe("Customer email address"),
    phone: z.string().optional().describe("Customer phone number"),
  }),
  execute: async (args) => {
    const params = new URLSearchParams();
    if (args.email) params.set("email", args.email);
    if (args.phone) params.set("phone", args.phone);
    const res = await fetch(`/api/customers/lookup?${params}`);
    if (!res.ok) return { success: false, error: "Customer not found." };
    const c = await res.json();
    return { success: true, data: { id: c.id, name: c.name, plan: c.plan, totalOrders: c.totalOrders }, display: "silent" };
  },
});
```

## CRM: update_customer_info

```typescript
const updateCustomerInfo = clientTool({
  name: "update_customer_info",
  description: "Update a customer's profile information.",
  parameters: z.object({
    customerId: z.string().describe("Customer ID"),
    name: z.string().optional().describe("Updated full name"),
    email: z.string().optional().describe("Updated email"),
    phone: z.string().optional().describe("Updated phone number"),
  }),
  needsApproval: true,
  execute: async (args) => {
    const { customerId, ...updates } = args;
    const res = await fetch(`/api/customers/${customerId}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(updates) });
    if (!res.ok) return { success: false, error: "Failed to update customer info." };
    return { success: true, data: { updated: true, customerId }, display: "text" };
  },
});
```

## Registration

Pass all tools to `init()` with `instructions` telling the AI when to use each one:

```typescript
import { init } from "@masheev/embed-sdk/js";
init({ inboxId: "YOUR_INBOX_ID", tools: [searchProducts, addToCart, checkOrderStatus, checkAvailability, createBooking, cancelBooking, lookupCustomer, updateCustomerInfo], instructions: "Use search_products for product queries. Use add_to_cart when they want to buy. Use check_availability before suggesting times. Use create_booking only after confirmation." });
```
