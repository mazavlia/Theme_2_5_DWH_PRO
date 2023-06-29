DO $$
BEGIN
  RAISE INFO '
Задание:
При работе по сбору витрины для анализа эффективности плана продаж, к вам обратился ваш руководитель и сообщил, что надо обязательно к схеме данных добавить таблицу о промо-акциях на те или иные товары, иначе финальная витрина будет недостаточно информативной.
Таким образом, в вашей схеме появляется новая таблица - promo, которая содержит информацию о том: в каком магазине, в какой день, на какой продукт и какого размера была скидка.
Вам также нужно к итоговой витрине, которую вы получили при выполнении базового задания, добавить несколько новых атрибутов:
- avg(sales/date) - среднее количество продаж в день,
- max_sales - максимальное количество продаж за один день,
- date_max_sales - день, в который произошло максимальное количество продаж,
- date_max_sales_is_promo - факт того, действовала ли скидка в тот день, когда произошло максимальное количество продаж,
- avg(sales/date) / max_sales - отношение среднего количества продаж к максимальному,
- promo_len - количество дней месяце когда на товар действовала скидка,
- promo_sales_cnt - количество товаров проданных в дни скидок,
- promo_sales_cnt/fact_sales - отношение количества товаров проданных в дни скидки к общему количеству проданных товаров за месяц,
- promo_income - доход с продаж в дни акций,
- promo_income/fact_income - отношение дохода с продаж в дни акций к общему доходу с продаж за месяц';
END;
$$;
WITH union_shops_tabl AS (SELECT * FROM shop_citilink
						  UNION SELECT * FROM shop_dns
						  UNION SELECT * FROM shop_mvideo
						  ORDER BY sale_date, shop_id, product_id),
	price_promo AS (SELECT us.shop_id, us.product_id, sale_date, pr.price, discount, 
 					CASE WHEN discount IS NOT NULL THEN ROUND((price::NUMERIC * (100 - discount) / 100), 0)
 					ELSE price END AS full_price
 					FROM union_shops_tabl us
 					JOIN products pr
 					ON pr.product_id = us.product_id
 					LEFT JOIN promo p
 					ON us.shop_id = p.shop_id AND us.product_id = p.product_id AND us.sale_date = p.promo_date),
 	sales AS (SELECT shop_id, product_id, sales_cnt fact_sales, sale_date
			  FROM union_shops_tabl 
			  GROUP BY sale_date, shop_id, product_id, fact_sales),
	promo_sales AS (SELECT us.shop_id, us.product_id, us.sales_cnt sal_ctn, sale_date
			  		FROM union_shops_tabl us
			  		JOIN promo pm ON us.shop_id = pm.shop_id AND us.product_id = pm.product_id AND us.sale_date = promo_date),
	full_sales AS (SELECT shop_id, product_id, 
 	 				MAX(sales_cnt) max_sales_quer, 
 					sale_date, SUM(sales_cnt) promo_count
 					FROM union_shops_tabl
 					WHERE DATE_PART('MONTH',  sale_date) = 5 
 					GROUP BY sale_date, shop_id, product_id),
 	calc_max_date AS (SELECT shop_id, product_id, max(sales_cnt), sale_date
			  		  FROM union_shops_tabl 
			  		  GROUP BY shop_id, product_id, sale_date, sales_cnt)
SELECT shop_name, 
	   product_name, 
	   SUM(sales_cnt) sales_fact,
	   SUM(plan_cnt) sales_plan,
	   ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
	   SUM(full_price * sales_cnt) income_fact,
	   SUM(full_price * plan_cnt) income_plan,
	   ROUND(SUM(full_price * sales_cnt)::NUMERIC / SUM(full_price * plan_cnt), 2) "income_fact/income_plan",
	   ROUND(SUM(sales_cnt)::NUMERIC / COUNT(us.sale_date), 2) "avg(sales/date)",
	   MAX(fact_sales) max_sales, 
	   (SELECT sale_date FROM sales WHERE fact_sales = (SELECT max(fact_sales) FROM sales)) max_sale_date,
	   (SELECT CASE 
		   	   WHEN (SELECT s.sale_date FROM sales s GROUP BY s.sale_date HAVING MAX(s.fact_sales) = (SELECT MAX(fact_sales) FROM sales)) IN (SELECT promo_date FROM promo) 
		   	   THEN 'TRUE' ELSE 'FALSE' 
		   	   END) date_max_sales_is_promo,
	   ROUND((SUM(sales_cnt)::NUMERIC / COUNT(us.sale_date)) / MAX(fact_sales), 2) "avg(sales/date) / max_sales",
	   (SELECT COUNT(DISTINCT promo_date) FROM promo) promo_len,
	   SUM(sal_ctn) promo_sales_cnt,
	   ROUND((SUM(sal_ctn)::NUMERIC / SUM(sales_cnt)), 2) "promo_sales_cnt/fact_sales",
	   SUM(full_price * sal_ctn) promo_income,
	   ROUND(SUM(full_price * sal_ctn) / SUM(full_price * sales_cnt), 2) "promo_income/fact_income"
FROM union_shops_tabl us
JOIN shops sh ON us.shop_id = sh.shop_id
JOIN products pr ON us.product_id = pr.product_id 
JOIN plan p ON us.product_id = p.product_id AND us.shop_id = p.shop_id AND us.sale_date = p.plan_date
JOIN price_promo pp ON us.shop_id = pp.shop_id AND us.product_id = pp.product_id AND us.sale_date = pp.sale_date
JOIN sales s ON s.sale_date = us.sale_date AND s.shop_id = us.shop_id AND s.product_id = us.product_id AND s.sale_date = us.sale_date
LEFT JOIN promo_sales ps ON ps.shop_id = us.shop_id AND ps.product_id = us.product_id AND ps.sale_date = us.sale_date
WHERE DATE_PART('MONTH',  us.sale_date) = 5
GROUP BY shop_name, product_name
ORDER BY shop_name, product_name

-- WITH union_shops_tabl AS (SELECT * FROM shop_citilink
-- 						  UNION SELECT * FROM shop_dns
-- 						  UNION SELECT * FROM shop_mvideo
-- 						  ORDER BY sale_date, shop_id, product_id),
-- 	 full_sales AS (SELECT shop_id, product_id, 
-- 	 				MAX(sales_cnt) max_sales_quer, 
-- 					sale_date, SUM(sales_cnt) promo_count
-- 					FROM union_shops_tabl
-- 					WHERE DATE_PART('MONTH',  sale_date) = 5 
-- 					GROUP BY sale_date, shop_id, product_id)
-- WITH union_shops_tabl AS (SELECT * FROM shop_citilink
-- 						  UNION SELECT * FROM shop_dns
-- 						  UNION SELECT * FROM shop_mvideo
-- 						  ORDER BY sale_date, shop_id, product_id)	  
-- SELECT DATE_PART('MONTH',  sale_date) AS sale_month,
-- 	   shop_name, 
-- 	   product_name, 
-- 	   SUM(sales_cnt) sales_fact,
-- 	   SUM(plan_cnt) sales_plan,
-- 	   ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
-- 	   SUM(price * sales_cnt) income_fact,
-- 	   SUM(price * plan_cnt) income_plan,
-- 	   ROUND((SUM(price * sales_cnt)::NUMERIC / SUM(price * plan_cnt)), 2) "income_fact/income_plan"
-- FROM union_shops_tabl us
-- JOIN shops sh ON us.shop_id = sh.shop_id
-- JOIN products pr ON us.product_id = pr.product_id 
-- JOIN plan p ON us.product_id = p.product_id AND us.shop_id = p.shop_id AND us.sale_date = p.plan_date 
-- WHERE DATE_PART('MONTH',  sale_date) = 5
-- GROUP BY sale_month, shop_name, product_name
-- ORDER BY shop_name, product_name

-- SELECT shop_name, 
-- 	   product_name, 
-- 	   SUM(sales_cnt) sales_fact,
-- 	   SUM(plan_cnt) sales_plan,
-- 	   ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
-- 	   SUM(price * sales_cnt) income_fact, 
-- 	   SUM(price * plan_cnt) income_plan,
-- 	   ROUND((SUM(price * sales_cnt)::NUMERIC / SUM(price * plan_cnt)), 2) "income_fact/income_plan",
-- 	   SUM(sales_cnt)/COUNT(sale_date) "avg(sales/date)",
-- 	   (SELECT MAX(max_sales_quer) FROM full_sales) max_sales,
-- 	   (SELECT sale_date FROM full_sales WHERE max_sales_quer = (SELECT MAX(max_sales_quer) FROM full_sales)) date_max_sales,
-- 	   (SELECT CASE WHEN (SELECT sale_date FROM full_sales WHERE max_sales_quer = (SELECT MAX(max_sales_quer) FROM full_sales)) IN (SELECT promo_date FROM promo) THEN 'TRUE' ELSE 'FALSE' END CASE) date_max_sales_is_promo,
-- 	   ROUND(((SUM(sales_cnt)/COUNT(sale_date))::NUMERIC / (SELECT MAX(max_sales_quer) FROM full_sales)), 2) "avg(sales/date)/max_sales",
-- 	   (SELECT COUNT(DISTINCT promo_date) FROM promo) promo_len,
-- 	   (SELECT SUM(sales_cnt) FROM union_shops_tabl WHERE sale_date IN (SELECT promo_date FROM promo)) promo_sales_cnt 
-- FROM shops
-- JOIN union_shops_tabl USING (shop_id)
-- JOIN products USING (product_id)
-- JOIN plan USING (product_id)
-- WHERE DATE_PART('MONTH',  sale_date) = 5
-- GROUP BY shop_name, product_name
-- ORDER BY shop_name, product_name

-- -- SELECT shop_id, MAX(sales_cnt) max_sales, 
-- -- 	DATE_PART('DAY',  sale_date) AS sale_day
-- -- 	FROM (SELECT * FROM shop_citilink
-- -- 						  UNION SELECT * FROM shop_dns
-- -- 						  UNION SELECT * FROM shop_mvideo
-- -- 						  ORDER BY sale_date, shop_id, product_id) union_shops_tabl
-- -- 	WHERE DATE_PART('MONTH',  sale_date) = 5 
-- -- 	GROUP BY sale_day, shop_id


-- WITH 
-- 	union_shops_tabl AS (SELECT * FROM shop_citilink
-- 						  UNION SELECT * FROM shop_dns
-- 						  UNION SELECT * FROM shop_mvideo
-- 						  ORDER BY sale_date, shop_id, product_id),
-- 	price_promo AS (SELECT u.shop_id, u.product_id, sale_date, pr.price, discount, 
-- 					CASE WHEN discount IS NOT NULL THEN ROUND((price::NUMERIC * (100 - discount) / 100), 0)
-- 					ELSE price END AS full_price
-- 					FROM union_shops_tabl u
-- 					JOIN products pr
-- 					ON pr.product_id = u.product_id
-- 					LEFT JOIN promo p
-- 					ON u.shop_id = p.shop_id AND u.product_id = p.product_id AND u.sale_date = p.promo_date)

WITH union_shops_tabl AS (SELECT * FROM shop_citilink
						  UNION SELECT * FROM shop_dns
						  UNION SELECT * FROM shop_mvideo
						  ORDER BY sale_date, shop_id, product_id),
	price_promo AS (SELECT us.shop_id, us.product_id, sale_date, pr.price, discount, 
 					CASE WHEN discount IS NOT NULL THEN ROUND((price::NUMERIC * (100 - discount) / 100), 0)
 					ELSE price END AS full_price
 					FROM union_shops_tabl us
 					JOIN products pr
 					ON pr.product_id = us.product_id
 					LEFT JOIN promo p
 					ON us.shop_id = p.shop_id AND us.product_id = p.product_id AND us.sale_date = p.promo_date),
 	sales AS (SELECT shop_id, product_id, SUM(sales_cnt) sales_fact, sale_date
			  FROM union_shops_tabl 
			  GROUP BY sale_date, shop_id, product_id),
	promo_sales AS (SELECT us.shop_id, us.product_id, promo_date, us.sales_cnt sales_count FROM promo pm  
					JOIN union_shops_tabl us ON promo_date = us.sale_date)
SELECT shop_name, 
	   product_name, 
	   SUM(sales_cnt) sales_fact,
	   SUM(plan_cnt) sales_plan,
	   ROUND(SUM(sales_cnt)::NUMERIC / SUM(plan_cnt), 2) "sales_fact/sales_plan",
	   SUM(full_price * sales_cnt) income_fact,
	   SUM(full_price * plan_cnt) income_plan,
	   ROUND(SUM(full_price * sales_cnt)::NUMERIC / SUM(full_price * plan_cnt), 2) "income_fact/income_plan",
	   ROUND(SUM(sales_cnt)::NUMERIC / COUNT(us.sale_date), 2) "avg(sales/date)",
	   MAX(sales_fact) max_sales,
	   (SELECT max(sale_date) FROM sales WHERE sales_fact = (SELECT max(sales_fact) FROM (SELECT sales_fact FROM sales GROUP BY sale_date, shop_id, product_id, sales_fact) t)) max_sale_date,
	   ROUND((SUM(sales_cnt)::NUMERIC / COUNT(us.sale_date)) / MAX(sales_fact), 2) "avg(sales/date) / max_sales", 
	   COUNT(DISTINCT promo_date) promo_len
FROM union_shops_tabl us
JOIN shops sh ON us.shop_id = sh.shop_id
JOIN products pr ON us.product_id = pr.product_id 
JOIN plan p ON us.product_id = p.product_id AND us.shop_id = p.shop_id AND us.sale_date = p.plan_date
JOIN price_promo pp ON us.shop_id = pp.shop_id AND us.product_id = pp.product_id AND us.sale_date = pp.sale_date
JOIN sales s ON s.sale_date = us.sale_date AND s.shop_id = us.shop_id AND s.product_id = us.product_id
JOIN promo pm ON pm.shop_id = us.shop_id AND pm.product_id = us.product_id
WHERE DATE_PART('MONTH',  us.sale_date) = 5
GROUP BY shop_name, product_name
ORDER BY shop_name, product_name