DO $$
BEGIN
  RAISE INFO '
Задание 2. Аналитикам нужно оценить, насколько отдел планирования хорошо делает свою работу. Для этого необходимо разработать SQL-скрипт, который формирует таблицу со следующим набором атрибутов:
- shop_name — название магазина,
- product_name — название товара,
- sales_fact — количество фактических продаж на конец месяца,
- sales_plan — количество запланированных продаж на конец месяца,
- sales_fact/sales_plan — отношение количества фактических продаже к запланированному,
- income_fact — фактический доход,
- income_plan — планируемый доход,
- income_fact/income_plan — отношение фактического дохода к запланированному.';
END;
$$;
WITH subquery_citilink AS (SELECT DATE_PART('MONTH',  sale_date) AS sale_month,
	   							 shop_name, 
	   							 product_name, 
	   							 SUM(sales_cnt)  sales_fact,
	   							 SUM(plan_cnt) sales_plan,
	   							 ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
	   							 SUM(price * sales_cnt) income_fact, 
	   							 SUM(price * plan_cnt) income_plan,
	   							 ROUND((SUM(price * sales_cnt)::NUMERIC / SUM(price * plan_cnt)), 2) "income_fact/income_plan"
						  FROM shops
						  JOIN shop_citilink USING (shop_id)
						  JOIN products USING (product_id)
						  JOIN plan USING (product_id)
						  WHERE DATE_PART('MONTH',  sale_date) = 5
						  GROUP BY sale_month, shop_name, product_name),
	 subquery_dns AS (SELECT DATE_PART('MONTH',  sale_date) AS sale_month,
	   							 shop_name, 
	   							 product_name, 
	   							 SUM(sales_cnt)  sales_fact,
	   							 SUM(plan_cnt) sales_plan,
	   							 ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
	   							 SUM(price * sales_cnt) income_fact, 
	   							 SUM(price * plan_cnt) income_plan,
	   							 ROUND((SUM(price * sales_cnt)::NUMERIC / SUM(price * plan_cnt)), 2) "income_fact/income_plan"
						  FROM shops
						  JOIN shop_dns USING (shop_id)
						  JOIN products USING (product_id)
						  JOIN plan USING (product_id)
						  WHERE DATE_PART('MONTH',  sale_date) = 5
						  GROUP BY sale_month, shop_name, product_name),
	 subquery_mvideo AS (SELECT DATE_PART('MONTH',  sale_date) AS sale_month,
	   							 shop_name, 
	   							 product_name, 
	   							 SUM(sales_cnt)  sales_fact,
	   							 SUM(plan_cnt) sales_plan,
	   							 ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
	   							 SUM(price * sales_cnt) income_fact, 
	   							 SUM(price * plan_cnt) income_plan,
	   							 ROUND((SUM(price * sales_cnt)::NUMERIC / SUM(price * plan_cnt)), 2) "income_fact/income_plan"
						  FROM shops
						  JOIN shop_mvideo USING (shop_id)
						  JOIN products USING (product_id)
						  JOIN plan USING (product_id)
						  WHERE DATE_PART('MONTH',  sale_date) = 5
						  GROUP BY sale_month, shop_name, product_name)
SELECT * FROM subquery_citilink
UNION ALL 
SELECT * FROM subquery_dns
UNION ALL 
SELECT * FROM subquery_mvideo
ORDER BY shop_name, product_name