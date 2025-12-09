--Business Questions:
--1. Which country has the most invoices?
SELECT 
	billing_country AS country ,
	COUNT(*) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;

--2. Who is the best-selling artist?
SELECT
	a.artist_id,
	a.name AS artist_name,
SUM(il.quantity*il.unit_price) AS total_sales
FROM invoice_line il
JOIN track t ON il.track_id=t.track_id
LEFT JOIN album ab ON ab.album_id=t.album_id
LEFT JOIN artist a ON a.artist_id=ab.artist_id
GROUP BY 1,2
ORDER BY 3 DESC;

--3. Identify the top 5 customers by total spending.
SELECT
	c.customer_id,
	(c.last_name||' '||c.first_name) AS full_name,
	SUM(i.total) AS total_spending 
FROM customer c
JOIN invoice i
ON c.customer_id=i.customer_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

--4. Which genre generates the most revenue?
SELECT
	g.genre_id,
	g.name AS genre,
	SUM(il.quantity*il.unit_price) AS Revenue
FROM invoice_line il
JOIN track t ON il.track_id=t.track_id
LEFT JOIN genre g ON t.genre_id=g.genre_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

--5. categorizes customers into "High Spender" and "Low Spender" .
WITH customer_spending AS (
    SELECT
        c.customer_id,
        (c.last_name || ' ' || c.first_name) AS full_name,
        SUM(i.total) AS total_spending
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 1,2
),
cutoff AS (
  SELECT 
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_spending) AS p80
  FROM customer_spending
)
SELECT
    cs.customer_id,
    cs.full_name,
    cs.total_spending,
    CASE 
        WHEN  cs.total_spending >= (SELECT p80 FROM cutoff) THEN 'High Spender'
      	ELSE 'Low Spender'
END AS spender_type
FROM customer_spending cs
ORDER BY cs.total_spending DESC;

--6. What are the top 10 tracks by revenue?
SELECT
  a.artist_id,
  a.name AS artist_name,
  t.track_id,
  t.name AS track_name,
  SUM(il.quantity * il.unit_price) AS revenue,
  SUM(il.quantity) AS units_sold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album ab ON t.album_id = ab.album_id
JOIN artist a ON ab.artist_id = a.artist_id
GROUP BY a.artist_id, a.name, t.track_id, t.name
ORDER BY revenue DESC, units_sold DESC
LIMIT 10;

--7. Which countries generate the highest revenue (not just invoice count)?
SELECT
	billing_country AS country,
	SUM(total) AS highest_revenue
FROM invoice 
GROUP BY 1
ORDER BY 2 DESC;

--8. What is the monthly sales trend?
SELECT TO_CHAR(DATE_TRUNC('month',invoice_date),'yyyy-mm') AS month,
SUM(total) AS total_sales
FROM invoice
GROUP BY 1
ORDER BY 1;

--9. Which employee (support rep) brings the highest revenue?
SELECT
	c.support_rep_id AS employee,
	(e.last_name||' '||e.first_name) AS employee_name,
	SUM(i.total) AS revenue
FROM employee e
JOIN customer c ON e.employee_id=c.support_rep_id
JOIN invoice i  ON c.customer_id=i.customer_id
GROUP BY 1,2
ORDER BY 3 DESC;

--10. What is the average order value (AOV)?
SELECT 
	COUNT(*) AS order_count,
	SUM(total) AS total_revenue,
	ROUND((SUM(total)/COUNT(*)),2) AS AOV
FROM invoice;

--11. What percentage of total revenue comes from the top 20% of customers? (Pareto Analysis)
WITH customer_spending AS(
SELECT 
	c.customer_id,
    (c.last_name || ' ' || c.first_name) AS full_name,
	SUM(i.total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id=i.customer_id
GROUP BY 1,2
),
cutoff AS (
  SELECT PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_spending) AS p80
  FROM customer_spending
  ),
totals AS (
SELECT
	SUM(total_spending) AS company_revenue
FROM customer_spending
)
SELECT
Round(
	(SELECT SUM(cs.total_spending) FROM customer_spending cs 
	WHERE cs.total_spending>=(SELECT p80 FROM cutoff))
	/totals.company_revenue*100,2) AS pct_revenue_from_top_20_by_value
FROM totals;


