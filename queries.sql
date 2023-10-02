--Данный запрос считает общее количество покупателей из таблицы customers--
select count(customer_id) as customers_count from customers c 

--Данный запрос выводит имя и фамилию продавца, суммарную выручку с проданных товаров и количество проведенных сделок 
--Сортировка по убыванию выручки, нули в конце

   select distinct
    t.name, t.operations, floor(t.income) as income
from (
    select
    (first_name||' '|| last_name) as name, 
        sum(quantity*price) as income,
        count (s.product_id) as operations
            from employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by (first_name||' '|| last_name)
    ) as t 
    order by floor(income) desc nulls last
    limit 10;

   
--Данный запрос информацию о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам.
--Таблица отсортирована по выручке по возрастанию.

   select
    distinct (first_name||' '|| last_name) as name, 
               round(avg(quantity*price)) as average_income
    from employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by first_name,last_name
     having round(avg(quantity*price)) < (select avg(average_income) from (SELECT
    distinct (first_name||' '|| last_name) as name, 
               round(avg(quantity*price)) as average_income
    from employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by first_name,last_name)as avg_income_sales)
   order by average_income;
    
    
-- Данный запрос выводит имя и фамилию продавца, день недели и суммарную выручку, сортировка по порядковому номеру дня недели и name
   
    with tab as (select
    (first_name||' '||last_name) as name, 
       sum(quantity*price) as income, 
       to_char(sale_date, 'Day') as weekday,
        extract(isodow from sale_date) as dow
    from employees e
    inner join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by (first_name||' '||last_name), to_char(sale_date, 'Day'), extract(isodow from sale_date))
    select name, lower(weekday) as weekday, round(income) as income
    from tab
    order by dow, name

--Данный запрос выводит количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+, сортировка по возрастным группам
 
with tab as(select case when age between 16 and 25 then '16-25'
     when age between 26 and 40 then '26-40'
     when age > 40 then '40+' end as age_category 
     from customers c)
     select age_category, count(age_category)
     from tab
     group by age_category
     order by age_category

    -- Данный запрос выводит количество уникальных покупателей и выручке, сортировка по дате по возрастанию   
        
   with tab as (
   select to_char(sale_date, 'YYYY-MM') as date,
          customer_id,
          sum(quantity*price) as income
  from  employees left join sales s on employee_id = s.sales_person_id  
  left join products p on s.product_id = p.product_id
  where to_char(sale_date, 'YYYY-MM') is not null
  group by  to_char(sale_date, 'YYYY-MM'), customer_id
    )
    select distinct date, 
                    count(customer_id) as total_customers,
                    floor(sum(income)) as income
    from tab
    group by date
    order by date;
    
  
     
    --Данный запрос выводит таблицу с покупателями, первая покупка которых пприходилась на время проведения акции 
    --(акционные товары отпускали со стоимостью равной 0)
    -- сортировка по id покуптеля
    
    
    with tab as
    (
    select (c.first_name||' '||c.last_name) as customer, min(sale_date) as sale_date, 
    sum(price*quantity)
    from customers c 
    left join sales s on c.customer_id = s.customer_id
    left join products p on s.product_id = p.product_id
    group by (c.first_name||' '||c.last_name)
    having sum(price*quantity) = 0
    ), tab2 as 
    (
   select (c.first_name||' '||c.last_name) as customer, min(sale_date) as sale_date, 
    (e.first_name||' '|| e.last_name) as seller
    from sales s
    left join customers c on s.customer_id = c.customer_id
    left join employees e  on e.employee_id = s.sales_person_id
    group by (c.first_name||' '||c.last_name), (e.first_name||' '|| e.last_name)
    )
    select tab.customer, tab.sale_date, seller
    from tab
    inner join tab2 on tab.customer = tab2.customer 
    and tab.sale_date = tab2.sale_date
    group by tab.customer, tab.sale_date, seller
    order by customer
    
 