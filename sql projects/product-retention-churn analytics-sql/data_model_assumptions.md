

---

# 🗂️ Data Model & Assumptions

## Project: Product, Retention & Churn Analytics using SQL

This project is **query-driven** and does not include raw dataset files (CSV, Excel, etc.).

The SQL queries are written assuming a **realistic SaaS / product analytics data model**, similar to what is commonly used in production event-tracking systems.

---

## 🔹 Core Tables Assumed

### 1️⃣ `users`

Stores user-level information.

| Column Name | Description                      |
| ----------- | -------------------------------- |
| user_id     | Unique identifier for each user  |
| signup_date | Date the user created an account |

**Assumptions:**

* Each `user_id` represents one unique user
* `signup_date` is the starting point of the user lifecycle

---

### 2️⃣ `events`

Stores product usage and activity events.

| Column Name | Description                                 |
| ----------- | ------------------------------------------- |
| user_id     | Identifier of the user performing the event |
| event_name  | Name of the action or feature used          |
| event_time  | Timestamp when the event occurred           |

**Assumptions:**

* Each row represents one user interaction
* Events are generated for all meaningful product actions
* `event_time` is stored in UTC
* Event names are consistent across the system

---

### 3️⃣ `subscriptions`

Stores subscription lifecycle data (if applicable).

| Column Name | Description                            |
| ----------- | -------------------------------------- |
| user_id     | Identifier of the subscribed user      |
| start_date  | Subscription start date                |
| end_date    | Subscription end date (NULL if active) |

**Assumptions:**

* One user can have at most one active subscription at a time
* `end_date` < current date indicates subscription churn
* Subscription churn complements activity-based churn detection

---

## 🔹 Key Business Assumptions

* **Active user** = user with at least one event in the time period
* **Churned user** = user inactive for 30+ days OR subscription ended
* Retention is measured at **monthly granularity**
* Feature usage is inferred from `event_name`
* Funnel progression is defined as:

  * signup → first_action → subscribe → payment_success

---

## 🔹 Time Windows Used

| Metric     | Time Window        |
| ---------- | ------------------ |
| DAU        | Daily              |
| WAU        | Weekly             |
| MAU        | Monthly            |
| Churn      | 30 days inactivity |
| Cohort Age | Monthly            |

---

## 🔹 Why No Dataset Is Included

This project focuses on demonstrating:

* SQL-based product analytics
* Retention and churn logic
* Funnel and cohort analysis
* Feature adoption insights
* Business-driven reasoning

In real SaaS environments, analysts typically query **existing event databases** rather than working with raw CSV files.

---

## 🔹 Intended Use Cases

This data model supports:

* Product engagement tracking
* Retention and churn monitoring
* Funnel optimization
* Feature prioritization
* Early churn detection

The model is intentionally generic so it can be adapted to:

* SaaS platforms
* Consumer apps
* Subscription-based products
* Freemium products

---

