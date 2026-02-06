### 📈 Month-over-Month (MoM) Sales Growth Analysis

**Business Context:**
The goal of this query was to identify revenue trends in 2020 by calculating the absolute monthly sales growth. This analysis enables stakeholders to quickly assess sales momentum without manual period-over-period comparisons.

**Key SQL Techniques Used:**
* **Window Functions (`LAG`):** Used to retrieve sales data from the previous month to calculate the exact difference (delta).
* **Common Table Expressions (CTEs):** Structured the query into logical steps (Data Cleaning -> Net Value Calculation -> Aggregation -> Final Analysis).
* **Data Cleaning:** Excluded returns (`NOT EXISTS`) and normalized discount values to ensure data integrity.
