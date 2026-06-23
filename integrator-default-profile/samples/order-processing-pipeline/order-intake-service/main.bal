import ballerina/http;
import ballerina/log;

listener http:Listener httpDefaultListener = http:getDefaultListener();

// Order-intake service (producer). Accepts an order over HTTP and publishes it as
// an event to the Kafka orders topic, then returns immediately. Order processing
// happens asynchronously in the separate order-processor component, decoupling
// intake from fulfillment.
service /orders on httpDefaultListener {

    resource function post .(Order placedOrder) returns OrderResponse|http:InternalServerError {
        do {
            check orderProducer->send({topic: ordersTopic, value: placedOrder});
            log:printInfo(string `Order accepted and published: ${placedOrder.orderId}`);
            return {orderId: placedOrder.orderId, orderStatus: "ACCEPTED"};
        } on fail error orderError {
            log:printError("Failed to publish order", 'error = orderError);
            return {body: {message: orderError.message()}};
        }
    }
}
