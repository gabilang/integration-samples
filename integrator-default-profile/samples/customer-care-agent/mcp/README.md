# ShopEasy MCP server

A sample MCP server for the ShopEasy customer care scenario. It exposes three tools over the Model Context Protocol:

- `searchProducts`: search the product catalog by keyword
- `getOrderStatus`: look up an order by ID
- `submitReturnRequest`: submit a return request for a delivered order

The server reads product and order data from `data.json` at startup and listens on `http://localhost:8080/mcp`.

## Run with WSO2 Integrator

1. Open WSO2 Integrator and select **Open Project**.
2. Navigate to this directory and open it.
3. Click the **Run** button in the top-right corner.

The server starts on port `8080`.

## Run with `bal run`

Make sure you have [Ballerina installed](https://ballerina.io/downloads/), then run the following from this directory:

```bash
bal run
```

The server starts on port `8080`. You should see output similar to:

```
Running executable

ballerina: Initializing MCP service on port 8080
```
