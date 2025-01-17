![Example Image](https://github.com/ashleyle95/sqlbi/blob/main/cover.jpg)
# PROJECT: FINANCIAL GROWTH ASSESSMENT AND AREA SALES MANAGER (ASM) KPI                                                         
[Project Description](https://github.com/ashleyle95/sqlbi/blob/main/Project%20Description.xlsx)

[SQL Script]()
[1. DDL](https://github.com/ashleyle95/sqlbi/blob/main/Procedure.sql)
[2. Procedure](https://github.com/ashleyle95/sqlbi/blob/main/Table%20vs%20DDL%20.sql)

[Measures - PowerBI (Notion Link)](https://merciful-pangolin-17c.notion.site/PROJECT-FINANCIAL-GROWTH-ASSESSMENT-AND-ASM-KPI-176ced2366e780f6ad34fe193e4dd6f2)

[Link report - Power BI service](https://app.powerbi.com/links/3NWH4mM3Vg?ctid=067e1e19-a11a-48e5-8b79-0b9ee745a7a2&pbi_source=linkShare)

## Table of contents
[1. Project Overview](#1-project-overview)

[2. Data Process](#2-data-process) 

[3. Reporting/Visualization](#3-reporting-visualization)

## 1. Project Overview

### Context
An Australian financial company, A , has been operating in different cities across seven regions (states).  Each of these regions plays a crucial role in supporting the company’s comprehensive business strategy. 

The company's business operations  are managed by area sales managers (ASM). These ASMs are key decision-makers responsible for driving business growth and focusing on two critial business acitivties including Loan-to-New Management and Customer Growth and Retention

Note: In this context, the General Ledger may not align with the standards issued by the Australian Accounting Standards Board (AASB).
### Objective
This data analysis aim to provide insights to support the Board of Director (BOD) to have the clear overview of Year-to-Date business performance and its nationwide area network and highlight the key strengths in operational performance to enhance efficiency across the network. 

Moreover, it also helps us assess the capabilities of personnel in each region through Area Sales Managers (ASM) to foster a culture of accountability and continuous development among ASMs. By analyzing various aspects of financial performance across all network areas and ASM KPIs, we can gain insights to sustain performance and improve the capacity of senior managers within the company
### Data Sources
Data is collected from various departments at the head office, including Sales and Operations, the Accounting department, and ASM records
  File `fact_txn_month_raw_data`:  Record incurred income and costs of a business's financial performance in General Ledge
  
  File `fact_kpi_month_raw_data`: Record  ending balance of card operations at the end of every month.
  
  File `fact_kpi_asm`: raw data of monthly sales performance of ASM	  
### Exploratory Data Analysis (EDA)
EDA is involved in evaluating financial performance, regional performance, and ASM KPI metrics to answer key questions:

*Financial performance*
- What are the key trends in revenue, profit, and expenses throughout the period?
- How have the key financial indicators evolved during this period?
- What are the main drivers contributing to income category?
- Are there any observable seasonal fluctuations or peak periods that impact financial performance?

*Regional Performance*
- Which region is demonstrating superior operational efficiency and consistent performance?
- Which region is experiencing challenges and in need of targeted improvements in operational performance?
- What is the growth rate of financial index during that period?
- Which regions are facing significant underperformance in critical operational and financial metrics?

*ASM KPI*
-  What is the relationship between the number of ASMs and two key activities: Loan-to-New and New Customer Acquisition
- How has the ranking of ASMs evolved, and which ASMs have shown the most notable improvement?
- Which regions have the highest and lowest performing ASMs, and what factors contribute to these disparities?
## 2. Data Process  
### Tool
  - Data Processing: Dbeaver
    
  - Reporting/Visualisation: PowerBI

###  Flowchart
![flowchart (2)](https://github.com/user-attachments/assets/7725962a-8e89-4c97-872e-73b60dc70b41)

### Data Transformation
- Project Description and key aspects of Business Logic [View more](https://github.com/ashleyle95/sqlbi/blob/main/Project%20Description.xlsx)
- Use Dbeaver to import data to the database as below
   
   File `fact_txn_month_raw_data`
   
  ![image](https://github.com/user-attachments/assets/b4836274-dbd2-466d-86c9-7da8d221b6a5)

  
   File `fact_kpi_month_raw_data`
   
   ![image](https://github.com/user-attachments/assets/def2751b-a326-4bcb-8769-a8b6f01d0a81)


   File `fact_kpi_asm`

![image](https://github.com/user-attachments/assets/da8026a5-2b37-4c38-b9d8-195ba7385caf)

- Create dimension tables by using PostgreSQL Data Definition Language (DDL) [View more](https://github.com/ashleyle95/sqlbi/blob/main/Procedure.sql)

Table: `dim_asm`: Information of Area Sales Managers of all areas
![image](https://github.com/user-attachments/assets/22315f77-ecfb-44bd-bff6-0797e1ca56ee)

Table `dim_city`: Information of cities or surburbs in each area
![image](https://github.com/user-attachments/assets/46bf1508-4bc0-4953-88e7-8e2081bdcfbe)

Table `dim_report_item`: Report items in the report (key financial indexes in financial statement)
![image](https://github.com/user-attachments/assets/5597b920-ced0-4e59-9758-11258def4e9f)

- Create transformation table for complex business logic [View more](https://github.com/ashleyle95/sqlbi/blob/main/Procedure.sql)*

Table`rule_temp`: The distribution rates of the head office's values, which are applied to report items, are based on specific report_item_id
![image](https://github.com/user-attachments/assets/5ecd8a24-8fe1-498d-bf2d-1313806d35ef)

Table`area_temp`: The total value before and after adding the head office's value, which is applied to report items.

![image](https://github.com/user-attachments/assets/d4a6cfe5-03fe-4501-bffd-d0a742b8b94b)

Tale `npl_before_wo` and table`rate_npl`: calculate rate of non-performance loan to rank ASM

![image](https://github.com/user-attachments/assets/70130e41-c762-4a8b-aec3-b79982127f97)


![image](https://github.com/user-attachments/assets/cb9418e3-4fc8-4344-a820-0299cd14aeb3)

Table `log_tracking`: record error messages for procedure of backdate reports
![image](https://github.com/user-attachments/assets/bbf3c863-764b-4d5b-a200-dc757dc19164)

- Use PLSQL Programming to create backdate report
  
      With the parameter YYYYMM, reports can be created using cumulative values from data sources and a created dimension table to automatically generate the report.
  
      Verify input and log errors if any occur.
  
      Optimize performance using indexes and partitions.
  
## 3. Reporting/Visualizaton 

[View details of Embede Demo in Power BI service](https://app.powerbi.com/links/3NWH4mM3Vg?ctid=067e1e19-a11a-48e5-8b79-0b9ee745a7a2&pbi_source=linkShare)

[Measure Power BI](https://merciful-pangolin-17c.notion.site/PROJECT-FINANCIAL-GROWTH-ASSESSMENT-AND-ASM-KPI-176ced2366e780f6ad34fe193e4dd6f2)
This file provides a summary and key highlights of the report, which contribute to the insights presented


















### Output:
1/ Executive Summary: Highlight some financial key metrics and summary of primary operational performance 

2/ Financial Performance: Provide a comprehensive overview of the performance across all area networks, focusing on growth rate compared to previous month

3/ Regional Performance: Emphasize the efficiency of business performance across months and classify areas based on the growth rate of key business metrics

4/ ASM Analysis: Analyze the performance of the Area Sales Manager based on two key business activities: Loan-to-New and New Customer Analysis

5/ ASM Report:  Provide a detailed report ranking Area Sales Managers for all criteria and highlight the increase or decrease in ranking for each ASM





### Results/Findings
The results of the analysis are summarized as below
1.
2.
3.

### Recommendation
Based on the analysis, we recommend the following actions

### Limitation
Hypothesis: Gauge Chart how to categorize area (min max target axis)
Not follow the general ledger in Australia
null values in fact_kpi is coalesce to 0
Expense will be returned to absolute value
In the chart of Power BI, we focus more on primary income and expense source in that

💻📖😄


|Heading1|Heading2|
|--------|--------|
|Content|Content2|
|SQL|PowerBI|





  
