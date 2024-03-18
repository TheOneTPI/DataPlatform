-- schema pointant sur bucket iceberg
drop schema if exists  iceberg_test.iceberg_poc cascade;

CREATE SCHEMA iceberg_test.iceberg_poc
WITH (location = 's3a://iceberg-poc/');

-- table customer
CREATE TABLE iceberg_test.iceberg_poc.customer (
	c_customer_sk bigint,
	c_customer_id varchar(16),
	c_current_cdemo_sk bigint,
	c_current_hdemo_sk bigint,
	c_current_addr_sk bigint,
	c_first_shipto_date_sk bigint,
	c_first_sales_date_sk bigint,
	c_salutation varchar(10),
	c_first_name varchar(20),
	c_last_name varchar(30),
	c_preferred_cust_flag varchar(1),
	c_birth_day integer,
	c_birth_month integer,
	c_birth_year integer,
	c_birth_country varchar(20),
	c_login varchar(13),
	c_email_address varchar(50),
	c_last_review_date_sk bigint
)
;

delete from iceberg_test.iceberg_poc.customer;
insert into iceberg_test.iceberg_poc.customer select * from tpcds.sf1000.customer;
--

-- table customer_adress
CREATE TABLE iceberg_test.iceberg_poc.customer_address (
	ca_address_sk bigint,
	ca_address_id varchar(16),
	ca_street_number varchar(10),
	ca_street_name varchar(60),
	ca_street_type varchar(15),
	ca_suite_number varchar(10),
	ca_city varchar(60),
	ca_county varchar(30),
	ca_state varchar(2),
	ca_zip varchar(10),
	ca_country varchar(20),
	ca_gmt_offset decimal(5,2),
	ca_location_type varchar(20)
);

delete from iceberg_test.iceberg_poc.customer_address;
insert into iceberg_test.iceberg_poc.customer_address select * from tpcds.sf1000.customer_address;
--

-- table item
CREATE TABLE iceberg_test.iceberg_poc.item (
	i_item_sk bigint,
	i_item_id varchar(16),
	i_rec_start_date date,
	i_rec_end_date date,
	i_item_desc varchar(200),
	i_current_price decimal(7,2),
	i_wholesale_cost decimal(7,2),
	i_brand_id integer,
	i_brand varchar(50),
	i_class_id integer,
	i_class varchar(50),
	i_category_id integer,
	i_category varchar(50),
	i_manufact_id integer,
	i_manufact varchar(50),
	i_size varchar(20),
	i_formulation varchar(20),
	i_color varchar(20),
	i_units varchar(10),
	i_container varchar(10),
	i_manager_id integer,
	i_product_name varchar(50)
);

delete from iceberg_test.iceberg_poc.item;
insert into iceberg_test.iceberg_poc.item select * from tpcds.sf1000.item;
--

-- table date_dim
CREATE TABLE iceberg_test.iceberg_poc.date_dim (
	d_date_sk bigint,
	d_date_id varchar(16),
	d_date date,
	d_month_seq integer,
	d_week_seq integer,
	d_quarter_seq integer,
	d_year integer,
	d_dow integer,
	d_moy integer,
	d_dom integer,
	d_qoy integer,
	d_fy_year integer,
	d_fy_quarter_seq integer,
	d_fy_week_seq integer,
	d_day_name varchar(9),
	d_quarter_name varchar(6),
	d_holiday varchar(1),
	d_weekend varchar(1),
	d_following_holiday varchar(1),
	d_first_dom integer,
	d_last_dom integer,
	d_same_day_ly integer,
	d_same_day_lq integer,
	d_current_day varchar(1),
	d_current_week varchar(1),
	d_current_month varchar(1),
	d_current_quarter varchar(1),
	d_current_year varchar(1)
);


delete from iceberg_test.iceberg_poc.date_dim;
insert into iceberg_test.iceberg_poc.date_dim select * from tpcds.sf1000.date_dim;
--

-- table time_dim
CREATE TABLE iceberg_test.iceberg_poc.time_dim (
	t_time_sk bigint,
	t_time_id varchar(16),
	t_time integer,
	t_hour integer,
	t_minute integer,
	t_second integer,
	t_am_pm varchar(2),
	t_shift varchar(20),
	t_sub_shift varchar(20),
	t_meal_time varchar(20)
);

delete from iceberg_test.iceberg_poc.time_dim;
insert into iceberg_test.iceberg_poc.time_dim select * from tpcds.sf1000.time_dim;
--
 
-- table web_sales
CREATE TABLE iceberg_test.iceberg_poc.web_sales (
	ws_sold_date_sk bigint,
	ws_sold_time_sk bigint,
	ws_item_sk bigint,
	ws_bill_customer_sk bigint,
	ws_bill_addr_sk bigint,
	ws_ship_customer_sk bigint,
	ws_ship_addr_sk bigint,
	ws_order_number bigint,
	ws_quantity integer,
	ws_wholesale_cost decimal(7,2),
	ws_list_price decimal(7,2),
	ws_sales_price decimal(7,2),
	ws_ext_discount_amt decimal(7,2),
	ws_ext_sales_price decimal(7,2),
	ws_ext_wholesale_cost decimal(7,2),
	ws_ext_list_price decimal(7,2),
	ws_ext_tax decimal(7,2),
	ws_coupon_amt decimal(7,2),
	ws_ext_ship_cost decimal(7,2),
	ws_net_paid decimal(7,2),
	ws_net_paid_inc_tax decimal(7,2),
	ws_net_paid_inc_ship decimal(7,2),
	ws_net_paid_inc_ship_tax decimal(7,2),
	ws_net_profit decimal(7,2)
);

delete from iceberg_test.iceberg_poc.web_sales;
-- using postgresql web_sales to get the same sales data
insert into iceberg_test.iceberg_poc.web_sales 
select 	ws_sold_date_sk,
	ws_sold_time_sk,
	ws_item_sk,
	ws_bill_customer_sk,
	ws_bill_addr_sk,
	ws_ship_customer_sk,
	ws_ship_addr_sk,
	ws_order_number,
	ws_quantity integer,
	ws_wholesale_cost,
	ws_list_price,
	ws_sales_price,
	ws_ext_discount_amt,
	ws_ext_sales_price,
	ws_ext_wholesale_cost,
	ws_ext_list_price,
	ws_ext_tax,
	ws_coupon_amt,
	ws_ext_ship_cost,
	ws_net_paid,
	ws_net_paid_inc_tax,
	ws_net_paid_inc_ship,
	ws_net_paid_inc_ship_tax,
	ws_net_profit
from postgres_test.trino_poc.web_sales;
--