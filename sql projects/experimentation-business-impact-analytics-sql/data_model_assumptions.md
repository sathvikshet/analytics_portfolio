

---

# 🗂️ Data Model & Assumptions

## Project: Experimentation & Business Impact Analytics using SQL

This project is **query-driven** and assumes a **production-style experimentation data model** commonly used in SaaS and product-led companies.

Raw datasets are not included because experimentation analysis is typically performed **directly on live databases or warehouses**.

---

## 🔹 Core Tables Assumed

### 1️⃣ `experiments`

Stores experiment assignment data.

| Column Name     | Description                         |
| --------------- | ----------------------------------- |
| user_id         | Unique identifier for each user     |
| experiment_name | Name of the experiment              |
| variant         | Experiment variant (`A`, `B`, etc.) |

**Assumptions:**

* Each user is assigned to **only one variant** per experiment
* Variant assignment does not change during the experiment
* Variants `A` and `B` represent control and treatment

---

### 2️⃣ `events`

Stores user activity and engagement events.

| Column Name | Description                  |
| ----------- | ---------------------------- |
| user_id     | Identifier of the user       |
| event_name  | Action performed by the user |
| event_time  | Timestamp of the event       |

**Assumptions:**

* Each row represents a single user interaction
* Events reflect meaningful product usage
* `event_time` is stored in UTC
* Used to measure **retention and activity**

---

### 3️⃣ `orders`

Stores order-level transaction data.

| Column Name | Description                    |
| ----------- | ------------------------------ |
| order_id    | Unique identifier for an order |
| customer_id | User who placed the order      |

**Assumptions:**

* One user can place multiple orders
* Orders are linked to users via `customer_id`

---

### 4️⃣ `payments`

Stores payment transaction details.

| Column Name    | Description                                         |
| -------------- | --------------------------------------------------- |
| order_id       | Identifier of the related order                     |
| payment_value  | Monetary value of the payment                       |
| payment_status | Status of payment (`success`, `failed`, `refunded`) |

**Assumptions:**

* Only `payment_status = 'success'` counts as revenue
* Failed and refunded payments are excluded from conversion and revenue
* Each successful payment represents a completed conversion

---

## 🔹 Key Business Definitions

* **Experiment User**: User present in the `experiments` table
* **Conversion**: User with at least one successful payment
* **Revenue**: Sum of successful payment values
* **ARPU**: Total revenue / number of users in a variant
* **Retained User**: User active in the last **30 days**
* **Churned User**: User inactive for 30+ days

---

## 🔹 Time Windows Used

| Metric                | Definition                        |
| --------------------- | --------------------------------- |
| Conversion            | Lifetime (any successful payment) |
| Revenue               | Lifetime revenue                  |
| Retention             | Last 30 days activity             |
| Experiment Assignment | Static during experiment          |

---

## 🔹 Experiment Assumptions

* Variants are expected to be **evenly split** unless specified
* Sample Ratio Mismatch (SRM) indicates invalid experiment results
* Conversion, revenue, and retention are compared **between variants**
* Absolute and relative lifts are used to measure impact

---

## 🔹 Why No Dataset Is Included

This project is designed to demonstrate:

* Experiment validation logic
* Business impact measurement
* SQL-based experimentation analysis
* Real decision-making workflows

In real companies, analysts **rarely work with CSV files** for experiments — they query experiment, event, and revenue tables directly.

---

## 🔹 Intended Use Cases

This data model supports:

* A/B test validation
* Conversion rate comparison
* Revenue uplift measurement
* ARPU analysis
* Retention comparison
* Rollout vs rollback decisions

It is intentionally generic and adaptable to:

* SaaS products
* E-commerce platforms
* Subscription businesses
* Feature experiments

---


