# Mule Customer API Demo

A MuleSoft application demonstrating customer data management with REST API endpoints and database integration.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Configuration](#-configuration)
- [API Endpoints](#-api-endpoints)
- [Project Structure](#-project-structure)
- [Flow Diagrams](#-flow-diagrams)

## 🔍 Overview

This MuleSoft application provides a RESTful API for customer data management. It includes endpoints for retrieving and creating customer records, with both database integration and mock data capabilities for testing purposes.

**Key Technologies:**
- MuleSoft Runtime 4.8.0
- MySQL Database
- HTTP REST API
- DataWeave 2.0 for data transformation

## ✨ Features

- **GET /customers** - Retrieve customer data with optional mock mode
- **POST /customers** - Add new customer data with transformation
- **Database Integration** - MySQL connectivity for persistent storage
- **Mock Data Support** - Testing mode with static mock data
- **Error Handling** - Global error handler for consistent error responses
- **Data Transformation** - DataWeave transformations for data processing
- **Logging** - Comprehensive logging for monitoring and debugging

## 🏗️ Architecture

The application follows a standard MuleSoft architecture pattern:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │───▶│   Mule Flow     │───▶│   MySQL DB      │
│                 │    │                 │    │                 │
│ (REST Request)  │    │ (Processing &   │    │ (Data Storage)  │
│                 │◀───│  Transformation)│◀───│                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

Before running this application, ensure you have:

- **Anypoint Studio** 7.x or later
- **Java** 17
- **MySQL** database server
- **Maven** 3.6+ (included with Anypoint Studio)

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/lochana-chathura/Mule-API-Integration.git
cd muledemo
```

### 2. Import into Anypoint Studio
1. Open Anypoint Studio
2. File → Import → Anypoint Studio → Anypoint Studio Project from File System
3. Select the project root directory
4. Click Finish

### 3. Database Setup
Create a MySQL database and table:

```sql
CREATE DATABASE test_db;
USE test_db;

CREATE TABLE Customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- Insert sample data
INSERT INTO Customers (name, email) VALUES 
('John Doe', 'john.doe@example.com'),
('Jane Smith', 'jane.smith@example.com');
```

## ⚙️ Configuration

### Database Configuration
The application uses property files to manage database connections. I've already configured the necessary properties:

#### Configuration (`config.properties`)
```properties
# Database Configuration
# NOTE: The following credentials are placeholder values for demo purposes only.
db.user=root
db.password=abc123
```

> **Note:** `db.user` and `db.password` above are intentional dummy values used for demonstration. They do not represent real credentials and must be replaced with actual values for any non-demo deployment.

## 🔗 API Endpoints

### GET /customers
Retrieves customer data from the database or returns mock data.

**URL:** `http://localhost:9090/customers`

**Query Parameters:**
- `mock=true` (optional) - Returns mock data instead of database results

**Example Requests:**
```bash
# Get actual data from database
curl -X GET http://localhost:9090/customers

# Get mock data for testing
curl -X GET http://localhost:9090/customers?mock=true
```

**Response Example:**
```json
[
    {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com"
    },
    {
        "id": 2,
        "name": "Jane Smith",
        "email": "jane.smith@example.com"
    }
]
```

### POST /customers
Creates a new customer record with data transformation.

**URL:** `http://localhost:9090/customers`

**Request Body:**
```json
{
    "id": 3,
    "name": "alice johnson",
    "email": "alice.johnson@example.com"
}
```

**Example Request:**
```bash
curl -X POST http://localhost:9090/customers \
  -H "Content-Type: application/json" \
  -d '{
    "id": 3,
    "name": "alice johnson",
    "email": "alice.johnson@example.com"
  }'
```

**Response Example:**
```json
{
    "message": "Customer added successfully",
    "customerId": 3
}
```

**Note:** The application transforms the input data by converting name and email to uppercase before processing.

### Manual Testing
1. **Start the Application**
    - Right-click project in Anypoint Studio
    - Run As → Mule Application

2. **Test Endpoints**
    - Use the provided curl commands above
    - Or use Postman with the API documentation

### Mock Mode Testing
For testing without database connectivity:
```bash
curl -X GET "http://localhost:9090/customers?mock=true"
```

## 📁 Project Structure

```
muledemo/
├── pom.xml                          # Maven configuration
├── mule-artifact.json               # Mule application descriptor
├── src/
│   ├── main/
│   │   ├── mule/
│   │   │   └── muledemo.xml         # Main Mule flows
│   │   └── resources/
│   │       ├── config.properties    # Application properties
│   │       ├── config.yaml          # Application metadata
│   │       ├── log4j2.xml          # Logging configuration
│   │       └── application-types.xml # Data type definitions
│   └── test/
│       ├── munit/                   # MUnit test cases
│       └── resources/
│           └── log4j2-test.xml      # Test logging configuration
└── target/                          # Build artifacts
```

## 📊 Flow Diagrams

### Canvas Overview
<img width="721" height="886" alt="Screenshot 2025-09-11 at 11 43 00" src="https://github.com/user-attachments/assets/62ebeb5c-9aed-4973-aeec-35123671f920" />

### Transform Message in `mock=true` Path
<img width="447" height="218" alt="Screenshot 2025-09-11 at 11 54 19" src="https://github.com/user-attachments/assets/1ed19e16-ead4-47ec-a44a-9f9dbd16345d" />

### Transform Incoming Customer Data
<img width="398" height="118" alt="Screenshot 2025-09-11 at 11 54 49" src="https://github.com/user-attachments/assets/b403cf79-f6ae-437b-a3b1-ffb726d79237" />

### Response Message
<img width="485" height="108" alt="Screenshot 2025-09-11 at 11 55 08" src="https://github.com/user-attachments/assets/5fccdcb5-247f-4529-88d5-d50025cab4b5" />

### Transform Message in Error Handler
<img width="485" height="108" alt="Screenshot 2025-09-11 at 11 55 18" src="https://github.com/user-attachments/assets/6cdf4171-115c-4a7f-a723-cb4a436dccbf" />
