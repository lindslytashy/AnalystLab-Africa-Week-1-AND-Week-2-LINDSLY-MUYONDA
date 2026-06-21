
-- ANALYSTLAB AFRICA - WEEK 3 Batch B: SQL & DATA QUERYING
-- Dataset: Chinook Database 
-- Intern: Lindsly Muyonda

-- SECTION 1: SCHEMA EXPLORATION

SELECT name FROM sqlite_master WHERE type='table';

-- Row counts
SELECT 'Customer' AS table_name, COUNT(*) AS row_count FROM Customer
UNION ALL
SELECT 'Invoice', COUNT(*) FROM Invoice
UNION ALL
SELECT 'Track', COUNT(*) FROM Track
UNION ALL
SELECT 'Album', COUNT(*) FROM Album
UNION ALL
SELECT 'Artist', COUNT(*) FROM Artist;


--CORE SQL QUERIES

-- SELECT, WHERE, ORDER BY
SELECT InvoiceId, CustomerId, InvoiceDate, BillingCountry, Total
FROM Invoice
WHERE Total > 10
ORDER BY Total DESC;

SELECT CustomerId, FirstName, LastName, City, Country, Email
FROM Customer
WHERE Country = 'Brazil'
ORDER BY LastName;

-- GROUP BY, HAVING & Aggregate Functions
SELECT BillingCountry,
       COUNT(InvoiceId)        AS total_invoices,
       SUM(Total)              AS total_revenue,
       ROUND(AVG(Total), 2)    AS avg_invoice_value
FROM Invoice
GROUP BY BillingCountry
HAVING SUM(Total) > 100
ORDER BY total_revenue DESC;

SELECT g.Name AS genre, COUNT(t.TrackId) AS track_count
FROM Track t
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name
ORDER BY track_count DESC;


-- ADVANCED SQL CONCEPTS


-- JOINs (INNER, LEFT)
SELECT ar.Name AS artist_name,
       COUNT(il.InvoiceLineId)              AS total_sales,
       SUM(il.UnitPrice * il.Quantity)      AS total_revenue
FROM InvoiceLine il
JOIN Track t   ON il.TrackId  = t.TrackId
JOIN Album a   ON t.AlbumId   = a.AlbumId
JOIN Artist ar ON a.ArtistId  = ar.ArtistId
GROUP BY ar.Name
ORDER BY total_revenue DESC
LIMIT 10;

SELECT c.CustomerId, c.FirstName, c.LastName, c.Country
FROM Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId
WHERE i.InvoiceId IS NULL;

-- Subqueries
SELECT c.FirstName || ' ' || c.LastName AS customer_name,
       SUM(i.Total) AS lifetime_value
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
HAVING SUM(i.Total) > (
    SELECT AVG(customer_sum)
    FROM (
        SELECT SUM(Total) AS customer_sum
        FROM Invoice
        GROUP BY CustomerId
    )
)
ORDER BY lifetime_value DESC;

-- Tracks  that never purchased
SELECT t.TrackId, t.Name AS track_name
FROM Track t
WHERE t.TrackId NOT IN (
    SELECT DISTINCT TrackId FROM InvoiceLine
);

-- Window Functions (RANK, ROW_NUMBER, PARTITION BY)
SELECT c.Country,
       c.FirstName || ' ' || c.LastName AS customer_name,
       SUM(i.Total) AS total_spent,
       RANK() OVER (
           PARTITION BY c.Country
           ORDER BY SUM(i.Total) DESC
       ) AS country_rank
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY c.Country, country_rank;

SELECT ar.Name AS artist_name,
       t.Name AS track_name,
       SUM(il.Quantity) AS units_sold,
       ROW_NUMBER() OVER (
           PARTITION BY ar.Name
           ORDER BY SUM(il.Quantity) DESC
       ) AS rank_within_artist
FROM InvoiceLine il
JOIN Track t   ON il.TrackId = t.TrackId
JOIN Album a   ON t.AlbumId  = a.AlbumId
JOIN Artist ar ON a.ArtistId = ar.ArtistId
GROUP BY ar.Name, t.Name
HAVING rank_within_artist <= 3
ORDER BY ar.Name, rank_within_artist;


-- BUSINESS PROBLEM SOLVING


-- Top 10 customers by lifetime value
SELECT c.CustomerId,
       c.FirstName || ' ' || c.LastName AS customer_name,
       c.Country,
       COUNT(i.InvoiceId)               AS total_orders,
       SUM(i.Total)                     AS lifetime_value
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY lifetime_value DESC
LIMIT 10;

-- Top 10 best-selling tracks
SELECT t.Name AS track_name,
       ar.Name AS artist_name,
       g.Name AS genre,
       SUM(il.Quantity) AS units_sold,
       SUM(il.UnitPrice * il.Quantity) AS revenue
FROM InvoiceLine il
JOIN Track t   ON il.TrackId  = t.TrackId
JOIN Album a   ON t.AlbumId   = a.AlbumId
JOIN Artist ar ON a.ArtistId  = ar.ArtistId
JOIN Genre g   ON t.GenreId   = g.GenreId
GROUP BY t.Name, ar.Name, g.Name
ORDER BY units_sold DESC
LIMIT 10;

-- Monthly revenue trend
SELECT strftime('%Y-%m', InvoiceDate) AS year_month,
       COUNT(InvoiceId) AS invoice_count,
       ROUND(SUM(Total), 2) AS monthly_revenue
FROM Invoice
GROUP BY year_month
ORDER BY year_month;

-- Revenue by year
SELECT strftime('%Y', InvoiceDate) AS year,
       ROUND(SUM(Total), 2) AS annual_revenue,
       COUNT(DISTINCT CustomerId) AS unique_customers
FROM Invoice
GROUP BY year
ORDER BY year;

-- Genre preference by country (top genre per country)
SELECT Country, genre, units_sold
FROM (
    SELECT c.Country,
           g.Name AS genre,
           SUM(il.Quantity) AS units_sold,
           RANK() OVER (
               PARTITION BY c.Country
               ORDER BY SUM(il.Quantity) DESC
           ) AS genre_rank
    FROM InvoiceLine il
    JOIN Track t    ON il.TrackId  = t.TrackId
    JOIN Genre g    ON t.GenreId   = g.GenreId
    JOIN Invoice i  ON il.InvoiceId = i.InvoiceId
    JOIN Customer c ON i.CustomerId = c.CustomerId
    GROUP BY c.Country, g.Name
)
WHERE genre_rank = 1
ORDER BY Country;


--  QUERY OPTIMISATION


CREATE INDEX IF NOT EXISTS idx_invoice_customer ON Invoice(CustomerId);
CREATE INDEX IF NOT EXISTS idx_invoiceline_track ON InvoiceLine(TrackId);
CREATE INDEX IF NOT EXISTS idx_track_genre ON Track(GenreId);
CREATE INDEX IF NOT EXISTS idx_album_artist ON Album(ArtistId);

-- Check query plan
EXPLAIN QUERY PLAN
SELECT ar.Name, SUM(il.UnitPrice * il.Quantity) AS revenue
FROM InvoiceLine il
JOIN Track t   ON il.TrackId = t.TrackId
JOIN Album a   ON t.AlbumId  = a.AlbumId
JOIN Artist ar ON a.ArtistId = ar.ArtistId
GROUP BY ar.Name
ORDER BY revenue DESC
LIMIT 10;
