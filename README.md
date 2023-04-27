# SQL-Sales-RFM-Analysis

Project Overview
-- 
In this project, I focus on a data-driven customer behaviour technique called RFM Analysis. The segmentation is performed based on customer's last purchase date (Recency), how often customers have purchased in the past (Frequency) and how much they have spent so far (Monetary). This method of segmentation allows companies/marketing teams to perform targeted marketing campaigns and craft more personalised messages, thereby increasing business performance. 

Dataset
--
The dataset used for this project is called US Regional Sales Data obtained from [data.world](https://data.world/dataman-udit/us-regional-sales-data). The dataset is ficticious and contains sales data for a certain company across the US regions from 2018-05-31 to 2020-12-31. Attached in this repo is the xlsx data file. 


Structure
--
The project is divided into three sections.

Section A - Data Cleaning
Before jumping right into the analysis, I inspected the data to ensure that the data was correct, consistent and usable. 
- Normalized Sales_Channel column (ie. converted 'Whole#_sale' to 'Wholesale') 
- Populated NULL OrderDate
- Corrected incorrect OrderDate (entry with year as '7683')
- Populated NULL Order_Quantity 
- Corrected negative Order_Quantity
- Populated NULL Discount_Applied 

Section B - Data Exploring
Conducted a quick exploration of the data. 
- Created a new Revenue column for easier analysis
- Explored Sales Data by Sales_Channel and Year
- Explored Top 5 products generating the most revenue

Section C - RFM Analysis 
Performed RFM Analysis using CTEs and Temp Tables
- Calculated the three measures: Recency, Frequency and Monetary Value
- Segmented clients into quartiles/buckets according to their RFM measures
- Concatenated the each RFM score into a string
- Segmented clients into categories based on their RFM score string (ie. 'loyal big spenders', 'slipping big spenders')

