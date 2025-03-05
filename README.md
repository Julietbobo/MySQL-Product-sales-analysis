# Product-sales-SQL-analysis
## Project Over View
The project aims to analyse the sales of sporting products, customer behaviour and product perfomance ranging from clothes, bikes, accessories etc. The analysis has been done using MySQL.
### Scope
The data set has 60,398 rows.  The data set involves 3 tables: the fact_sales, dim-products and customers. 

### Data exploration and analysis
- I categorized the analysis in four groups
  - Change over time analysis
  - Cumulative analysis (running total)
  - Part of whole analysis. This involves analysing product performance relative to all products
  - Data segmentation
  - Customer behaviour analysis
#### 1.Change over time analysis
I used date functions to extract the months and years to analyse change over time of the revenue, total customers and quantity ordered.
```
select year(order_date) as years, monthname(order_date) as months, sum(sales_amount) as revenue,
count(distinct(customer_key)) total_customers, sum(quantity) as quantity
from fact_sales
where sales_amount is not null and order_date!='' group by years, months order by years;

```
![change analysis](https://github.com/user-attachments/assets/8d01a708-cefc-4ee2-9fef-9ec97c2f08da)


#### 2.Cumulative analysis
In addition to date functions, I used a subquery and a window function to help me get the running total of the quantities, revenue and total customers which was partitioned by years.
```
select *, year(order_date), sum(Revenue)over( partition by year(order_date) order by order_date) as Running_Total_Revenue
from
(select order_date, sum(sales_amount) as revenue, count(distinct(customer_key)) total_customers,
 sum(quantity) as quantity from fact_sales
where sales_amount is not null and order_date!='' group by order_date order by order_date) as temp;

```
![running total](https://github.com/user-attachments/assets/3d70d5cb-f13e-4521-8de4-37e903fbf5e0)


#### 3.Part of whole analysis
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

![orders by categ](https://github.com/user-attachments/assets/0d6af161-867d-432b-85d9-2601ba2743bd)


- ##### by quantity ordered and category and product line
  
```
select category, product_line, counts from (
select  category, product_line, count(category) over (partition by category,product_line) as counts from fact_sales f
left join dim_products p on f.product_key=p.product_key ) as temp
group by category, product_line;

```
![category and productline](https://github.com/user-attachments/assets/197a3e00-8a00-42a0-a254-a7ed89672de2)


- ##### revenue contribution by product category
  
```
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.category,sum(sales_amount) as revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key
 where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.category) as temp;

```

![revenue by categ](https://github.com/user-attachments/assets/826a0b3a-6836-4cfa-b23f-ad821a656d18)


- #####  revenue contribution by product line

```
select*, concat(round((Revenue/sum(Revenue)over ())*100,2),"%") as percentage from
(select p.product_line,sum(sales_amount) as Revenue
from fact_sales f
left join dim_products p on f.product_key=p.product_key 
where f.sales_amount is not null or f.product_key is not null or f.product_key!=''
group by p.product_line) as temp;

```
![rev by product line](https://github.com/user-attachments/assets/c7eef0e0-136a-4b08-9b68-1ea4e8f6bc49)


#### 4.data segmentation
- I categorized the data based on the costs to see which ones were popular. I segmented them into below 100, 100-500, 500-1000 and above 1000. I used a case statement to help create the different categories and a CTE to create a table with the different categories incorporated from which I would be able to derive the total orders based on the cost.
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
![data segment](https://github.com/user-attachments/assets/5c9a1997-3259-4537-8d56-d78360767013)


#### 5.customer behaviour 
- I analyzed the customer behaviour in terms of quantity of products bought, how many orders they've made, total sales amount, the average value per order and what category
  they fall into based on their total sales amount. I categorized the customers into regular, VIP and New using a case statement.
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
![customer behavior](https://github.com/user-attachments/assets/f623f539-e21e-4cfd-ba52-7dcad703c910)


### Data limitation
- The dataset contains rows with order dates as empty spaces. I took care of this by using the where clause for filtering

  ` where sales_amount is not null and order_date!='' `


