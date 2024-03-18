------------------
-- QUERY 001
------------------
select ddate.d_year
 , count(*) 
from postgres_test.trino_poc.web_sales sale
inner join postgres_test.trino_poc.date_dim ddate
on sale.ws_sold_date_sk = ddate.d_date_sk
group by ddate.d_year;

-- result query time
--> 1 min 38s