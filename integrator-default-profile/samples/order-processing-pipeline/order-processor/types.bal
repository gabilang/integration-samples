import ballerinax/kafka;

type OrderItem record {|
    string sku;
    int quantity;
    decimal unitPrice;
|};

type Order record {|
    string orderId;
    string customerName;
    OrderItem[] orderItems;
|};

type OrderConsumerRecord record {|
    *kafka:AnydataConsumerRecord;
    Order value;
|};
