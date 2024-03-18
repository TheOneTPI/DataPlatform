------------------
-- QUERY 001
------------------
select ddate.d_year
 , count(*) 
from trino_poc.web_sales sale
inner join trino_poc.date_dim ddate
on sale.ws_sold_date_sk = ddate.d_date_sk
group by ddate.d_year;

-- result query time
--> 2 min 25s