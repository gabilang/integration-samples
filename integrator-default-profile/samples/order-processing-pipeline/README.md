# 📦 Real-Time Order Processing Pipeline (Kafka)

An event-driven order processing pipeline built with [Apache Kafka](https://kafka.apache.org/) and
Ballerina, split into **two independently deployable components** that communicate only through Kafka
topics:

```
                 HTTP POST /orders
                         │
                         ▼
        ┌─────────────────────────────────┐
        │  order-intake-service (producer) │   ← deploy as a "service" component
        │  HTTP /orders → produce to        │
        │  "orders" topic, return ACCEPTED  │
        └─────────────────────────────────┘
                         │  Kafka "orders" topic
                         ▼
        ┌─────────────────────────────────┐
        │  order-processor (consumer)      │   ← deploy as an "event-integration" component
        │  consume "orders" → validate →    │
        │  reserve inventory → route high-  │
        │  value orders to "fulfillment"    │
        └─────────────────────────────────┘
                         │  Kafka "fulfillment" topic
                         ▼
                  downstream handling
```

This demonstrates the core value of Kafka in integrations: **decoupling order intake from order
fulfillment** so the two scale, deploy, and fail independently.

## Components

| Directory | Role | WSO2 Cloud component type | Inbound endpoint? |
|-----------|------|---------------------------|-------------------|
| [`order-intake-service/`](./order-intake-service) | HTTP intake → produces order events | **service** | Yes — `POST /orders` |
| [`order-processor/`](./order-processor) | Consumes order events → validate, reserve inventory, route high-value orders | **event-integration** | No — broker-driven consumer |

> **Why two components?** The `event-integration` component type is for pure broker-driven
> consumers and rejects any component that exposes an inbound endpoint. The HTTP intake therefore
> lives in its own `service` component. The `order-processor` still *produces* to the `fulfillment`
> topic — that is broker egress, not an inbound endpoint, so it remains a valid `event-integration`.

Each directory is a self-contained Ballerina package with its own `Ballerina.toml`, `Config.toml`,
and Kafka security configuration (`security.bal`).

## Prerequisites

- [Ballerina](https://ballerina.io/downloads/) `2201.12.9` or later
- [Docker](https://www.docker.com/) (to run the bundled Kafka broker)

## Run locally

1. Start a local Kafka broker (shared by both components; `orders` and `fulfillment` topics are
   auto-created on first use):

   ```bash
   docker compose -f environment/docker-compose.yml up -d
   ```

2. In one terminal, start the consumer:

   ```bash
   cd order-processor
   bal run
   ```

3. In a second terminal, start the intake service:

   ```bash
   cd order-intake-service
   bal run
   ```

4. Send an order to the intake service (`POST /orders`, default port `9090`):

   ```bash
   curl -X POST http://localhost:9090/orders \
     -H "Content-Type: application/json" \
     -d '{
       "orderId": "ORD-1001",
       "customerName": "Alice",
       "orderItems": [
         { "sku": "SKU-LAPTOP", "quantity": 1, "unitPrice": 1200.00 }
       ]
     }'
   ```

   Response:

   ```json
   { "orderId": "ORD-1001", "orderStatus": "ACCEPTED" }
   ```

5. Observe the **order-processor** logs. Because the total (1200.00) exceeds `highValueThreshold`,
   the order is routed to the `fulfillment` topic:

   ```
   INFO  Order processed: ORD-1001, total: 1200.0
   INFO  High-value order routed to fulfillment: ORD-1001
   ```

   A low-value order (below the threshold) is processed but **not** routed to fulfillment, and an
   order for an out-of-stock SKU is rejected with a warning.

6. Tear down the broker when finished:

   ```bash
   docker compose -f environment/docker-compose.yml down
   ```

## Configuration

Each component reads its own `Config.toml`. By default both point at the local docker-compose broker
on `PLAINTEXT`.

**`order-intake-service/Config.toml`**

```toml
kafkaBootstrapServers = "localhost:9092"
ordersTopic = "orders"
```

**`order-processor/Config.toml`**

```toml
kafkaBootstrapServers = "localhost:9092"
ordersTopic = "orders"
fulfillmentTopic = "fulfillment"
consumerGroupId = "order-processing-group"
highValueThreshold = 500.0
```

Both components share the same Kafka security keys (defined in each `security.bal`). The defaults
keep the local broker on `PLAINTEXT`; set these in `Config.toml` to reach a TLS-secured cluster:

| Config key | Purpose |
|------------|---------|
| `kafkaSecurityProtocol` | `PLAINTEXT` (default), `SSL`, `SASL_SSL`, or `SASL_PLAINTEXT` |
| `kafkaCaCertPath` | Path to the broker CA certificate PEM (enables TLS trust) |
| `kafkaClientCertPath` / `kafkaClientKeyPath` | Client cert + key PEM paths (mutual TLS) |
| `kafkaSaslMechanism` | `PLAIN` (default), `SCRAM-SHA-256`, or `SCRAM-SHA-512` |
| `kafkaSaslUsername` / `kafkaSaslPassword` | SASL credentials |

## Using a hosted Kafka (Aiven)

[Aiven for Apache Kafka](https://aiven.io/kafka) requires a TLS connection. By default an Aiven
service uses **client-certificate (mutual TLS)** authentication; SASL/SCRAM can be enabled instead
from the service's *Advanced configuration*. You do not need the local Docker broker for this —
point each component at your Aiven service via its `Config.toml`.

### 1. Get the connection details from the Aiven console

From your Kafka service's **Overview → Connection information**, note the **Service URI**
(`host:port`, e.g. `kafka-xxxx-yourproject.aivencloud.com:12345`) and download the three files:

- **CA Certificate** → `ca.pem`
- **Access Certificate** → `service.cert`
- **Access Key** → `service.key`

Place them in a `certs/` folder inside **each** component that needs them (it is git-ignored).

> The Access Key may be in PKCS#1 format. Ballerina expects PKCS#8. If the file begins with
> `-----BEGIN RSA PRIVATE KEY-----`, convert it once:
> ```bash
> openssl pkcs8 -topk8 -nocrypt -in service.key -out service.key.pk8
> ```
> and use `service.key.pk8` below.

### 2. Create the topics

Aiven does not auto-create topics by default. In the service's **Topics** tab, create `orders` and
`fulfillment` (or enable `kafka.auto_create_topics_enable` under *Advanced configuration*).

### 3. Configure each `Config.toml` for mutual TLS (Aiven default)

`order-intake-service/Config.toml`:

```toml
kafkaBootstrapServers = "kafka-xxxx-yourproject.aivencloud.com:12345"
ordersTopic = "orders"

kafkaSecurityProtocol = "SSL"
kafkaCaCertPath = "certs/ca.pem"
kafkaClientCertPath = "certs/service.cert"
kafkaClientKeyPath = "certs/service.key"
```

`order-processor/Config.toml`:

```toml
kafkaBootstrapServers = "kafka-xxxx-yourproject.aivencloud.com:12345"
ordersTopic = "orders"
fulfillmentTopic = "fulfillment"
consumerGroupId = "order-processing-group"
highValueThreshold = 500.0

kafkaSecurityProtocol = "SSL"
kafkaCaCertPath = "certs/ca.pem"
kafkaClientCertPath = "certs/service.cert"
kafkaClientKeyPath = "certs/service.key"
```

If you enabled **SASL/SCRAM** on the service instead, use these keys (in place of the cert paths):

```toml
kafkaSecurityProtocol = "SASL_SSL"
kafkaCaCertPath = "certs/ca.pem"
kafkaSaslMechanism = "SCRAM-SHA-256"
kafkaSaslUsername = "avnadmin"
kafkaSaslPassword = "<your-service-password>"
```

## Deploy on WSO2 Cloud

Deploy the two packages as **separate components** in the same project:

1. **`order-intake-service`** → create a **service** component. It exposes the `POST /orders`
   endpoint.
2. **`order-processor`** → create an **event-integration** component. It has no inbound endpoint;
   if it must reach an external broker, enable egress on the component's environment config so a
   `NetworkPolicy` is emitted for broker connectivity.

For each component, configure its Kafka connection (`kafkaBootstrapServers`, topics, and security)
to point at your managed Kafka cluster before running.
