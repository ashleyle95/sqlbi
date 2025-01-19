![Example Image](https://github.com/ashleyle95/sqlbi/blob/main/cover.jpg)
# PROJECT: FINANCIAL GROWTH ASSESSMENT AND AREA SALES MANAGER (ASM) KPI                                                         

## Project Links
[Project Description](https://github.com/ashleyle95/sqlbi/blob/main/Project%20Description.xlsx)

[SQL Script]()
[1. DDL](https://github.com/ashleyle95/sqlbi/blob/main/Procedure.sql)
[2. Procedure](https://github.com/ashleyle95/sqlbi/blob/main/Table%20vs%20DDL%20.sql)

[Measures - PowerBI (Notion Link)](https://merciful-pangolin-17c.notion.site/PROJECT-FINANCIAL-GROWTH-ASSESSMENT-AND-ASM-KPI-176ced2366e780f6ad34fe193e4dd6f2)

[Link report - Power BI service](https://app.powerbi.com/view?r=eyJrIjoiM2IwMzI3ZmQtNzc3NS00M2U5LTg5MWYtZDJmZmFlNDI5ZWJiIiwidCI6IjA2N2UxZTE5LWExMWEtNDhlNS04Yjc5LTBiOWVlNzQ1YTdhMiJ9)

## Table of contents
[1. Project Overview](#1-project-overview)

[2. Data Process](#2-data-process) 

[3. Reporting/Visualization](#3-reporting-visualization)

[4. Findings/Recommendations](#4-findingsrecommendations)

[5. Limitation](#5-limitations)

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

![image](https://github.com/user-attachments/assets/59bee737-9e1f-4277-adc2-9611b3ddc333)



  
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

[Embedded Demo in Power BI service](https://app.powerbi.com/view?r=eyJrIjoiM2IwMzI3ZmQtNzc3NS00M2U5LTg5MWYtZDJmZmFlNDI5ZWJiIiwidCI6IjA2N2UxZTE5LWExMWEtNDhlNS04Yjc5LTBiOWVlNzQ1YTdhMiJ9)

[Measure Power BI](https://merciful-pangolin-17c.notion.site/PROJECT-FINANCIAL-GROWTH-ASSESSMENT-AND-ASM-KPI-176ced2366e780f6ad34fe193e4dd6f2)

**`Page Home`** *A brief recap of the project’s context, objectives, and essential information for the user*

![image](https://github.com/user-attachments/assets/f316022a-c9a4-410d-bb1e-56fac178c9f8)




**`Page Executive Summary`** *Highlight key finnacial metris and overview of operational performance*

Cumulative net profit in the latest month is 250 billions and Average margin from 10-12% during that perriod.

While there is a slight decrease in growth rate compared to previous month, growth rate of margin increase 3-5%. It shows a good sign of profitability

Provision expenses account for the highest percentage of total expenses, indicating that the company is prioritizing risk management. Tasmania is the region with the highest income, while South Australia has the highest expenses. For further analysis, we can delegate this to regional performance to provide more precise insights

![image](https://github.com/user-attachments/assets/fde5aa2b-8675-4e0d-93d0-6f557231b2b0)


**`Page Financial Performance`** *Emphasize the efficiency of business performance across months and classify areas based on the growth rate of key business metrics*

Due interest is the category that accounts for the highest percentage of total operating income. 

February is the month with the highest growth rate in net profit and income. Except for February, we observe that the growth rates of net profit, provision expenses, and due interest increase at the same rate. 
From February to May, we experienced a significant decline in the growth rates of profit, due interest, and provision expenses. The average margin remained stable following a significant decline of 18%

![image](https://github.com/user-attachments/assets/1aef9504-e990-4fc7-8401-9750507d9cc8)


**`Page Regional Performance`** *Emphasize the efficiency of business performance across months and classify areas based on the growth rate of key business metrics*

In the latest month, the areas with the highest growth rates in profit and income are Tasmania, while the areas with the lowest growth rates in profit and income are New South Wales, Victoria, and South Australia. 
Tasmania is the area that has shown strong growth in both net profit and income. Additionally, South Australia had the highest CIR, and therefore, it needs to implement appropriate cost management. 
Although Northern Territory generates good income, its margins are not strong enough to achieve a higher net profit growth rate


![image](https://github.com/user-attachments/assets/d4d359e2-3510-4579-8201-289e08201fcb)

**`Page Regional Performance`**  *Analyze the performance of the Area Sales Manager based on two key business activities: Loan-to-New and New Customer Analysis*

This analysis based on the Pareto Principle to answer the key question: What does 80% loan-to-new or customer come from?

80% of loans to new customers were provided by 50 ASMs, accounting for over 60% of the total ASMs, while 80% of new customers were served by 52 ASMs, representing more than half of the total. The trends are consistent across both analyses.

Therefore, we can develop a strategic approach for determining the optimal number of ASMs to align with the project objectives and budget, while also evaluating the capabilities of the ASMs.

![image](https://github.com/user-attachments/assets/a36130b8-0883-4226-8eee-e6668b13ceef)

![image](https://github.com/user-attachments/assets/fe03f078-3813-4c56-876d-05e02ea7cb09)

We can switch visual by this button.
![image](https://github.com/user-attachments/assets/390196bf-cb2c-4385-b4f3-c33268e9d7f3)


**`Page ASM Report`** *Provide a detailed report ranking Area Sales Managers for all criteria and highlight the increase or decrease in ranking for each ASM*

During that period, region always having highest ASM in Top 10 : ﻿Queensland﻿ 

In the latest month, the number of ASM having decreasing ranking accounts for highest percentage (~58%) 

  Region with the highest ASM number with increasing ranking: ﻿Queensland﻿

  Region with the lowest ASM number with  increasing ranking

﻿New South Wales﻿


![image](https://github.com/user-attachments/assets/1d5dd8ea-808b-4553-b255-befdc21e886b)


## Findings/Recommendations

*Provision Expense Impact:* 

Provision expense accounts for the highest percentage of total expenses, which results in a reduced recorded net profit, thereby not truly reflecting the company’s performance. It is essential to assess other operational aspects of the company and evaluate the relative importance of provision expenses. A strategic approach should be taken in setting the budget for this expense category to ensure it accurately aligns with operational goals.

*Areas for Cost Management Focus:* 

Certain regions should place greater emphasis on cost management to enhance their net profit:

Northern Territory (NT): The Northern Territory should focus on high-margin products, as they have demonstrated the ability to generate substantial income; however, their net profit remains negative. The ASM report indicates that most ASMs in NT rank below 60. To improve, they must enhance performance in the areas of loan-to-new and new customer acquisition.

Queensland: Queensland shows strong profit margins and efficient ASM performance. It demonstrates sound financial health.

Tasmania: Tasmania displays a good profit margin; however, the ASM performance needs improvement. Strengthening ASM effectiveness will help boost overall business performance.

*Cost of Management*:

Based on Pareto analysis, the cost for ASM (Area Sales Manager) management is considered acceptable, as the majority of loan-to-new and new customer figures—over 60% of the total—are attributed to these managers. While this indicates a concentration of results, it does not necessarily suggest that reducing the number of ASMs will lead to higher profitability. Notably, 80% of the loans to new customers come from just 60% of the managers, highlighting that reducing the ASM count may not optimize profitability
## Limitation

**In SQL**

Some of the analysis code and business logic for calculation may not align with the standards set by the Australian Accounting Standards Board (AASB). Null values in the max_bucket column of the fact_kpi_month_raw_data table, which indicates the maximum loan classification of customers, will be coalesced to 1 for calculation purposes.

**In Power BI**

The Gauge Chart categorizes areas based on the minimum, maximum, and target values along the axis, which are initially set based on user intentions. In practice, these values will be determined by various factors such as the financial reports from previous periods, the current economic situation, competitors' performance, and the overall performance of the company.

In the Expense Category, we will focus primarily on the core sources of income and expenses, ensuring that the most critical financial drivers are clearly visible and prioritized.

💻📖😄

| [Table of Contents](#table-of-contents) | [Project Links](#project-links) |


![image](https://github.com/user-attachments/assets/71437a11-333e-4d7a-8073-ee6d54691298)


  
