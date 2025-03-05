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
