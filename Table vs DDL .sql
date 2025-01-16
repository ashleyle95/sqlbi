--1. Create dimension table: dim_report_item , dim_asm, dim_city, 
--2. Create transformation table for calculation:
	-- rule_temp: Table for storing distribution rates for head office values (fact_summary_area)
	-- area_temp: Table for storing and calculating values for areas, before and after adding head office amounts (fact_summary_area)
	-- npl_before_wo, rate_npl:calculating the non-performing loan rate before write-off and the rate for each area (fact_avg_asm)
--3. Create target table: fact_summary_area, fact_avg_asm 
--4. Create log_tracking
------------------------------------------------------------------

--1. Create dimension table
	--Table dim_report_item 
CREATE TABLE dim_report_item (
	report_item_id int4 NULL,
	item_name varchar(1024) NULL,
	report_item_code varchar(1024) NULL,
	item_parent int4 NULL,
	item_level int4 NULL,
	sort_order int4 NULL,
	rule_id int4 NULL
);
	--Table dim_asm 
CREATE TABLE dim_asm AS
	SELECT email, area_name, sale_name
	FROM fact_kpi_asm f
	GROUP BY email, area_name, sale_name
	-- Table dim_city
CREATE TABLE dim_city (
	pos_city varchar(1024) NULL,
	city_code varchar(1024) NULL,
	area_code varchar(1024) NULL,
	area_name varchar(1024) NULL
);
--2. Create transformation table for calculation:
CREATE TABLE area_temp (
	month_key int4 NULL,
	report_item_id int4 NULL,
	area_code varchar NULL,
	area_amount int8 NULL,
	rate numeric NULL,
	total_amount numeric NULL
);
CREATE TABLE rule_temp (
	month_key int4 NULL,
	area_code varchar NULL,
	rate numeric NULL,
	rule_id int4 NULL
);
CREATE TABLE npl_before_wo (
	month_key int4 NULL,
	area_code varchar NULL,
	area_name varchar NULL,
	accumulated_balance_before_wo numeric NULL,
	accumulated_npl_before_wo numeric NULL
);	
CREATE TABLE rate_npl (
	month_key int4 NULL,
	area_code varchar NULL,
	area_name varchar NULL,
	accumulated_npl_before_wo numeric NULL
);
--3. Create target table: fact_summary_area, fact_avg_asm
CREATE TABLE fact_summary_area (
	month_key int4 NULL,
	report_item_id int4 NULL,
	area_code varchar NULL,
	total_amount numeric NULL
);	


CREATE TABLE fact_avg_asm (
	month_key int4 NULL,
	area_code varchar NULL,
	area_name varchar NULL,
	email varchar NULL,
	total_point int4 NULL,
	rank_final int4 NULL,
	ltn_avg numeric NULL,
	rank_ltn_avg int4 NULL,
	psdn_avg numeric NULL,
	rank_psdn_avg int4 NULL,
	approval_rate_avg numeric NULL,
	rank_approval_rate_avg int4 NULL,
	accumulated_npl_before_wo numeric NULL,
	rank_npl int4 NULL,
	scale_point int4 NULL,
	rank_sale int4 NULL,
	cir numeric NULL,
	rank_cir int4 NULL,
	margin numeric NULL,
	rank_margin int4 NULL,
	roc numeric NULL,
	rank_roc int4 NULL,
	avg_performance_employee numeric NULL,
	rank_employee_performance int4 NULL,
	fin_point int4 NULL,
	rank_fin int4 NULL
);
--4. Create log_tracking
CREATE TABLE IF NOT EXISTS log_tracking (
	log_id SERIAL PRIMARY KEY,
	procedure_name VARCHAR(255) NOT NULL,
	start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	end_time TIMESTAMP,
	is_successful BOOLEAN,
	error_log TEXT,
	rec_created_dt TIMESTAMP DEFAULT CURRENT_DATE
	); 

	