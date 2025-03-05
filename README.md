# Product-sales-SQL-analysis
## Project Over View
The project aims to analyse the sales of sporting products, customer behaviour and product perfomance ranging from clothes, bikes, accessories etc. The analysis has been done using MySQL and the visualization using Power BI.
### Scope
The data runs from (?).  The data set involves 3 tables: the fact_sales, dim-products and customers. 
### Data exploration and analysis
- I categorized the analysis in four groups
  - Change over time analysis
  - Cumulative analysis (running total)
  - Year over year product perfomance
  - Part of whole analysis. This involves analysing product performance relative to all products
  - Customer behaviour analysis
#### 1.Change over time analysis
I used date functions to extract the months and years to analyse change over time of the revenue, total customers and quantity ordered.
```
select year(order_date) as years, monthname(order_date) as months, sum(sales_amount) as Revenue, count(distinct(customer_key)) Total_customers, sum(quantity) as quantity
from fact_sales where sales_amount is not null group by years, months order by years;

```
#### 2.Running total
In addition to date functions, I used a subquery and a window function to help me get the running total of the quantities, revenue and total customers which was partitioned by years.
```
select *,  sum(Revenue)over( partition by year(order_date) order by order_date) as Running_Total_Revenue
from
(select order_date,  sum(sales_amount) as Revenue, count(distinct(customer_key)) Total_customers,
 sum(quantity) as quantity from fact_sales
where sales_amount is not null group by order_date order by order_date) as temp;

```
#### 3.Year over year product performance analysis
#### 4.Part of whole analysis
- I analysed product performance relative to all products by revenue and quantity ordered for the different product categories and product lines.
- I used left join inorder to connect the fact table to the products table and subqueries to get a combined table. The concat function helped in adding the percent symbol (%)
- ##### by quantity ordered and category

```
select*, total_orders, concat(round((total_orders/sum(total_orders)over ())*100,2),"%") as percentage from
(select p.category,sum(f.quantity) as total_orders
from fact_sales f
left join dim_products p on f.product_key=p.product_key 
where f.quantity is not null or f.product_key is not null or f.product_key!=''
group by p.category) as temp;

```
- ##### by quantity ordered and category and product line
  
```
select category, product_line, counts from (
select  category, product_line, count(category) over (partition by category,product_line) as counts from fact_sales f
left join dim_products p on f.product_key=p.product_key ) as temp
group by category, product_line;

```
- ##### revenue contribution by product category
  
```
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.category,sum(sales_amount) as revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key
 where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.category) as temp;

```

- #####  revenue contribution by product line

```
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.product_line,sum(sales_amount) as Revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key 
where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.product_line) as temp;

```

- #####  data segmentation

```
with temp as (select f.product_key, p.product_name, p.cost,case
when cost <100 then "Below 100"
when cost between 100 and 500 then "100-500"
when cost between 500 and 1000 then "500-1000"
else "Above 1000" end as cost_range
from fact_sales f left join dim_products p on f.product_key=p.product_key where f.product_key is not null or f.product_key!='')
select cost_range, count(product_name) as counts from temp 
group by cost_range order by counts desc;

```

- #####  customer behaviour 

```
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

```


