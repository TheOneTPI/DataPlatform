------------------
-- QUERY 001
------------------
select ddate.d_year
 , count(*) 
from iceberg_test.iceberg_poc.web_sales sale
inner join iceberg_test.iceberg_poc.date_dim ddate
on sale.ws_sold_date_sk = ddate.d_date_sk
group by ddate.d_year;

-- result query time
--> 4s