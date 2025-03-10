-- CHANGE OVER TIME ANALYSIS --
select year(order_date) as years, monthname(order_date) as months, sum(sales_amount) as revenue,
count(distinct(customer_key)) total_customers, sum(quantity) as quantity
from fact_sales
where sales_amount is not null and order_date!='' group by years, months order by years;

-- cumulative analysis(Running total) --
select *, year(order_date), sum(Revenue)over( partition by year(order_date) order by order_date) as Running_Total_Revenue
from
(select order_date, sum(sales_amount) as revenue, count(distinct(customer_key)) total_customers,
 sum(quantity) as quantity from fact_sales
where sales_amount is not null and order_date!='' group by order_date order by order_date) as temp;

-- product Performance Analysis YoY--
with temp as(
select year(order_date) as years, p.product_name,sum(sales_amount) as revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key where f.product_key is not null or f.product_key!=''
group by p.product_name, years )

select *, round(avg(Revenue) over(partition by product_name order by years asc),0) as average,
concat(round(((Revenue - lag(revenue,1,0) over (partition by product_name order by years asc))/revenue)*100,0),"%") as changes,
case 
when Revenue-round(avg(Revenue) over(partition by product_name),0)>0 then "above avg"
when Revenue-round(avg(Revenue) over(partition by product_name),0)<=0 then "below avg"  end as perfomance
from temp;

-- PART OF WHOLE ANALYSIS --------------------------------------------------------------------------------------------------
-- quantity ordered by category --
select*, concat(round((total_orders/sum(total_orders)over ())*100,2),"%") as percentage from
(select p.category,sum(f.quantity) as total_orders
from fact_sales f
left join dim_products p on f.product_key=p.product_key 
where f.quantity is not null or f.product_key is not null or f.product_key!=''
group by p.category) as temp;

-- quantity ordered by category and product line --
select category, product_line, counts from (
select  category, product_line, count(category) over (partition by category,product_line) as counts from fact_sales f
left join dim_products p on f.product_key=p.product_key ) as temp
group by category, product_line;

-- revenue contribution by product category --
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.category,sum(sales_amount) as revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key
 where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.category) as temp;

-- revenue contribution by product line --
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.product_line,sum(sales_amount) as Revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key 
where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.product_line) as temp;
--------------------------------------------------------------------------------------------------------------------------------
-- data segmentation --
with temp as (select f.product_key, p.product_name, p.cost,case
when cost <100 then "Below 100"
when cost between 100 and 500 then "100-500"
when cost between 500 and 1000 then "500-1000"
else "Above 1000" end as cost_range
from fact_sales f left join dim_products p on f.product_key=p.product_key where f.product_key is not null or f.product_key!='')
select cost_range, count(product_name) as counts from temp 
group by cost_range order by counts desc;

-- customer behaviour --
with temp as(select 
f.order_number, f.product_key,f.order_date,f.sales_amount,f.quantity,
c.customer_key,c.customer_number,c.customer_name,c.age,c.age_group
from fact_sales f 
left join customers c on f.customer_key=c.customer_key 
where f.customer_key is not null or f.customer_key!='')

select customer_number,customer_name,age, age_group,
sum(quantity) as total_quantity,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
round(sum(sales_amount)/count(distinct order_number),0) as avg_order_amount,case
when (timestampdiff(month,min(order_date), max(order_date)))>=12 and sum(sales_amount)>=5000 then "VIP"
when (timestampdiff(month,min(order_date), max(order_date)))<12 and sum(sales_amount)>=5000 then "regular"
else "new" end as customer_segment
from temp where customer_number is not null group by customer_number, customer_name, age,age_group;











