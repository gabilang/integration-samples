// In-memory inventory keyed by SKU, kept here so the sample is self-contained
// (a real integration would read/write a database or inventory service).
isolated map<int> inventoryStock = {
    "SKU-LAPTOP": 5,
    "SKU-PHONE": 20,
    "SKU-MOUSE": 100,
    "SKU-KEYBOARD": 50
};

isolated function calculateOrderTotal(Order placedOrder) returns decimal {
    decimal orderTotal = 0;
    foreach OrderItem orderItem in placedOrder.orderItems {
        orderTotal += orderItem.unitPrice * orderItem.quantity;
    }
    return orderTotal;
}

isolated function validateOrder(Order placedOrder) returns error? {
    if placedOrder.orderItems.length() == 0 {
        return error("order must contain at least one item");
    }
    foreach OrderItem orderItem in placedOrder.orderItems {
        if orderItem.quantity <= 0 {
            return error(string `invalid quantity for SKU ${orderItem.sku}`);
        }
    }
}

// Verifies every line item has enough stock and, if so, decrements it atomically.
isolated function checkAndReserveInventory(Order placedOrder) returns boolean {
    Order & readonly orderCopy = placedOrder.cloneReadOnly();
    lock {
        foreach OrderItem orderItem in orderCopy.orderItems {
            int availableStock = inventoryStock[orderItem.sku] ?: 0;
            if availableStock < orderItem.quantity {
                return false;
            }
        }
        foreach OrderItem orderItem in orderCopy.orderItems {
            int availableStock = inventoryStock[orderItem.sku] ?: 0;
            inventoryStock[orderItem.sku] = availableStock - orderItem.quantity;
        }
        return true;
    }
}
