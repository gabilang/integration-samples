# 📦 Real-Time Order Processing Pipeline (Kafka)

## Description

An event-driven order processing pipeline built with [Apache Kafka](https://kafka.apache.org/) and
Ballerina. An HTTP service accepts incoming orders and **publishes them as events** to a Kafka
`orders` topic, then returns immediately. A separate Kafka **listener service consumes** those events
asynchronously, validates each order, reserves inventory, and routes **high-value orders** to a
`fulfillment` topic for downstream handling.

This demonstrates the core value of Kafka in integrations: **decoupling order intake from order
fulfillment** so the two scale and fail independently.

```
HTTP POST /orders ──▶ produce event to "orders" topic
                              │  (Kafka decouples intake from processing)
                              ▼
                     kafka:Service listener (onConsumerRecord)
                              │  validate → reserve inventory
                              ▼
                  high-value order? ──▶ produce to "fulfillment" topic + notify
                  out-of-stock / invalid? ──▶ log warning (rejected)
```

## 🚀 Features

- 🔀 Event-driven, asynchronous order processing with Apache Kafka
- 🧾 HTTP order-intake endpoint (producer) with fire-and-forget semantics
- 📥 Kafka listener service (consumer) with validation and inventory reservation
- 💰 Automatic routing of high-value orders to a fulfillment topic
- 🐳 Local Kafka broker included via Docker Compose

## Prerequisites

- [Ballerina](https://ballerina.io/downloads/) `2201.12.9` or later
- [Docker](https://www.docker.com/) (to run the bundled Kafka broker)

## Configuration

Create a `Config.toml` file in the package root with the following values:

```toml
kafkaBootstrapServers = "localhost:9092"
ordersTopic = "orders"
fulfillmentTopic = "fulfillment"
consumerGroupId = "order-processing-group"
highValueThreshold = 500.0
```

The Kafka connection security is also configurable. By default it is `PLAINTEXT` (for the local
broker), so the keys below can be omitted for local testing — see
[Using a hosted Kafka (Aiven)](#using-a-hosted-kafka-aiven) for TLS/SASL.

| Config key | Purpose |
|------------|---------|
| `kafkaSecurityProtocol` | `PLAINTEXT` (default), `SSL`, `SASL_SSL`, or `SASL_PLAINTEXT` |
| `kafkaCaCertPath` | Path to the broker CA certificate PEM (enables TLS trust) |
| `kafkaClientCertPath` / `kafkaClientKeyPath` | Client cert + key PEM paths (mutual TLS) |
| `kafkaSaslMechanism` | `PLAIN` (default), `SCRAM-SHA-256`, or `SCRAM-SHA-512` |
| `kafkaSaslUsername` / `kafkaSaslPassword` | SASL credentials |

## Usage Instructions

1. Start a local Kafka broker:

   ```bash
   docker compose -f environment/docker-compose.yml up -d
   ```

2. Run the integration (starts both the HTTP producer service and the Kafka consumer listener):

   ```bash
   bal run
   ```

3. Send an order to the `POST /orders` endpoint:

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

4. Observe the consumer logs. Because the total (1200.00) exceeds `highValueThreshold`, the order is
   routed to the `fulfillment` topic:

   ```
   INFO  Order accepted and published: ORD-1001
   INFO  Order processed: ORD-1001, total: 1200.0
   INFO  High-value order routed to fulfillment: ORD-1001
   ```

   A low-value order (total below the threshold) is processed but **not** routed to fulfillment, and
   an order for an out-of-stock SKU is rejected with a warning.

5. Tear down the broker when finished:

   ```bash
   docker compose -f environment/docker-compose.yml down
   ```

## How It Works

- **Producer (`main.bal`)** — the `/orders` HTTP service publishes each accepted order to the
  `orders` topic via a `kafka:Producer` and immediately returns `ACCEPTED`.
- **Consumer (`listener.bal`)** — a `kafka:Service` on a `kafka:Listener` receives batches of order
  events in `onConsumerRecord`. For each order it validates the payload, reserves inventory, and —
  for high-value orders — publishes a fulfillment event to the `fulfillment` topic.
- **Business logic (`functions.bal`)** — order total calculation, validation, and an in-memory
  inventory store (kept in-memory so the sample is self-contained; a real integration would use a
  database or inventory service).
- **Types (`types.bal`)** — `Order`, `OrderItem`, the typed Kafka consumer record, and the HTTP
  response record.
- **Connections (`connections.bal`)** — the shared `kafka:Producer` used by both services.
- **Security (`security.bal`)** — config-driven TLS/SASL settings shared by the producer and the
  listener, so the same code runs against a local plaintext broker or a hosted secure cluster.

## Using a hosted Kafka (Aiven)

[Aiven for Apache Kafka](https://aiven.io/kafka) requires a TLS connection. By default an Aiven
service uses **client-certificate (mutual TLS)** authentication; SASL/SCRAM can be enabled instead
from the service's *Advanced configuration*. You do not need the local Docker broker for this —
point the sample at your Aiven service via `Config.toml`.

### 1. Get the connection details from the Aiven console

From your Kafka service's **Overview → Connection information**, note the **Service URI**
(`host:port`, e.g. `kafka-xxxx-yourproject.aivencloud.com:12345`) and download the three files:

- **CA Certificate** → `ca.pem`
- **Access Certificate** → `service.cert`
- **Access Key** → `service.key`

Place them somewhere accessible (e.g. a `certs/` folder in the package root — it is git-ignored).

> The Access Key may be in PKCS#1 format. Ballerina expects PKCS#8. If the file begins with
> `-----BEGIN RSA PRIVATE KEY-----`, convert it once:
> ```bash
> openssl pkcs8 -topk8 -nocrypt -in service.key -out service.key.pk8
> ```
> and use `service.key.pk8` below.

### 2. Create the topics

Aiven does not auto-create topics by default. In the service's **Topics** tab, create `orders` and
`fulfillment` (or enable `kafka.auto_create_topics_enable` under *Advanced configuration*).

### 3. Configure `Config.toml` for mutual TLS (Aiven default)

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

If you enabled **SASL/SCRAM** on the service instead, use:

```toml
kafkaSecurityProtocol = "SASL_SSL"
kafkaCaCertPath = "certs/ca.pem"
kafkaSaslMechanism = "SCRAM-SHA-256"
kafkaSaslUsername = "avnadmin"
kafkaSaslPassword = "<your-service-password>"
```

### 4. Run and test

```bash
bal run
```

Send the same `POST /orders` requests shown above — the order events now flow through your Aiven
cluster. You can watch them land on the Aiven side from the **Topics → orders / fulfillment**
message browser in the console.

### Deploy on WSO2 Cloud

1. Deploy this integration on **WSO2 Cloud**.
2. Configure `kafkaBootstrapServers`, `ordersTopic`, `fulfillmentTopic`, `consumerGroupId`, and
   `highValueThreshold` to point at your managed Kafka cluster before running.
