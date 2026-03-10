
# 📊 Revenue & Growth Analytics using SQL

## 🔹 Project Overview

This project focuses on analyzing **revenue performance, customer behavior, growth trends, and revenue leakage** using SQL.

The goal is to demonstrate how SQL can be used not just to write queries, but to **answer real business questions** that founders, growth teams, and finance teams care about.

This project is **query-driven** and simulates real-world analytics work where analysts often work directly on production databases rather than raw CSV files.

---

## 🔹 Business Problems Solved

This project answers questions such as:

* How is revenue trending month over month and year over year?
* Where is revenue coming from (countries, products, customers)?
* Who are the highest-value customers?
* Which customers show declining spending behavior?
* How much revenue is at risk due to customer churn?
* How much revenue is lost due to failed or refunded payments?

---

## 🔹 Files & Structure

```
📦 Revenue-Growth-Analytics-SQL/
│
├── revenue_queries.sql
├── growth_analysis.sql
├── customer_analysis.sql
├── leakage_analysis.sql
│
├── final_views.sql
├── insights_for_founders.md
├── data_model_assumptions.md
└── README.md
```

---

## 🔹 SQL Files Explained

### 1️⃣ `revenue_queries.sql`

Focuses on **revenue trends and growth metrics**:

* Monthly revenue
* Month-over-month (MoM) growth
* Year-over-year (YoY) growth

Used to understand overall business performance and momentum.

---

### 2️⃣ `growth_analysis.sql`

Focuses on **where revenue comes from**:

* Revenue by country
* Revenue by product
* Revenue by customer
* Revenue concentration (Pareto analysis)

Helps identify growth opportunities and dependency risks.

---

### 3️⃣ `customer_analysis.sql`

Focuses on **customer value and behavior**:

* ARPU (Average Revenue Per User)
* Customer lifetime revenue
* Revenue-based customer segmentation
* Detection of declining customer spend
* Estimation of revenue at risk

Used for retention and customer success strategies.

---

### 4️⃣ `leakage_analysis.sql`

Focuses on **revenue loss and inefficiencies**:

* Gross vs net revenue
* Refund analysis
* Failed payment analysis
* Revenue leakage percentage

Helps identify payment, refund, and process issues impacting revenue.

---

## 🔹 SQL Concepts Used

* Common Table Expressions (CTEs)
* Window Functions (`LAG`, `NTILE`)
* Aggregations (`SUM`, `COUNT`)
* Time-based analysis (`DATE_TRUNC`)
* Revenue growth calculations
* Business-driven SQL structuring

---

## 🔹 Assumptions

* Only **successful payments** are considered revenue
* Failed and refunded payments represent revenue leakage
* Each `customer_id` uniquely identifies a customer
* Revenue is analyzed at monthly and lifetime levels

Detailed assumptions and table structure are documented in
👉 **`data_model_assumptions.md`**

---

## 🔹 Target Role

This project is designed for:

• Data Analyst
• Product / Business Analyst
• SQL-focused analytics roles
• Startup and SaaS analytics teams

The emphasis is on **clear thinking, business understanding, and readable SQL** rather than just complex queries.

---

## 🔹 Author

**Sathvik**
Aspiring Data Analyst specializing in SQL analytics, business intelligence, and data-driven decision making.

---


