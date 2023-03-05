SELECT * FROM `dim_customer`;
SELECT * FROM `dim_product`;
SELECT * FROM `fact_gross_price`;
SELECT * FROM `fact_manufacturing_cost`;
SELECT * FROM `fact_pre_invoice_deductions`;
SELECT * FROM `fact_sales_monthly`;
------------------------------------------ 
SELECT COUNT(*) FROM `dim_customer`;
SELECT COUNT(*) FROM `dim_product`;
SELECT COUNT(*) FROM `fact_gross_price`;
SELECT COUNT(*) FROM `fact_manufacturing_cost`;
SELECT COUNT(*) FROM `fact_pre_invoice_deductions`;
SELECT COUNT(*) FROM `fact_sales_monthly`;
desc `dim_product`;
desc `dim_customer`;
desc `fact_gross_price`;
DESC `fact_manufacturing_cost`;
SELECT DISTINCT platform, channel FROM `dim_customer`;
SELECT DISTINCT division FROM `dim_product`;
SELECT DISTINCT segment FROM `dim_product`;
SELECT DISTINCT category FROM `dim_product`;
SELECT DISTINCT product FROM `dim_product`;
SELECT DISTINCT variant FROM `dim_product`;
SELECT * FROM `dim_product` WHERE segment = 'notebook';

-------------------------------------------------------------------------- 
----------------- CHALLENGE 1 ------------
CREATE VIEW markets_of_Atliq_Exclusive_in_APAC AS
SELECT DISTINCT market FROM dim_customer WHERE customer = "Atliq Exclusive" AND  region = "APAC";

----------------- CHALLENGE 2 -------------
CREATE VIEW unique_products_2020_and_2021 AS
WITH unique_products_2020_cte (unique_products_2020) AS
(
SELECT COUNT( DISTINCT product) AS unique_products_2020  FROM dim_product 
JOIN fact_manufacturing_cost ON fact_manufacturing_cost.product_code = dim_product.product_code 
WHERE cost_year = 2020
), 
unique_products_2021_cte (unique_products_2021) AS 
(
SELECT  COUNT( DISTINCT product) AS unique_products_2021  FROM dim_product 
JOIN fact_manufacturing_cost ON fact_manufacturing_cost.product_code = dim_product.product_code 
WHERE cost_year = 2021
) 
SELECT unique_products_2020_cte.unique_products_2020, unique_products_2021_cte.unique_products_2021,
round(unique_products_2021 / unique_products_2020 *100 -100) AS percentage_chg
FROM unique_products_2020_cte, unique_products_2021_cte;

----------------- CHALLENGE 3 -------------
CREATE VIEW product_counts_for_each_segment AS
SELECT segment,COUNT(DISTINCT product) AS product_count FROM dim_product GROUP BY segment ORDER BY product_count DESC;

----------------- CHALLENGE 4 -------------

WITH product_count_2020_cte (segment, product_count_2020) AS 
(
  SELECT segment, COUNT(DISTINCT product) AS product_count_2020 
  FROM dim_product
  JOIN fact_manufacturing_cost ON dim_product.product_code = fact_manufacturing_cost.product_code 
  WHERE cost_year = 2020 
  GROUP BY segment
), 
product_count_2021_cte (segment, product_count_2021) AS 
(
  SELECT segment, COUNT(DISTINCT product) AS product_count_2021 
  FROM dim_product
  JOIN fact_manufacturing_cost ON dim_product.product_code = fact_manufacturing_cost.product_code 
  WHERE cost_year = 2021 
  GROUP BY segment
)
SELECT product_count_2020_cte.segment, product_count_2020, product_count_2021
FROM product_count_2020_cte 
JOIN product_count_2021_cte ON product_count_2020_cte.segment = product_count_2021_cte.segment;

----------------------------- another solution for CHALLENGE 4 -------------------------------

CREATE VIEW product_counts_by_segment AS
SELECT segment,
       COUNT(DISTINCT CASE WHEN cost_year = 2020 THEN product END) AS product_count_2020,
       COUNT(DISTINCT CASE WHEN cost_year = 2021 THEN product END) AS product_count_2021
FROM dim_product
JOIN fact_manufacturing_cost ON dim_product.product_code = fact_manufacturing_cost.product_code
GROUP BY segment;

SELECT * FROM product_counts_by_segment;

----------------- CHALLENGE 5 -------------
CREATE VIEW highest_and_lowest_manufacturing_costs AS
SELECT dim_product.product_code, dim_product.product, ROUND(fact_manufacturing_cost.manufacturing_cost,2) AS  manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product ON dim_product.product_code = fact_manufacturing_cost.product_code
WHERE fact_manufacturing_cost.manufacturing_cost = (SELECT MAX(manufacturing_cost) from fact_manufacturing_cost)
UNION
SELECT dim_product.product_code, dim_product.product, ROUND(fact_manufacturing_cost.manufacturing_cost,2) AS manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product ON dim_product.product_code = fact_manufacturing_cost.product_code
WHERE fact_manufacturing_cost.manufacturing_cost = (SELECT MIN(manufacturing_cost) from fact_manufacturing_cost);

----------------- CHALLENGE 6 -------------
CREATE VIEW  top_5_customers_average_discount_percentage AS
SELECT dim_customer.customer, round(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct),3) * 100  AS average_discount_percentage
FROM dim_customer
JOIN fact_pre_invoice_deductions ON dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
WHERE fact_pre_invoice_deductions.fiscal_year = 2021 AND dim_customer.market = 'india'
GROUP BY dim_customer.customer ORDER BY average_discount_percentage DESC LIMIT 5;

----------------- CHALLENGE 7 -------------
CREATE VIEW the_Gross_sales_by_Atliq_Exclusive AS
SELECT MONTH(fact_sales_monthly.date) AS Month, YEAR(fact_sales_monthly.date) AS Year,
ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) AS `Gross sales Amount` FROM fact_gross_price
JOIN fact_sales_monthly ON fact_sales_monthly.product_code = fact_gross_price.product_code
JOIN dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
WHERE dim_customer.customer = 'Atliq Exclusive'
GROUP BY Year, Month
ORDER BY Year;

----------------- CHALLENGE 8 -------------
CREATE VIEW maximum_total_sold_quantity_by_quarter AS
SELECT CASE WHEN date between '2019-09-01' and '2019-11-01'  THEN 'quarter 1' 
WHEN date BETWEEN '2019-12-01' AND  '2020-02-01' THEN 'quarter 2' 
ELSE 'quarter 3' END AS Quarter,
SUM(sold_quantity) AS total_sold_quantity FROM fact_sales_monthly 
WHERE fiscal_year = 2020
GROUP BY Quarter 
ORDER BY total_sold_quantity DESC LIMIT 1;

----------------- CHALLENGE 9 -------------

CREATE VIEW highest_channel_gross_sales AS 
WITH percentage_of_contribution_cte (channel,gross_sales_mln) AS
(
SELECT dim_customer.channel, ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) AS gross_sales_mln
FROM dim_customer
JOIN fact_sales_monthly ON fact_sales_monthly.customer_code = dim_customer.customer_code
JOIN fact_gross_price ON fact_gross_price.product_code = fact_sales_monthly.product_code
WHERE fact_sales_monthly.fiscal_year = 2021
GROUP BY dim_customer.channel 
) SELECT percentage_of_contribution_cte.channel, percentage_of_contribution_cte.gross_sales_mln ,
(ROUND(SUM(percentage_of_contribution_cte.gross_sales_mln) OVER (PARTITION BY percentage_of_contribution_cte.channel)
 /
SUM(percentage_of_contribution_cte.gross_sales_mln) OVER(),3))
 * 100
AS percentage
FROM percentage_of_contribution_cte ORDER BY percentage DESC LIMIT 1;

----------------- CHALLENGE 10 -------------
CREATE VIEW Top_3_products_each_div AS
with top_3_products (division, product_code, product, total_sold_quantity,rank_order ) AS
(
SELECT dim_product.division, dim_product.product_code, dim_product.product, SUM(fact_sales_monthly.sold_quantity) AS total_sold_quantity,
RANK() OVER(PARTITION BY dim_product.division ORDER BY SUM(fact_sales_monthly.sold_quantity) DESC ) AS rank_order
FROM dim_product
JOIN fact_sales_monthly ON fact_sales_monthly.product_code = dim_product.product_code
WHERE fact_sales_monthly.fiscal_year = 2021
GROUP BY  dim_product.division, dim_product.product_code, dim_product.product
) 
SELECT top_3_products.division, top_3_products.product_code, top_3_products.product, top_3_products.total_sold_quantity,top_3_products.rank_order
FROM top_3_products
WHERE top_3_products.rank_order BETWEEN 1 AND 3;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- CREATE VIEW total_gross_sales AS
SELECT fact_sales_monthly.fiscal_year, ifnull(CASE WHEN fact_sales_monthly.fiscal_year = 2020 THEN
ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) END, 0)  AS `Gross sales Amount 2020` ,
ifnull(CASE WHEN fact_sales_monthly.fiscal_year = 2021 THEN
ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) END, 0)  AS `Gross sales Amount 2021`
FROM fact_gross_price 
JOIN fact_sales_monthly ON fact_sales_monthly.product_code = fact_gross_price.product_code
GROUP BY fact_sales_monthly.fiscal_year;

-- CREATE VIEW customer_transactions_by_fiscal_year AS
SELECT ifnull(CASE WHEN fact_sales_monthly.fiscal_year = 2020  THEN COUNT(dim_customer.customer) END, 0) AS count_customer_2020, 
ifnull(CASE WHEN fact_sales_monthly.fiscal_year = 2021  THEN COUNT(dim_customer.customer) END, 0) AS count_customer_2021
FROM dim_customer
JOIN fact_sales_monthly ON fact_sales_monthly.customer_code = dim_customer.customer_code
GROUP BY fact_sales_monthly.fiscal_year;

-- CREATE VIEW total_gross_sales_by_date AS
SELECT ROUND(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) AS gross_sales, DATE(date)
FROM fact_sales_monthly
JOIN fact_gross_price ON fact_gross_price.product_code = fact_sales_monthly.product_code
GROUP BY date ORDER BY date;

-- CREATE VIEW total_gross_profit_by_segment AS
SELECT segment, ROUND(SUM((fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) - fact_manufacturing_cost.manufacturing_cost)) AS gross_profit
FROM fact_sales_monthly
JOIN fact_gross_price ON fact_gross_price.product_code = fact_sales_monthly.product_code
JOIN fact_manufacturing_cost ON fact_manufacturing_cost.product_code = fact_gross_price.product_code
JOIN dim_product ON fact_manufacturing_cost.product_code = dim_product.product_code
GROUP BY dim_product.segment;

-- CREATE VIEW gross_profit AS
SELECT dim_product.product_code, division, segment, product, variant, cost_year, manufacturing_cost, fact_sales_monthly.fiscal_year, gross_price, date, fact_sales_monthly.customer_code, sold_quantity,
ROUND((fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) - fact_manufacturing_cost.manufacturing_cost) AS gross_profit  FROM dim_product
JOIN fact_manufacturing_cost ON fact_manufacturing_cost.product_code = dim_product.product_code
JOIN fact_gross_price ON fact_gross_price.product_code = fact_manufacturing_cost.product_code
JOIN fact_sales_monthly ON fact_sales_monthly.product_code = fact_gross_price.product_code






