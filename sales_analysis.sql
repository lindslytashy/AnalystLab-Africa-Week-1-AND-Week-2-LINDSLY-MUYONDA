-- 
-- ANALYSTLAB AFRICA - WEEK 3: SQL & DATA QUERYING
-- Dataset: Sample Sales Data
-- Intern: LINDSLY MUYONDA


-- SCHEMA EXPLORATION


SELECT COUNT(*) AS total_rows FROM sales;

SELECT STATUS, COUNT(*) AS count
FROM sales
GROUP BY STATUS
ORDER BY count DESC;


--  CORE SQL QUERIES


-- SELECT, WHERE, ORDER BY
SELECT ORDERNUMBER, CUSTOMERNAME, COUNTRY, PRODUCTLINE, SALES
FROM sales
WHERE STATUS = 'Shipped'
ORDER BY SALES DESC;

SELECT ORDERNUMBER, CUSTOMERNAME, PRODUCTLINE, SALES, DEALSIZE
FROM sales
WHERE DEALSIZE = 'Large'
ORDER BY SALES DESC;

--  GROUP BY, HAVING & Aggregate Functions
SELECT PRODUCTLINE,
       COUNT(DISTINCT ORDERNUMBER)    AS total_orders,
       SUM(QUANTITYORDERED)           AS units_sold,
       ROUND(SUM(SALES), 2)           AS total_revenue,
       ROUND(AVG(SALES), 2)           AS avg_order_value
FROM sales
GROUP BY PRODUCTLINE
ORDER BY total_revenue DESC;

SELECT COUNTRY,
       COUNT(DISTINCT CUSTOMERNAME)   AS unique_customers,
       ROUND(SUM(SALES), 2)           AS total_revenue
FROM sales
GROUP BY COUNTRY
ORDER BY total_revenue DESC;

SELECT YEAR_ID,
       COUNT(DISTINCT ORDERNUMBER)    AS orders,
       ROUND(SUM(SALES), 2)           AS annual_revenue
FROM sales
WHERE STATUS = 'Shipped'
GROUP BY YEAR_ID
ORDER BY YEAR_ID;

SELECT PRODUCTLINE,
       ROUND(SUM(SALES), 2) AS total_revenue
FROM sales
GROUP BY PRODUCTLINE
HAVING SUM(SALES) > 500000
ORDER BY total_revenue DESC;


--  ADVANCED SQL CONCEPTS


-- Quarterly Revenue Pivot (CASE WHEN)
SELECT YEAR_ID,
       ROUND(SUM(CASE WHEN QTR_ID=1 THEN SALES ELSE 0 END), 2) AS Q1,
       ROUND(SUM(CASE WHEN QTR_ID=2 THEN SALES ELSE 0 END), 2) AS Q2,
       ROUND(SUM(CASE WHEN QTR_ID=3 THEN SALES ELSE 0 END), 2) AS Q3,
       ROUND(SUM(CASE WHEN QTR_ID=4 THEN SALES ELSE 0 END), 2) AS Q4,
       ROUND(SUM(SALES), 2)                                     AS annual_total
FROM sales
WHERE STATUS = 'Shipped'
GROUP BY YEAR_ID
ORDER BY YEAR_ID;

-- Subqueries
SELECT CUSTOMERNAME, COUNTRY,
       ROUND(SUM(SALES), 2) AS total_spent
FROM sales
GROUP BY CUSTOMERNAME, COUNTRY
HAVING SUM(SALES) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(SALES) AS customer_total
        FROM sales
        GROUP BY CUSTOMERNAME
    )
)
ORDER BY total_spent DESC;

SELECT DISTINCT PRODUCTCODE, PRODUCTLINE, MSRP
FROM sales s1
WHERE MSRP > (
    SELECT AVG(MSRP)
    FROM sales s2
    WHERE s2.PRODUCTLINE = s1.PRODUCTLINE
)
ORDER BY PRODUCTLINE, MSRP DESC;

--  Window Functions (RANK, ROW_NUMBER, PARTITION BY)
SELECT CUSTOMERNAME, COUNTRY,
       ROUND(SUM(SALES), 2) AS total_revenue,
       RANK() OVER (
           PARTITION BY COUNTRY
           ORDER BY SUM(SALES) DESC
       ) AS country_rank
FROM sales
GROUP BY CUSTOMERNAME, COUNTRY
ORDER BY COUNTRY, country_rank;

SELECT YEAR_ID, MONTH_ID,
       ROUND(SUM(SALES), 2) AS monthly_revenue,
       ROUND(SUM(SUM(SALES)) OVER (
           PARTITION BY YEAR_ID
           ORDER BY MONTH_ID
       ), 2) AS cumulative_ytd
FROM sales
GROUP BY YEAR_ID, MONTH_ID
ORDER BY YEAR_ID, MONTH_ID;

-- Top 3 products per product line
SELECT PRODUCTLINE, PRODUCTCODE, total_revenue, rn AS rank_in_line
FROM (
    SELECT PRODUCTLINE, PRODUCTCODE,
           ROUND(SUM(SALES), 2) AS total_revenue,
           ROW_NUMBER() OVER (
               PARTITION BY PRODUCTLINE
               ORDER BY SUM(SALES) DESC
           ) AS rn
    FROM sales
    GROUP BY PRODUCTLINE, PRODUCTCODE
)
WHERE rn <= 3
ORDER BY PRODUCTLINE, rn;


-- BUSINESS PROBLEM SOLVING


-- Top 10 customers by lifetime value
SELECT CUSTOMERNAME, COUNTRY,
       COUNT(DISTINCT ORDERNUMBER)    AS total_orders,
       ROUND(SUM(SALES), 2)           AS lifetime_value
FROM sales
GROUP BY CUSTOMERNAME, COUNTRY
ORDER BY lifetime_value DESC
LIMIT 10;

-- Deal size distribution by country
SELECT COUNTRY,
       SUM(CASE WHEN DEALSIZE='Small'  THEN 1 ELSE 0 END) AS small_deals,
       SUM(CASE WHEN DEALSIZE='Medium' THEN 1 ELSE 0 END) AS medium_deals,
       SUM(CASE WHEN DEALSIZE='Large'  THEN 1 ELSE 0 END) AS large_deals
FROM sales
GROUP BY COUNTRY
ORDER BY large_deals DESC;

-- Customer segmentation: loyal vs occasional vs one-time
SELECT
    CASE WHEN order_count = 1            THEN 'One-Time'
         WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional'
         ELSE 'Loyal (6+)' END            AS segment,
    COUNT(*)                              AS customer_count,
    ROUND(AVG(total_revenue), 2)          AS avg_lifetime_value
FROM (
    SELECT CUSTOMERNAME,
           COUNT(DISTINCT ORDERNUMBER) AS order_count,
           SUM(SALES)                  AS total_revenue
    FROM sales
    GROUP BY CUSTOMERNAME
)
GROUP BY 1
ORDER BY avg_lifetime_value DESC;


--  QUERY OPTIMISATION
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sales_status      ON sales(STATUS);
CREATE INDEX IF NOT EXISTS idx_sales_year        ON sales(YEAR_ID);
CREATE INDEX IF NOT EXISTS idx_sales_productline ON sales(PRODUCTLINE);
CREATE INDEX IF NOT EXISTS idx_sales_customer    ON sales(CUSTOMERNAME);
CREATE INDEX IF NOT EXISTS idx_sales_country     ON sales(COUNTRY);

EXPLAIN QUERY PLAN
SELECT CUSTOMERNAME,
       ROUND(SUM(SALES), 2) AS total_revenue
FROM sales
WHERE STATUS = 'Shipped'
  AND YEAR_ID = 2004
GROUP BY CUSTOMERNAME
ORDER BY total_revenue DESC
LIMIT 10;


