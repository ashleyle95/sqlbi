-----------------------------------------------------------------
--Procedure name		: back_date_report 
--Purpose				: For any paramater of month_key, export backdate reporting data
--Author				: Minh Chau Le
--Created				: on Sep 28, 2024
--Editor, version and purpose of modification (if applicable)
--Summary:
--1. Declare variable
--2. Main logic
--SECTION A: Target Table fact_summary_area 
--Step A1: Truncate rule_temp table to calculate distribution rates for head office values (based on dim_rule).
	--Rule 1: Average ending balance after write off(max_bucket:1) 
	--Rule 2: Average ending balance after write off( max_bucket:2) 
	--Rule 3: Average ending balance after write off(max_bucket:2,3,4,5) 
	--Rule 4: Average ending balance after write off (all max_bucket)
	--Rule 6: New customer Number
	--Rule 7: Percentage of ASM number 
--Step A2: Truncate area_temp table to calculate values after adding distributed head office values.
--Step A3: Insert results to target table
--SECTION B: Target Table fact_summary_employee	
--Step B1: Delete the records in table fact_avg_asm with input month_key
--Step B2: Insert values to table npl_before_wo, rate_npl (calculation: accumulated_npl_before_wo,rank_npl)
--Step B3: Insert values to target table fact_avg_asm
--3. Handle the exception: Table log_tracking
-----------------------------------------------------------------
CREATE OR replace PROCEDURE back_date_report(month_key_in int)
LANGUAGE plpgsql
AS $$
--Step 1:Declare variable
DECLARE 
month_key_v int;

start_month_key_v int;
BEGIN
--Default to the previous month if no input is provided
IF month_key_in IS NULL THEN 
	month_key_v := TO_CHAR(CURRENT_DATE - INTERVAL '1 month','YYYYMM')::int;
ELSE month_key_v := month_key_in;
END IF;
start_month_key_v := (TO_CHAR(TO_DATE(month_key_v::text,'YYYYMM'),'YYYY') || '01')::int;
DELETE
FROM fact_summary_area
WHERE month_key = month_key_v;
--Step 2: Main Logic
--------------SECTION A: TABLE TARGET fact_summary_area--------------
--Step A1: Truncate table rule_temp. Detail of rule info in table dim_rule 
TRUNCATE TABLE rule_temp;
--Rule 1: Average ending balance after write off(max_bucket:1) 
INSERT INTO rule_temp
	(month_key,
	area_code,
	rate,
	rule_id)
SELECT
	month_key_v AS month_key, 
	y.area_code,
	COALESCE(avg_principal_aft_wo / sum(avg_principal_aft_wo) OVER(),
	0)::NUMERIC AS rate,
	1 AS rule_id
FROM
	--y: average ending balance
	(
	SELECT
		month_key_v AS month_key, 
		COALESCE(avg(principal_aft_wo),
		0) AS avg_principal_aft_wo, 
		area_code
	FROM
		--x: total cumulative principal in month_key_v	
		(
		SELECT
			kpi_month,
			area_code, 
			sum(outstanding_principal) AS principal_aft_wo
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON
			d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND COALESCE(max_bucket,
			1)= 1
			-- max_bucket NULL=1
		GROUP BY
			kpi_month,
			area_code
		)x
	GROUP BY area_code
	)y
UNION ALL
--Rule 2: Average ending balance after write off( max_bucket:2) 
SELECT
	month_key_v AS month_key, 
	area_code, 
	COALESCE(avg_principal_aft_wo / sum(avg_principal_aft_wo) OVER(),0)::NUMERIC AS rate,
	2 AS rule_id
FROM
	--y: Average ending balance
	(
	SELECT
		month_key_v AS month_key,
		COALESCE(avg(principal_aft_wo),0) AS avg_principal_aft_wo,
		area_code
	FROM
		--x: total cumulative principal in month_key_v	
		(
		SELECT
			kpi_month,
			area_code,
			sum(outstanding_principal) AS principal_aft_wo
		FROM
			fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND max_bucket = 2
		GROUP BY
			kpi_month,
			area_code)x
	GROUP BY area_code
	)y
UNION ALL
--Rule 3: Average ending balance after write off(max_bucket:2,3,4,5) 
SELECT
	month_key_v AS month_key, 
	area_code, 
	COALESCE(avg_principal_aft_wo / sum(avg_principal_aft_wo) OVER(),0)::NUMERIC AS rate,
	3 AS rule_id
FROM
	--y: average ending balance
	(
	SELECT
		month_key_v AS month_key, 
		COALESCE(avg(principal_aft_wo),0) AS avg_principal_aft_wo,
		area_code
	FROM
		--x: total cumulative principal in month_key_v	
	(
		SELECT
			kpi_month,
			area_code,
			sum(outstanding_principal) AS principal_aft_wo
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND max_bucket IN(2, 3, 4, 5)
		GROUP BY
			kpi_month,
			area_code
		)x
	GROUP BY area_code
	)y
UNION ALL
--Rule 4: Average ending balance after write off (all max_bucket)
	SELECT
		month_key_v AS month_key, 
		area_code, 
		COALESCE(avg_principal_aft_wo / sum(avg_principal_aft_wo) OVER(),0)::NUMERIC AS rate,
		4 AS rule_id
FROM
	--y: average ending balance
	(
	SELECT
		month_key_v AS month_key, 
		COALESCE(avg(principal_aft_wo),0) AS avg_principal_aft_wo,
		area_code
	FROM
		--x: total cumulative principal in month_key_v	
			(
		SELECT
			kpi_month,
			area_code, 
			sum(outstanding_principal) AS principal_aft_wo
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city			
		WHERE kpi_month BETWEEN start_month_key_v AND month_key_v			
		GROUP BY
			kpi_month,
			area_code)x
	GROUP BY area_code		
	)y
UNION ALL
--Rule 5: Average ending balance before write off(max_bucket:2,3,4,5) 
SELECT
	month_key_v AS kpi_month, 
	area_code, 
	COALESCE(avg(balance_bf_wo)/ sum(avg(balance_bf_wo)) OVER(),
	0):: NUMERIC AS rate,
	5 AS rule_id
FROM
	--z: total balance after wo
	(
	SELECT
		x.kpi_month, 
		x.area_code, 
		COALESCE(x.principal_aft_wo + y.wo_balance,
		0) AS balance_bf_wo
	FROM
		--x: cumulative outstading principal after wo (max_bucket:2,3,4,5)
		(
		SELECT
			kpi_month,
			area_code, 
			COALESCE(sum(outstanding_principal),0) AS principal_aft_wo
		FROM fact_kpi_month_balance f		
		JOIN dim_city d ON d.pos_city = f.pos_city			
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND max_bucket IN(2, 3, 4, 5)
		GROUP BY
			kpi_month,
			area_code)x
	JOIN
		(
		--y: write-off balance for kpi_month
		SELECT
			kpi_month, 
					area_code, 
					COALESCE(sum(write_off_balance_principal),0) AS wo_balance		
		FROM fact_kpi_month_balance f			
		JOIN dim_city d ON d.pos_city = f.pos_city		
		WHERE
			write_off_month BETWEEN start_month_key_v AND month_key_v
			AND kpi_month BETWEEN start_month_key_v AND month_key_v
		GROUP BY
			area_code,
			kpi_month)y
	ON
		x.kpi_month = y.kpi_month
		AND x.area_code = y.area_code)z
GROUP BY z.area_code
	
UNION ALL
--Rule 6: New customer Number
SELECT
	month_key_v AS month_key,
	y.area_code,
	COALESCE(avg(y.new_cus)/ sum(avg(y.new_cus)) OVER(),0) AS rate,
	6 AS rule_id
FROM
	(
	SELECT
		COALESCE(count(psdn),
		0) AS new_cus,
		d.area_code,
		kpi_month
	FROM fact_kpi_month_balance f			
	JOIN dim_city d ON d.pos_city = f.pos_city		
	WHERE kpi_month BETWEEN start_month_key_v AND month_key_v		
	GROUP BY
			d.area_code,
			f.kpi_month
	)y
GROUP BY y.area_code	
UNION ALL
--Rule 7: Percentage of ASM number 
SELECT
	month_key_v AS month_key, 
	x.area_code, 
	COALESCE(SUM(y.total_sm) / SUM(SUM(y.total_sm)) OVER (),0) AS rate,
	 7 AS rule_id
FROM
	(
	SELECT
		area_name,
		area_code
	FROM dim_city		
	GROUP BY
		area_name,
		area_code
	) x
JOIN
	(
	SELECT
		COUNT(1) AS total_sm,
		area_name
	FROM fact_kpi_asm			
	WHERE month_key = month_key_v			
	GROUP BY area_name			
	) y 
ON x.area_name = y.area_name			
GROUP BY x.area_code;		
--Step A2: Truncate table area_temp for total distributed values
TRUNCATE TABLE area_temp;
--Report_item_id 1: Profit Before Taxes
--Report_item_id 4: Total Operating Income
--Report_item_id 5: Total Operating Expense
--Report_item_id 6: Provision Expense
--Report_item_id 7: Income from card operations
--Report_item_id 8: Net cost of business capital
--Report_item_id 9: Net Income from Other Operations
--Report_item_id 10: Due Interest
--Report_item_id 11: Overdue interest 
--Report_item_id 12: Insurance fees 
--Report_item_id 13: Limit increase fees 
--Report_item_id 14: Late payment fees, Off-balance sheet income, and others. 
--Report_item_id 15: Capital revenue 
--Report_item_id 16: Market capital cost 2 
--Report_item_id 17: Market capital cost 1 
--Report_item_id 18: Cost of certificate of deposit 
--Report_item_id 19: Fintech revenue 
--Report_item_id 20: Retail & individual revenue 
--Report_item_id 21: Income from other operations 
--Report_item_id 22: Commission cost 
--Report_item_id 23: Net cost from other business operations 
--Report_item_id 24: Net cost from ship operations 
--Report_item_id 25: Tax expense 
--Report_item_id 26: Employee costs
--Report_item_id 27: Administrative expenses
--Report_item_id 28: Asset expenses
--Report_item_id 29: Human Resources (Sale Manager)
--Report_item_id 30: Financial Index
--Report_item_id 31: CIR (%)
--Report_item_id 32: Margin (%)
--Report_item_id 33: Profit-to-Captital Cost Ratio(%)
--Report_item_id 34: Profit per ASM

INSERT INTO area_temp 
	(month_key,
	report_item_id,
	area_code,
	area_amount)
--Report_item_id 10: Due interest
SELECT
		month_key_v, 
		10 AS report_item_id, 
		SUBSTRING(analysis_code, 9, 1) AS area_code, 
		sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (702000030002, 702000030001, 702000030102)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 11: Overdue interest
SELECT
	month_key_v, 
	11 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (702000030012, 702000030112)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 12: Insurance fees
SELECT
	month_key_v, 
	12 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code = 716000000001
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 13: Limit increase fees
SELECT
	month_key_v, 
	13 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code = 719000030002
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 14: Late payment fees, Off-balance sheet income, and others.
	SELECT
	month_key_v, 
			14 AS report_item_id, 
			SUBSTRING(analysis_code, 9, 1) AS area_code, 
			sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (719000030003, 719000030103, 790000030003, 790000030103, 790000030004, 790000030104)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 15: Capital revenue (default 0.00)
SELECT
	month_key_v, 
	15 AS report_item_id,
	area_code,
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
UNION ALL
--Report_item_id 16: Market capital cost 2
SELECT
	month_key_v,
	16 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (801000000001, 802000000001)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 16: Market capital cost 2 (except head office)
SELECT
	month_key_v,
	16 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	WHERE area_code != 'A' 
	) AS areas
UNION ALL
--Report_item_id 17: Market capital cost 1 (default 0.00)
SELECT
	month_key_v,
	17 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
UNION ALL
--Report_item_id 18: Cost of certificate of deposit
SELECT
	month_key_v, 
	18 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code = 803000000001
GROUP BY SUBSTRING(analysis_code, 9, 1)
--Report_item_id 18: Cost of certificate of deposit (except head office)
UNION ALL
SELECT
	month_key_v,
	18 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	WHERE area_code != 'A' 
	) AS areas
UNION ALL
--Report_item_id 19: Fintech revenue (default 0.00)
SELECT
	month_key_v, 
	19 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
--Report_item_id 20: Retail & individual revenue
UNION ALL
SELECT
	month_key_v, 
	20 AS report_item_id,
	area_code,
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
UNION ALL
--Report_item_id 21: Income from other operations
SELECT
	month_key_v, 
	21 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (702000010001, 702000010002, 704000000001, 705000000001, 709000000001, 714000000002,714000000003, 714037000001, 714000000004, 714014000001, 715000000001, 715037000001, 719000000001,709000000101, 719000000101)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 22: Commission cost
SELECT
	month_key_v, 
	22 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN ( 816000000001, 816000000002, 816000000003)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 23: Net cost from other business operations 
SELECT
	month_key_v, 
	23 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (809000000002, 809000000001, 811000000001, 811000000102, 811000000002, 811014000001, 811037000001,811039000001, 811041000001, 815000000001, 819000000002, 819000000003, 819000000001, 790000000003, 790000050101,790000000101, 790037000001, 849000000001, 899000000003, 899000000002, 811000000101, 819000060001)
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
---Report_item_id 24: Net cost from ship operations (default 0.00)
SELECT
	month_key_v, 
	24 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
UNION ALL
--Report_item_id 25: Tax expense 
SELECT
	month_key_v, 
	25 AS report_item_id,
	area_code, 
	0.00 AS area_amount
FROM 
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas
UNION ALL
--Report_item_id 26: Employee costs
SELECT
	month_key_v, 
	 26 AS report_item_id, 
	 SUBSTRING(analysis_code, 9, 1) AS area_code, 
	 sum(amount) AS area_amount
FROM
	fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code :: text LIKE '85%'
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 27: Administrative expenses
SELECT
	month_key_v, 
	27 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code :: text LIKE '86%'
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report_item_id 28: Asset expenses
SELECT
	month_key_v, 
	28 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date, 'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code :: text LIKE '87%'
GROUP BY SUBSTRING(analysis_code, 9, 1)
UNION ALL
--Report item 6: Provision Expense
SELECT
	month_key_v, 
	6 AS report_item_id, 
	SUBSTRING(analysis_code, 9, 1) AS area_code, 
	sum(amount) AS area_amount
FROM fact_txn_month_raw_data f
WHERE
	TO_CHAR(transaction_date,'YYYYMM')::int BETWEEN start_month_key_v AND month_key_v
	AND account_code IN (790000050001, 882200050001, 790000030001, 882200030001, 790000000001, 790000020101, 882200000001, 882200050101, 882200020101, 882200060001, 790000050101, 882200030101)
GROUP BY SUBSTRING(analysis_code, 9, 1);
--Update head office code from '0' to 'A'(dim_city: 'A', analysis code: '0')
UPDATE area_temp
SET area_code = 'A'
WHERE area_code = '0';
--Update distribution rate for each report_item_id in area_temp table
UPDATE area_temp
SET rate = x.rate
FROM
--Retrive rate from rule_temp 
	(
	SELECT
		report_item_id ,
		area_code,
		rate
	FROM rule_temp r
	JOIN dim_report_item d ON d.rule_id = r.rule_id
	)x
WHERE
	x.report_item_id = area_temp.report_item_id
	AND x.area_code = area_temp.area_code;
--Update total distributed amount including amount from head office
UPDATE area_temp
SET total_amount = z.total_amount
FROM
	(
	SELECT
		x.area_code,
		x.report_item_id,
		x.area_amount + COALESCE(x.rate,0)* y.area_amount AS total_amount
	FROM area_temp x
	JOIN area_temp y ON 
		y.area_code = 'A'
		AND x.report_item_id = y.report_item_id 
	) z
WHERE
	area_temp.report_item_id = z.report_item_id
	AND area_temp.area_code = z.area_code;
--Step A3: Insert results from area_temp to Target table fact_summary_area
--Aggregation by item_parent
INSERT INTO fact_summary_area 
	(month_key,
	report_item_id,
	area_code,
	total_amount)
SELECT
	month_key_v,
	report_item_id,
	area_code,
	total_amount
FROM area_temp
UNION ALL
--Report_item_id 7:  Income from card operations
SELECT
	month_key_v AS month_key, 
	7 AS report_item_id, 
	a.area_code, 
	sum(a.total_amount)
FROM area_temp a
JOIN dim_report_item d ON d.report_item_id = a.report_item_id
WHERE d.item_parent = 7
GROUP BY a.area_code
UNION ALL
--Report_item_id 8:  Net cost of business capital	
SELECT
	month_key_v AS month_key, 
	8 AS report_item_id, 
	a.area_code, 
	sum(a.total_amount)
FROM area_temp a
JOIN dim_report_item d ON d.report_item_id = a.report_item_id
WHERE d.item_parent = 8
GROUP BY a.area_code
UNION ALL
--Report_item_id 9:   Net Income from Other Operations
SELECT
	month_key_v AS month_key, 
	9 AS report_item_id, 
	a.area_code, 
	sum(a.total_amount)
FROM area_temp a
JOIN dim_report_item d ON d.report_item_id = a.report_item_id
WHERE d.item_parent = 9
GROUP BY a.area_code;
INSERT INTO fact_summary_area 
	(month_key,
	report_item_id,
	area_code,
	total_amount)
--Report_item_id 4: Total Operating Income
SELECT
	month_key_v AS month_key, 
	4 AS report_item_id, 
	f.area_code, 
	sum(f.total_amount)
FROM fact_summary_area f
JOIN dim_report_item d ON d.report_item_id = f.report_item_id
WHERE
	d.item_parent = 4
	AND month_key = month_key_V
GROUP BY f.area_code
UNION ALL
--Report_item_id 5: Total Operating Expense
SELECT
	month_key_v AS month_key, 
	5 AS report_item_id, 
	a.area_code, 
	sum(a.total_amount)
FROM area_temp a
JOIN dim_report_item d ON d.report_item_id = a.report_item_id
WHERE d.item_parent = 5
GROUP BY a.area_code;
--Report_item_id 1: Profit Before Taxes
INSERT INTO fact_summary_area 
	(month_key,
	report_item_id,
	area_code,
	total_amount)
SELECT
	month_key_v AS month_key, 
	1 AS report_item_id, 
	f.area_code, 
	sum(f.total_amount)
FROM fact_summary_area f
JOIN dim_report_item d ON d.report_item_id = f.report_item_id
WHERE
	d.item_parent = 1
	AND month_key = month_key_v
GROUP BY f.area_code
UNION ALL
--Report_item_id  29: Area Sales Manager number
SELECT
	month_key_v, 
	29 AS report_item_id, 
	x.area_code, 
	count(email)
FROM fact_kpi_asm f
JOIN 
	(
	SELECT
		area_name,
		area_code
	FROM dim_city
	GROUP BY
		area_name,
		area_code
	)x 
ON x.area_name = f.area_name
WHERE month_key = month_key_v
GROUP BY x.area_code
UNION ALL 
SELECT
	month_key_v,
	29 AS report_item_id, 
	'A' AS area_code, 
	count(email)
FROM fact_kpi_asm f
WHERE month_key = month_key_v
UNION ALL
--Report_item_id 30: Financial index	
SELECT
	month_key_v, 
	30 AS report_item_id ,
	area_code, 
	0.00 AS area_amount
FROM
	(
	SELECT DISTINCT area_code
	FROM dim_city
	) AS areas ;
--Report_item_id 31 :CIR (%)
INSERT INTO
	fact_summary_area 
	(month_key,
	report_item_id,
	area_code,
	total_amount)	
SELECT
	x.month_key, 
	31 AS report_item_id,
	x.area_code, 
	COALESCE(abs(y.total_amount)* 100 / x.total_amount, 0)::NUMERIC AS total_amount
FROM 
	(
	SELECT
		month_key, 
		area_code, 
		total_amount
	FROM fact_summary_area f
	WHERE
		report_item_id = 4
		AND month_key = month_key_v
	)x
JOIN 
	(
	SELECT
		month_key, 
		area_code, 
		total_amount
	FROM fact_summary_area f
	WHERE 
		report_item_id = 5
		AND month_key = month_key_v
	)y ON x.area_code = y.area_code
		AND x.month_key = y.month_key
UNION ALL
--Report_item_id 32: Margin (%)
SELECT
	x.month_key, 
	32 AS report_item_id,
	x.area_code, 
	COALESCE(x.amount * 100 / y.amount,0):: NUMERIC AS margin
FROM
	(
	SELECT
		month_key_v AS month_key, 
		32 AS report_item_id, 
		f.area_code, 
		sum(total_amount) AS amount
	FROM fact_summary_area f
	WHERE
		report_item_id = 1
		AND month_key = month_key_v
	GROUP BY f.area_code
	)x
JOIN
	(
	SELECT
		month_key_v AS month_key, 
		32 AS report_item_id,
		f.area_code, 
		sum(total_amount)AS amount
	FROM fact_summary_area f
	WHERE
		report_item_id IN (7, 15, 19, 20, 21)
		AND month_key = month_key_v
	GROUP BY f.area_code
	)y ON x.area_code = y.area_code
		AND x.month_key = y.month_key
UNION ALL
--Report_item_id 33: Profit-to-Capital Cost (%)
SELECT
	x.month_key, 
	33 AS report_item_id,
	x.area_code, 
	COALESCE(x.total_amount * 100 / abs(y.total_amount),0)::NUMERIC AS total_amount
FROM 
	(
	SELECT
		month_key_v AS month_key,
		area_code, 
		total_amount
	FROM fact_summary_area
	WHERE
		report_item_id = 1
		AND month_key = month_key_v
	)x
JOIN 
	(
	SELECT
		month_key_v AS month_key, 
		area_code, 
		total_amount
	FROM fact_summary_area
	WHERE
		report_item_id = 8
		AND month_key = month_key_v
	)y ON x.area_code = y.area_code
		AND x.month_key = y.month_key
UNION ALL
--Report_item_id 34: Proit per Area Sales Manager
SELECT
	month_key_v, 
	34 AS report_item_id, 
	x.area_code, 
	COALESCE(y.total_amount / x.total_amount, 0)::NUMERIC AS total_amount
FROM 
	(
	SELECT
		month_key, 
		area_code, 
		total_amount
	FROM fact_summary_area f
	WHERE
		report_item_id = 29
		AND month_key = month_key_v
	)x
JOIN 
	(
	SELECT
		month_key, 
		area_code, 
		total_amount
	FROM fact_summary_area fsa
	WHERE
		report_item_id = 1
		AND month_key = month_key_v 
	)y ON x.area_code = y.area_code
		AND x.month_key = y.month_key;
--------------SECTION B: TABLE TARGET fact_avg_asm--------------
--Step B1: Delete the record with monthkey input
DELETE FROM fact_avg_asm
WHERE month_key = month_key_v;
--Step B.2: Insert values to npl_before_wo, rate_npl
--Calculate rate of accumulated non-performance-loan before write-off in total accumulated oustading balance
TRUNCATE TABLE npl_before_wo;
INSERT INTO npl_before_wo 
	(month_key,
	area_code,
	area_name,
	accumulated_balance_before_wo,
	accumulated_npl_before_wo)
SELECT
	w.kpi_month, 
	w.area_code,
	w.area_name, 
	z.balance + w.accumulated_wo AS accumulated_balance_before_wo,
	z.npl + w.accumulated_wo AS accumulated_npl_before_wo
FROM
	--w: self join from table x: calculate accumulated wo
		(	
	SELECT
		x.kpi_month, 
		x.area_code, 
		x.area_name,
		sum(y.wo) AS accumulated_wo
	--x: total write-off amount (group by month, area)
	FROM 
		(	
		SELECT
			kpi_month, 
			d.area_code,
			d.area_name ,
			sum(write_off_balance_principal) AS wo
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND write_off_month BETWEEN start_month_key_v AND month_key_v
		GROUP BY
			d.area_code,
			kpi_month,
			d.area_name 
		)x
	JOIN
	--y=x: total write-off amount (group by month, area)
		(
		SELECT
			kpi_month,
			d.area_code,
			SUM(write_off_balance_principal) AS wo
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND write_off_month BETWEEN start_month_key_v AND month_key_v
		GROUP BY
			d.area_code,
			kpi_month
		)y ON
		x. kpi_month >= y.kpi_month
		AND x.area_code = y.area_code
	GROUP BY
		x.kpi_month,
		x.area_code,
		x.area_name
		)w
JOIN 
	--z: by joining table a and table b for npl and total balance (group by month, area)
		(	
	SELECT
		a.balance, 
		b.npl, 
		a.area_code, 
		a.kpi_month
	FROM 
		(
		--a: total outstanding princial (group by month, area)
		SELECT
			kpi_month, 
			d.area_code, 
			sum(outstanding_principal) AS balance
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE kpi_month BETWEEN start_month_key_v AND month_key_v
		GROUP BY
			d.area_code,
			kpi_month
			)a
	JOIN 
			(
		--b: total non-performance loan (group by month, area)
		SELECT
			kpi_month, 
			d.area_code, 
			sum(outstanding_principal) AS npl
		FROM fact_kpi_month_balance f
		JOIN dim_city d ON d.pos_city = f.pos_city
		WHERE
			kpi_month BETWEEN start_month_key_v AND month_key_v
			AND max_bucket IN (3, 4, 5)
		GROUP BY
			d.area_code,
			kpi_month
			)b ON a. kpi_month = b.kpi_month AND a.area_code = b.area_Code
	GROUP BY
		a.kpi_month,
		a.area_code,
		a.balance,
		b.npl
		)z ON z.kpi_month = w.kpi_month AND z.area_code = w.area_code;
TRUNCATE TABLE rate_npl;

INSERT INTO rate_npl 
	(month_key,
	area_code,
	area_name,
	accumulated_npl_before_wo)
SELECT
	month_key_v AS month_key,
	area_code, 
	area_name,
	COALESCE(avg(accumulated_npl_before_wo)* 100 / avg(accumulated_balance_before_wo)::NUMERIC,0) AS accumulated_npl_before_wo
FROM 
	(
	SELECT
		month_key, 
		area_code, 
		area_name, 
		accumulated_balance_before_wo, 
		accumulated_npl_before_wo
	FROM npl_before_wo
	)
GROUP BY
	area_code,
	area_name;
--Step B3: Insert values to target table fact_avg_asm
INSERT INTO fact_avg_asm
	(month_key ,
	area_code,
	area_name,
	email,
	total_point,
	rank_final,
	ltn_avg,
	rank_ltn_avg,
	psdn_avg,
	rank_psdn_avg,
	approval_rate_avg,
	rank_approval_rate_avg, 
	accumulated_npl_before_wo,
	rank_npl,
	scale_point,
	rank_sale,
	cir,
	rank_cir,
	margin,
	rank_margin,
	roc,
	rank_roc,
	avg_performance_employee,
	rank_employee_performance,
	fin_point,
	rank_fin)
SELECT
	month_key ,
	area_code,
	area_name,
	email,
	rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl + rank_cir + rank_margin + rank_roc + rank_employee_performance AS total_point,		
	RANK () OVER( ORDER BY rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl + rank_cir + rank_margin + rank_roc + rank_employee_performance ASC) AS rank_final,
	ltn_avg, 
	rank_ltn_avg, 
	psdn_avg, 
	rank_psdn_avg,
	approval_rate_avg, 
	rank_approval_rate_avg,
	accumulated_npl_before_wo, 
	rank_npl,
	rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl AS scale_point,
	RANK() OVER(ORDER BY rank_ltn_avg + rank_psdn_avg + rank_approval_rate_avg + rank_npl ASC) AS rank_sale,
	cir, 
	rank_cir, 
	margin, 
	rank_margin, 
	roc, 
	rank_roc,
	avg_performance_employee, 
	rank_employee_performance,
	rank_cir + rank_margin + rank_roc + rank_employee_performance AS fin_point,
	RANK() OVER (
ORDER BY rank_cir + rank_margin + rank_roc + rank_employee_performance ASC) AS rank_fin
FROM
	(
	--s: get the above info from fact_summary_area to rank
	SELECT
		z.month_key,
		r.area_code,
		z.area_name,
		z.email,
		z.ltn_avg, 
		RANK () OVER( ORDER BY z.ltn_avg DESC) AS rank_ltn_avg, z.psdn_avg, 
		RANK () OVER( ORDER BY z.psdn_avg DESC) AS rank_psdn_avg, z.approval_rate_avg, 
		RANK () OVER( ORDER BY z.approval_rate_avg DESC) AS rank_approval_rate_avg,
		r.accumulated_npl_before_wo AS accumulated_npl_before_wo, 
		RANK () OVER( ORDER BY r.accumulated_npl_before_wo ASC) AS rank_npl,
		a.total_amount AS cir, 
		DENSE_RANK () OVER( ORDER BY a.total_amount ASC) AS rank_cir,
		b.total_amount AS margin,
		DENSE_RANK () OVER( ORDER BY b.total_amount DESC) AS rank_margin,
		c.total_amount AS roc,
		DENSE_RANK () OVER( ORDER BY
		c.total_amount DESC) AS rank_roc,
		d.total_amount AS avg_performance_employee ,
		DENSE_RANK () OVER( ORDER BY d.total_amount DESC) AS rank_employee_performance
	FROM
		(
		-- z: average values of ltn, psdn, approval_rate 
		SELECT
			month_key_v AS month_key ,
			email,
			area_name, 
			COALESCE(avg(ltn),0) AS ltn_avg, 
			COALESCE(avg(psdn),0) AS psdn_avg,
			COALESCE(avg(approval_rate),0) AS approval_rate_avg
		FROM fact_kpi_asm f
		WHERE month_key BETWEEN start_month_key_v AND month_key_v
		GROUP BY email, area_name
		)z
	LEFT JOIN rate_npl r ON
		z.area_name = r.area_name
		AND z.month_key = r.month_key
	LEFT JOIN fact_summary_area a ON
		a.area_code = r.area_code
		AND a.month_key = r.month_key
		AND a.report_item_id = 31
	LEFT JOIN fact_summary_area b ON
		b.area_code = r.area_code
		AND b.month_key = r.month_key
		AND b.report_item_id = 32
	LEFT JOIN fact_summary_area c ON
		c.area_code = r.area_code
		AND c.month_key = r.month_key
		AND c.report_item_id = 33
	LEFT JOIN fact_summary_area d ON
		d.area_code = r.area_code
		AND d.month_key = r.month_key
		AND d.report_item_id = 34
	WHERE z.month_key = month_key_v
	)s;
-----------------------------------------------------------------	
--3. Handle the exception: Table log_tracking
INSERT INTO log_tracking (procedure_name, start_time , end_time, is_successful, rec_created_dt)
VALUES ('fact_summary_area', vstart_time , CURRENT_TIMESTAMP, TRUE, vProcess_dt);
-- Record Errors
EXCEPTION
WHEN others THEN
    INSERT INTO log_tracking (procedure_name, start_time, end_time, is_successful, error_log, rec_created_dt)
    VALUES ('fact_summary_area', vstart_time, CURRENT_TIMESTAMP, FALSE, SQLERRM, CURRENT_TIMESTAMP);
	RAISE EXCEPTION 'Error';
END $$;
CALL back_date_report (202302);
CALL back_date_report (202301);
CALL back_date_report (202303);
CALL back_date_report (202304);
CALL back_date_report (202305);
SELECT * FROM fact_summary_area;
SELECT * FROM fact_avg_asm;
SELECT * FROM log_tracking;

