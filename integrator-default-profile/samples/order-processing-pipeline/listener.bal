import ballerina/log;
import ballerinax/kafka;

listener kafka:Listener orderListener = new (kafkaBootstrapServers, getOrderConsumerConfig());

isolated function getOrderConsumerConfig() returns kafka:ConsumerConfiguration {
    kafka:ConsumerConfiguration consumerConfig = {
        groupId: consumerGroupId,
        topics: [ordersTopic],
        securityProtocol: getKafkaSecurityProtocol()
    };
    kafka:SecureSocket? secureSocket = getKafkaSecureSocket();
    if secureSocket is kafka:SecureSocket {
        consumerConfig.secureSocket = secureSocket;
    }
    kafka:AuthenticationConfiguration? auth = getKafkaAuth();
    if auth is kafka:AuthenticationConfiguration {
        consumerConfig.auth = auth;
    }
    return consumerConfig;
}

// Order-processing service (consumer). Asynchronously consumes order events,
// validates each order, reserves inventory, and routes high-value orders to the
// fulfillment topic for downstream handling.
service kafka:Service on orderListener {

    remote function onConsumerRecord(OrderConsumerRecord[] orderRecords, kafka:Caller caller) returns error? {
        foreach OrderConsumerRecord orderRecord in orderRecords {
            Order placedOrder = orderRecord.value;
            do {
                check validateOrder(placedOrder);

                boolean inventoryReserved = checkAndReserveInventory(placedOrder);
                if !inventoryReserved {
                    log:printWarn(string `Order rejected (out of stock): ${placedOrder.orderId}`);
                    continue;
                }

                decimal orderTotal = calculateOrderTotal(placedOrder);
                log:printInfo(string `Order processed: ${placedOrder.orderId}, total: ${orderTotal}`);

                if orderTotal >= highValueThreshold {
                    check orderProducer->send({topic: fulfillmentTopic, value: placedOrder});
                    log:printInfo(string `High-value order routed to fulfillment: ${placedOrder.orderId}`);
                }
            } on fail error orderError {
                log:printWarn(string `Order rejected (${orderError.message()}): ${placedOrder.orderId}`);
            }
        }
    }
}
