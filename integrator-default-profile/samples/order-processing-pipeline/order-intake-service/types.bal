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

type OrderResponse record {|
    string orderId;
    string orderStatus;
|};
