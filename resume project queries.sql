
# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select customer, market, region from dim_customer
where customer = "Atliq Exclusive" and region ="APAC"


# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

with cte1 as (
select t2020.unique_product_2020,
	   t2021.unique_product_2021 from
(select count(distinct product_code) as unique_product_2020, fiscal_year from fact_sales_monthly
where fiscal_year=2020) as t2020
cross join
(select count(distinct product_code) as unique_product_2021, fiscal_year from fact_sales_monthly
where fiscal_year=2021) as t2021)
SELECT 
    unique_product_2020,
    unique_product_2021,
    ROUND(
        (unique_product_2021 - unique_product_2020) * 100.0 
        / unique_product_2020,
        2
    ) AS percentage_chng
FROM cte1;


# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count

select count(distinct product_code) as product_count, segment from dim_product
group by segment
order by product_count desc


# 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference

with cte1 as (
select segment, count(distinct case when fiscal_year = 2020 then product_code end) as product_count_2020,
			count(distinct case when fiscal_year = 2021 then product_code end) as product_count_2021
            from fact_sales_monthly
join dim_product using (product_code)
where fiscal_year in (2020,2021)
group by segment)
select *, product_count_2021- product_count_2020 as difference from cte1


# 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost

select product_code, product, manufacturing_cost from fact_manufacturing_cost
join dim_product
using (product_code)
where manufacturing_cost= (select min(manufacturing_cost) from fact_manufacturing_cost) or
manufacturing_cost= (select max(manufacturing_cost) from fact_manufacturing_cost)


# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage

select customer, customer_code, avg(pre_invoice_discount_pct) *100, 2 as avg_disc_pct from fact_pre_invoice_deductions
join dim_customer
using(customer_code)
where fiscal_year = 2021 and market="India"
group by customer, customer_code
order by avg_disc_pct desc
limit 5



# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount

select sum(g.gross_price * s.sold_quantity) as gross_sales_amount, month(s.date) as month, year(s.date) as year from fact_sales_monthly s
join dim_customer c
on s.customer_code=c.customer_code
join fact_gross_price g
on s.product_code=g.product_code and
s.fiscal_year=g.fiscal_year
where customer="Atliq Exclusive"
group by year(s.date),
month(s.date)
order by year,month


# 8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

select case
when month(date) in (9,10,11) then 'Q1'
when month(date) in (12,1,2) then 'Q2'
when month(date) in (3,4,5) then 'Q3'
when month(date) in (6,7,8) then 'Q4'
end as quarter,
sum(sold_quantity) as total_sold_qty from fact_sales_monthly
where year(date)=2020
group by quarter
order by total_sold_qty desc



# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage

with cte as (
select channel, round(sum(gross_price * sold_quantity)/1000000,2) as gross_sales_mln from fact_sales_monthly
join fact_gross_price using(product_code, fiscal_year)
join dim_customer using(customer_code)
where fiscal_year=2021
group by channel
)
select *,ROUND((gross_sales_mln * 100) / SUM(gross_sales_mln) OVER (), 2) AS percentage
from cte
order by gross_sales_mln desc


# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code product total_sold_quantity rank_order

WITH product_sales AS (
    SELECT 
        p.division,
        s.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly s
    JOIN dim_product p 
        ON s.product_code = p.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY 
        p.division, 
        s.product_code, 
        p.product
),
ranked_products AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY division 
            ORDER BY total_sold_quantity DESC
        ) AS rank_order
    FROM product_sales
)
SELECT 
    division,
    product_code,
    product,
    total_sold_quantity,
    rank_order
FROM ranked_products
WHERE rank_order <= 3
ORDER BY 
    division,
    rank_order;