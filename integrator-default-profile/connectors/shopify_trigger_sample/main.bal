import ballerina/log;
import ballerinax/trigger.shopify;

listener shopify:Listener shopifyListener = new ({apiSecretKey: string `${shopifyApiSecretKey}`}, listenOn = shopifyListenerPort);

service shopify:OrdersService on shopifyListener {
    remote function onOrdersCreate(shopify:OrderEvent event) returns error? {
        do {
            log:printInfo("Received Shopify orders/create webhook event");
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    remote function onOrdersCancelled(shopify:OrderEvent event) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    remote function onOrdersFulfilled(shopify:OrderEvent event) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    remote function onOrdersPaid(shopify:OrderEvent event) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    remote function onOrdersPartiallyFulfilled(shopify:OrderEvent event) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

    remote function onOrdersUpdated(shopify:OrderEvent event) returns error? {
        do {
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }
}
