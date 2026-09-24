# Pizza Order Tracker

A pizza ordering system built from three microservices and a web frontend.

## What's Inside

- **Order Service** (Port 3000): Receives pizza orders and coordinates with other services
- **Kitchen Service** (Port 3001): Checks availability and cooks pizzas
- **Delivery Service** (Port 3002): Assigns drivers for delivery
- **Frontend** (Port 8080): Simple web UI for ordering pizzas

## Architecture

```
┌─────────────┐
│   Browser   │
│  (Port 8080)│
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Order     │────▶│   Kitchen   │     │  Delivery   │
│  Service    │     │   Service   │     │   Service   │
│ (Port 3000) │     │ (Port 3001) │     │ (Port 3002) │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Running the App

```bash
cp .env.template .env   # then fill in DASH0_AUTH_TOKEN
docker compose up
```

Then open http://localhost:8080 and order a pizza.

To stop it:

```bash
docker compose down
```

## Telemetry

The stack sends traces, metrics and logs to Dash0. Nothing in the services
themselves calls OpenTelemetry: the SDK is loaded before the application code by
`NODE_OPTIONS=--require @opentelemetry/auto-instrumentations-node/register`, set
per service in `docker-compose.yml`.

```
Browser (8080) ──┐
Order (3000) ────┤
Kitchen (3001) ──┼──▶ otel-collector (4317/4318) ──▶ Dash0 OTLP/gRPC ingress
Delivery (3002) ─┘
```

What that gives you, per pizza order:

- One trace covering the browser page view, `POST /order`, both kitchen calls and
  the delivery call — `traceparent` headers are propagated automatically by the
  HTTP client instrumentation.
- Express route and middleware spans, so the time spent inside each handler is
  visible.
- The existing pino logs, forwarded as OpenTelemetry log records with
  `trace_id` / `span_id` attached, so logs and traces line up in Dash0.
- Node.js runtime and HTTP metrics.

The Collector holds the credentials (`pizza-app/.env`, gitignored) and is the
only component that talks to Dash0. Browser telemetry goes to the Collector on
port 4318 as well, so no Dash0 token is embedded in the page.

Configuration lives in two places:

| File | Holds |
|---|---|
| `docker-compose.yml` | `OTEL_*` environment variables per service |
| `otelcol.yaml` | Collector receivers, processors and the Dash0 exporter |

`/health` spans are dropped in the Collector so the container healthchecks don't
dominate the traces.

### Checking it arrived

```bash
docker compose logs -f otel-collector
```

A working export is quiet. `Exporting failed` with `401` means
`DASH0_AUTH_TOKEN` is wrong; `context deadline exceeded` means
`DASH0_OTLP_GRPC_ENDPOINT` is wrong or unreachable.

## Watching What Happens

The terminal shows all four services interleaved:

```
order-service    | {"level":30,...,"orderId":"PIZZA-123...","msg":"Order received"}
kitchen-service  | {"level":30,...,"orderId":"PIZZA-123...","msg":"Starting to cook"}
delivery-service | {"level":30,...,"orderId":"PIZZA-123...","msg":"Assigning driver"}
```

One service on its own:

```bash
docker compose logs -f kitchen-service
```

## Failure Modes You Can Switch On

### Slow Kitchen (Oven is Broken)
```bash
SLOW_KITCHEN=true docker compose up
```

Every pizza takes about five seconds longer to cook.

### No Drivers Available
```bash
NO_DRIVERS=true docker compose up
```

Delivery has nobody to assign, so orders fail.

## Services Overview

### Order Service
- Receives orders from the frontend
- Calls Kitchen Service to check availability and cook
- Calls Delivery Service to assign a driver
- Returns order confirmation

### Kitchen Service
- Checks if kitchen is available
- Simulates cooking time
- Can be configured to be slow (SLOW_KITCHEN=true)

### Delivery Service
- Finds available drivers
- Assigns driver to order
- Can be configured to have no drivers (NO_DRIVERS=true)

### Frontend
- Simple HTML form
- Sends orders to Order Service
- Displays confirmation

## Tech Stack

- **Node.js** - Runtime
- **Express** - Web framework
- **Axios** - HTTP client
- **Docker** - Containerization

## Ports

- `3000` - Order Service
- `3001` - Kitchen Service
- `3002` - Delivery Service
- `8080` - Frontend
