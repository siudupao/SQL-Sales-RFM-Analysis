-- Inspect sales data
SELECT *
FROM SalesRFM.dbo.Sales_Data

-------------------- Section A: Data Cleaning and Inspection --------------------

--1. Inspect Columns and Values

SELECT DISTINCT(OrderNumber) 
FROM SalesRFM.dbo.Sales_Data
/* Each order has a distinct OrderNumber */ 

SELECT DISTINCT(Sales_Channel) 
FROM SalesRFM.dbo.Sales_Data
/* Sales_Channel needs cleaning */

UPDATE SalesRFM.dbo.Sales_Data
SET Sales_Channel = CASE WHEN Sales_Channel = 'Dis  _tributor' THEN 'Distributor'
	WHEN Sales_Channel = 'On line' THEN 'Online'
	WHEN Sales_Channel = 'Whole#_sale' THEN 'Wholesale'
	WHEN Sales_Channel = 'In___Store' THEN 'In-Store'
	ELSE Sales_Channel
	END
/* Categories in different names simplified under one */

SELECT DISTINCT(OrderDate) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* First order on 2018-05-31, last order on 2020-12-30*/
/* There is 'NULL' and distinct entry with year as '7683' */

SELECT *
FROM SalesRFM.dbo.Sales_Data
WHERE OrderDate is null or OrderDate like '7683%'
/* There are three 'NULL' and one entry with year as '7683' */


UPDATE SalesRFM.dbo.Sales_Data
SET OrderDate = CASE WHEN OrderNumber = 'SO - 000414' THEN '2018-07-08'
	WHEN OrderNumber = 'SO - 000668' THEN '2018-08-05'
	WHEN OrderNumber = 'SO - 0003750' THEN '2019-08-03'
	WHEN OrderNumber = 'SO - 0005230' THEN '2020-01-30'
	ELSE OrderDate
	END
/* Enter OrderDate based on OrderNumber */

SELECT DISTINCT(CustomerID) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* There are 50 Customers */

SELECT DISTINCT(Order_Quantity) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* Order_Quantity ranging from 1-8 */
/* There is 'NULL' and distinct entries with negative quantity */

SELECT *
FROM SalesRFM.dbo.Sales_Data
WHERE Order_Quantity is null or Order_Quantity < 0 
/* There are two 'NULL' and one -45 and one -8 */

UPDATE SalesRFM.dbo.Sales_Data
SET Order_Quantity = ( 
	SELECT AVG(Order_Quantity)
	FROM SalesRFM.dbo.Sales_Data
	WHERE CustomerID = 39 and ProductID = 9 and Order_Quantity is not null
		) 
WHERE OrderNumber = 'SO - 0004042' 
/* Impute first NULL Order_Quantity with average Order_Quantity based on Customer_ID and Product_ID */

UPDATE SalesRFM.dbo.Sales_Data
SET Order_Quantity = ( 
	SELECT AVG(Order_Quantity)
	FROM SalesRFM.dbo.Sales_Data
	WHERE CustomerID = 30 and ProductID = 27 and Order_Quantity is not null
		) 
WHERE OrderNumber = 'SO - 0005894' 
/* Impute second NULL Order_Quantity with average Order_Quantity based on Customer_ID and Product_ID */

UPDATE SalesRFM.dbo.Sales_Data
SET Order_Quantity = ABS(Order_Quantity)
WHERE Order_Quantity < 0
/* Assume Order_Quantity cannot be negative, no returns, convert to positive value */

SELECT DISTINCT(Discount_Applied) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* Discounts ranging from 5% to 40% */
/* There is 'NULL' entry */

SELECT *
FROM SalesRFM.dbo.Sales_Data
WHERE Discount_Applied is null
/* There are five 'NULL' */

UPDATE SalesRFM.dbo.Sales_Data
SET Discount_Applied = 0
WHERE Discount_Applied is null
/* Assume 'NULL' is from missing entry due to no discount applied, set Discount_Applied to 0 */

SELECT DISTINCT(Unit_Price) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* Unit_Price ranging from $167.5 to $6566 */

SELECT DISTINCT(Unit_Cost) FROM SalesRFM.dbo.Sales_Data ORDER BY 1
/* Unit_Cost ranging from $68.68 to $6498.56 */


-------------------- Section B: Exploring Sales Data --------------------

SELECT *
FROM SalesRFM.dbo.Sales_Data

--1. Create a Column for Revenue

ALTER TABLE SalesRFM.dbo.Sales_Data
ADD Revenue FLOAT

UPDATE SalesRFM.dbo.Sales_Data
SET Revenue = (Unit_Price*(1-Discount_Applied)*Order_Quantity)

--2. Explore Sales Data

SELECT DISTINCT(Revenue)
FROM SalesRFM.dbo.Sales_Data
ORDER BY 1
/* Transactions with sales as low as $100.50 to as high as $49697.92 */

--3. Sales by Sales Channel

SELECT Sales_Channel, SUM(Revenue) as Total_Revenue
FROM SalesRFM.dbo.Sales_Data
GROUP BY Sales_Channel
ORDER BY 2 DESC
/* In-Store sales generated the most revenue, followed by Online, Distributor and Wholesale */

--4. Sales by Year 

SELECT YEAR(OrderDate) as Year, SUM(Revenue) as Total_Revenue, COUNT(OrderNumber)
FROM SalesRFM.dbo.Sales_Data
GROUP BY YEAR(OrderDate)
ORDER BY 2 DESC 
/* Top sales generated in 2020, followed by 2019 and then 2018 */

--5. Top 5 Products Generating Most Revenue

SELECT TOP 5 ProductID, SUM(Revenue) as Total_Revenue 
FROM SalesRFM.dbo.Sales_Data
GROUP BY ProductID
ORDER BY 2 DESC

-------------------- Section C: RFM ANALYSIS --------------------

--1. Segmenting Customers Based on Past Purchase Behaviour

DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
	SELECT CustomerID,
		MAX(OrderDate) as last_order_date,
		(SELECT MAX(OrderDate) FROM SalesRFM.dbo.Sales_Data) as max_order_date,
		DATEDIFF(day, MAX(OrderDate), (SELECT MAX(OrderDate) FROM SalesRFM.dbo.Sales_Data)) as Recency,
		COUNT(OrderNumber) as Frequency,
		SUM(Revenue) as MonetaryValue
	FROM SalesRFM.dbo.Sales_Data 
	GROUP BY CustomerID
),
rfm_calc AS	
(
	SELECT rfm.*,
		NTILE(4) OVER (ORDER BY Recency) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency DESC) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue DESC) rfm_monetary
	FROM rfm 
)
SELECT rfm_calc.*,
	rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm_cell_string
INTO #rfm
FROM rfm_calc

SELECT CustomerID, rfm_recency, rfm_frequency, rfm_monetary, 
	CASE WHEN rfm_cell_string in (111, 112, 121, 122, 211, 212, 221, 222) then 'loyal big spenders'
	WHEN rfm_cell_string in (113, 114, 123, 124, 213, 214, 223, 224) then 'loyal small spenders'
	WHEN rfm_cell_string in (131, 132, 141, 142, 231, 232, 241, 242) then 'new big spenders'
	WHEN rfm_cell_string in (133, 134, 143, 144, 233, 234, 243, 244) then 'new small spenders'
	WHEN rfm_cell_string in (311, 312, 321, 322, 411, 412, 421, 422) then 'slipping big spenders' 
	WHEN rfm_cell_string in (313, 314, 323, 324, 413, 414, 423, 424) then 'slipping small spenders'
	WHEN rfm_cell_string in (331, 332, 341, 342, 431, 432, 441, 442) then 'lost big spenders'
	WHEN rfm_cell_string in (333, 334, 343, 344, 433, 434, 443, 444) then 'lost small spenders'
	END rfm_segment
FROM #rfm