--Данный запрос считает общее количество покупателей из таблицы customers--
select count(customer_id) as customers_count from customers c 

--Шаг 5 таб 1
--Данный запрос выводит имя и фамилию продавца, суммарную выручку с проданных товаров и количество проведенных сделок 
--Сортировка по убыванию выручки, нули в конце

select distinct
    t.name, t.operations, t.income
FROM (
    select
    (first_name||' '|| last_name) as name, 
        row_number () over( partition by first_name) AS row_number,
        first_name, last_name, p.product_id, quantity, price, round(quantity*price) as income,
        count (s.product_id) over(partition by first_name, last_name) as operations,
        sum (quantity*price) over (partition by first_name, last_name)
    FROM employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    ) AS t WHERE t.row_number = 1
order by income desc nulls last
limit 10;

--шаг 5 таб 2
--Данный запрос информацию о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам.
--Таблица отсортирована по выручке по возрастанию.

SELECT
    distinct (first_name||' '|| last_name) as name, 
               round(avg(quantity*price)) as average_income
    FROM employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by first_name,last_name, p.product_id, quantity, price, s.product_id
    having round(avg(quantity*price)) < (select avg(average_income) from (SELECT
    distinct (first_name||' '|| last_name) as name, 
               round(avg(quantity*price)) as average_income
    FROM employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by first_name,last_name, p.product_id, quantity, price, s.product_id)as avg_income_sales);
    

--шаг 5 таб 3
-- Данный запрос выводит имя и фамилию продавца, день недели и суммарную выручку, сортировка по порядковому номеру дня недели и name
select name, weekday, round(income)
from (
    SELECT
    (first_name||' '||last_name) as name, 
       sum(quantity*price) as income, 
       to_char(sale_date, 'Day')as weekday,
        EXTRACT(ISODOW FROM sale_date) as dow
    FROM employees e
    left join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by (first_name||' '||last_name), p.product_id, quantity, price, s.product_id, sale_date
) AS t
order by dow, name, weekday;



--Шаг 6 таб 1
--Данный запрос выводит количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+, сортировка по возрастным группам
with tab as (select age, 
ntile (3) over(order by age) as age_category
from customers c)
select distinct case when age_category = 1 then '16-25'
     when age_category = 2 then '26-40'
     when age_category = 3 then '40+' end as age_category,
     count(age_category) over(partition by age_category) as count
from tab
order by age_category;


--Шаг 6 таб 2
-- Данный запрос выводит количество уникальных покупателей и выручке, сортировка по дате по возрастанию   
    
    with tab as (select to_char(sale_date, 'YYYY-MM') as date,
    count(customer_id) over(partition by sale_date) as total_customers,
    sum(round(quantity*price)) over(partition by sale_date) as income
        from  employees left join sales s on employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id)
    select distinct date, total_customers, income
    from tab
    order by date; 

    
    --Шаг 6 таб 3
    --Данный запрос выводит таблицу с покупателями, первая покупка которых пприходилась на время проведения акции 
    --(акционные товары отпускали со стоимостью равной 0)
    -- сортировка по id покуптеля
    
    with tab as(select (c.first_name||' '||c.last_name) as customer,
    sale_date, price, c.customer_id, 
    (e.first_name||' '|| e.last_name) as seller
    from customers c 
    left join sales s on c.customer_id = s.customer_id
    left join employees e  on e.employee_id = s.sales_person_id 
    left join products p on s.product_id = p.product_id)
    select customer, sale_date, seller from tab
    where price = '0'
    order by customer_id