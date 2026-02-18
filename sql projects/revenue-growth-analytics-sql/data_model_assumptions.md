
---

# 🗂️ Data Model & Assumptions

## Project: Revenue & Growth Analytics using SQL

This project is **query-driven** and does not include raw dataset files (CSV, Excel, etc.).

The SQL queries are written assuming a **realistic production-style data model** commonly found in **E-commerce / SaaS / Transactional systems**.

This mirrors real-world analytics work where analysts often write SQL directly on existing databases.

---

## 🔹 Assumed Tables Overview

### 1️⃣ `customers`

Stores customer-level information.

| Column Name    | Description                             |
| -------------- | --------------------------------------- |
| customer_id    | Unique identifier for each customer     |
| customer_state | Customer location / region              |
| signup_date    | Date customer registered (if available) |

**Assumptions:**

* Each `customer_id` represents one unique customer
* Customer location does not change frequently

---

### 2️⃣ `orders`

Stores order-level information.

| Column Name              | Description                      |
| ------------------------ | -------------------------------- |
| order_id                 | Unique identifier for each order |
| customer_id              | Links order to a customer        |
| order_purchase_timestamp | Timestamp when order was placed  |

**Assumptions:**

* One order can have one or more payments
* Each order belongs to a single customer
* Timestamps are stored in UTC

---

### 3️⃣ `payments`

Stores payment transaction details.

| Column Name    | Description                                         |
| -------------- | --------------------------------------------------- |
| order_id       | Links payment to an order                           |
| payment_value  | Monetary value of the payment                       |
| payment_status | Status of payment (`success`, `failed`, `refunded`) |

**Assumptions:**

* Only `success` payments are counted as revenue
* `failed` and `refunded` payments represent revenue leakage
* Each row represents one payment attempt

---

### 4️⃣ `order_items`

Stores product-level details for each order.

| Column Name | Description                |
| ----------- | -------------------------- |
| order_id    | Links item to an order     |
| product_id  | Identifier for the product |

**Assumptions:**

* One order can contain multiple products
* Revenue attribution to products is based on associated payments

---

## 🔹 Key Business Assumptions

* Revenue = **successful payments only**
* Refunds and failed payments are excluded from revenue metrics
* Revenue is analyzed at:

  * Monthly level
  * Customer lifetime level
* Each customer can place multiple orders
* Revenue trends are based on order purchase date

---

## 🔹 Why No Dataset Is Included

This project focuses on demonstrating:

* SQL problem-solving skills
* Business-driven analytics thinking
* Use of realistic data models
* Query readability and explanation

Including raw datasets is **not required** to showcase SQL capability for **junior remote contract roles**.

---

## 🔹 Intended Usage

This data model supports:

* Revenue trend analysis
* Growth and performance metrics
* Customer value segmentation
* Churn risk detection
* Revenue leakage analysis

The structure is intentionally generic so it can be adapted to:

* SaaS platforms
* E-commerce businesses
* Subscription-based products

---

