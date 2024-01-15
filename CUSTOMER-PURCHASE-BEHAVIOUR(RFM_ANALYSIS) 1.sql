/*     Customer Segmentation:
Problem: How can we segment our customer base to better understand their behavior and needs?
Questions: Can you group customers based on their recency, frequency, and monetary value? What are
the different customer segments that emerge from the analysis?

Recency (R)
Definition: How recently a customer made a purchase or engaged with the business.
Tables required: Sales.SalesOrderHeader, salesOrderDetail.
Columns required:  CustomerID, and OrderDate 

1.	Customer ID or Unique Identifier: An identifier for each customer that allows me to link their recency,frequency, and monetary value 
    to their individual profiles.
2.	Date of Last Interaction: The date when the customer last interacted with your business, made a purchase, or engaged in any meaningful 
    activity. This will be used to calculate the recency score.
Once have these columns, the recency scores can be calculated based on the difference between the current date and the date of the last 
interaction for each customer.

A) table for question 1 containing all columns needed. created a temporary table  #RFM  by selecting specific
column from the salesoOrderheader and salesOrderDetail. which includes CustomerId,OrderDate,SalesOrderID,ProductID
OrderQty,UnitPrice,LineTotal for each sales */

SELECT 
    a.[CustomerID],
    a.[OrderDate],
    a.[SalesOrderID],
    b.[ProductID],
    b.[OrderQty],
    b.[UnitPrice],
    b.[LineTotal]
INTO #RFM
FROM [Sales].[SalesOrderHeader]a 
INNER JOIN [Sales].[SalesOrderDetail] b 
ON a.[SalesOrderID] = b.[SalesOrderID]

------------------------------------------------------------------------------------------
SELECT * FROM #RFM 
------------------------------------------------------------------------------------------

/*B) RECENCY:This code calculate the the differecnce in days btw the maxinum order date for each customers
and the specified date ('2015-01-01').It stores the customerID and date diff in a temp #numberofdays
The saleOrdertable is use to calc the max order date for each customer.the DATEDIFF compute the diff
in days btw the Maxorderdate and "2015-01-01".the resultare then store in temp table #numberofdays */

--declare today's date (Date of my analysis)
DECLARE @today_date AS DATE = '2015-01-01'

SELECT
  [CustomerID],
  DATEDIFF(day,MAX([Orderdate]),'2015-01-01')AS datedifference
INTO #numberofdays
FROM [Sales].[SalesOrderHeader]m
GROUP BY [CustomerID]
ORDER BY MAX([OrderDate])DESC

---------------------------------------------------------------------------------------
SELECT * FROM #numberofdays
---------------------------------------------------------------------------------------


/* C) FREQUENCY
Definition: How often a customer makes purchases or engages with your business.
Tables required: Sales.SalesOrderHeader
Columns required:  CustomerID, SalesorderID, and OrderDate 

1.	Customer ID or Unique Identifier: An identifier for each customer that allows you to link their recency, frequency, and monetary value to their individual profiles.
2.	Transaction/Purchase ID: An identifier for each transaction or purchase made by the customer.
3.	Date of Transaction/Purchase: The date when each transaction or purchase was made. This will be used to calculate the frequency score.

Once i have these columns,i calculated the frequency score based on the number of transactions or purchases made by each customer within a specified time frame.

This SQL code calculate the purchase frequency(SumofPurchaseCount)for each customerby counting the number of sales ordersthey made 
btw '2013-01-01' and '2015-01-01'.the result are grouped by customer and the total purchase frequency is obtained for each customer, ordered in desc orderbased on the total purchase freq.
The COUNTFRQ common Table Expression(CTE) calculates the purchase freq for each customer based on their
distinct sale within a specified date range. the final SELECT statement aggregates the purchase freq for each 
customer, stores result in #SUMFRQ temp table, ordered it by total purchase freqin DESC order */

;WITH countfrq
AS
(
SELECT
    [CustomerID],
    [OrderDate],
    COUNT([SalesOrderID]) AS Purchase_Frequency
FROM
    [Sales].[SalesOrderHeader]
WHERE [OrderDate] BETWEEN '2013-01-01'AND '2015-01-01'
GROUP BY [CustomerID],[OrderDate]
)
SELECT
    [CustomerID],
    SUM(purchase_frequency) AS Sumofpurchasecount
INTO #SumFrq
FROM countfrq
GROUP BY [CustomerID]
ORDER BY Sumofpurchasecount DESC
--------------------------------------------------------------------------------
SELECT * FROM #SumFrq
--------------------------------------------------------------------------------

/*D)  Monetary Value (M):
Definition: The amount of money a customer has spent on purchases.
Tables required: Sales.SalesOrderHeader & Sales.SalesOrderDetail
Columns required: CustomerID, SalesOrderID, OrderDate, OrderQty, and Unit price

1.	Customer ID or Unique Identifier: An identifier for each customer that allows you to link their recency, frequency, and monetary value to their individual profiles.
2.	Transaction/Purchase ID: An identifier for each transaction or purchase made by the customer.
3.	Amount Spent: The monetary value associated with each transaction or purchase made by the customer. This could be the total amount spent in that transaction.
Once you have these columns, you can calculate the monetary value score based on the total amount spent by each customer over a specified time frame or for their entire history as relevant to your analysis.

This code calculate the total amount spent (total_spent) by each customer within the date of
January 1,2015, by multiplying orderquantity(ORDERQty)with the unit price (UnitPrice).The result are grouped by customeID 
and stored in a temp table named #totalamtspent */

SELECT
    [CustomerID],
    SUM([OrderQty] * [UnitPrice]) total_spent
INTO #totalamtspent
FROM #RFM
WHERE [OrderDate] BETWEEN '2013-01-01' AND '2015-01-01'
GROUP BY[CustomerID]
ORDER BY [CustomerID] DESC 
-------------------------------------------------------------------------------
SELECT * FROM #totalamtspent
-------------------------------------------------------------------------------

/* E) SQL ode calculates RFM(Recency, Frequency, Monetry Value) scores and corresponding segment for each customer.it begins
by calculating recency scores(RecencyScore) based on date differences.it then determin frequncy score (FrequencyScore)based  
on the purchase counts and monetary spending score (monetaryspendingscore) based on total spending.The final SELECT statement,
combines and displays these scores, segmentsand relevant customer information, ordered by recency score inascending order */
--WITH Recency1
--AS

    SELECT [CustomerID], 
           datedifference,
    CASE
       WHEN datedifference < 200 THEN 'very recent'
       WHEN datedifference BETWEEN 201 and 720 THEN 'moderately recent'
    ELSE 'not so recent'
    END AS Recency
    INTO Recency1
    FROM #numberofdays 
    --------------------------------------------
    SELECT * FROM Recency1
    ---------------------------------------------


--Recency2
--AS (
    SELECT[CustomerID],
          datedifference,
          Recency,
    CASE
      WHEN Recency ='very recent' THEN '1'
      WHEN Recency = 'Moderately recent' THEN '2'
      ELSE'3'
      END AS Recencyscore
      INTO Recency2
      FROM Recency1
---------------------------------------------------------------
SELECT * FROM Recency2
----------------------------------------------------------------

SELECT [CustomerID],
        sumofpurchasecount,
   CASE 
      WHEN sumofpurchasecount > 20 THEN 'high frequency'
      WHEN sumofpurchasecount BETWEEN 11 AND 19 THEN 'moderate frequency'
      ELSE 'low frequency'
END AS frequency
INTO Frequency1
FROM #SumFrq
---------------------------------------------------------------------------------------
SELECT * FROM Frequency1
---------------------------------------------------------------------------------------

    SELECT
       [CustomerID],
       sumofpurchasecount,
       frequency,
    CASE 
       WHEN frequency = 'high fequency' THEN '1'
       WHEN frequency = 'moderate frequency' THEN '2'
       ELSE '3'
    END AS freqencyscore
INTO Frequency2
FROM Frequency1
----------------------------------------------------------------------------------
SELECT * FROM Frequency2
----------------------------------------------------------------------------------


SELECT
       [CustomerID],
       total_spent,
    CASE 
       WHEN total_spent > 400000 THEN 'high spending'
       WHEN total_spent BETWEEN 210000 and 399999 THEN 'moderate spending'
       ELSE 'low spending'
    END AS monetaryvalue
INTO Monetaryvalue1
FROM #Totalamtspent
------------------------------------------------------------------------
SELECT * FROM Monetaryvalue1
-------------------------------------------------------------------------

--Monetaryvalue2
--AS (
    SELECT
       [CustomerID],
       total_spent,
       monetaryvalue,
    CASE 
       WHEN monetaryvalue = 'High spending'THEN '1'
       WHEN monetaryvalue = 'moderate spending'THEN '2'
       ELSE '3'
       END AS monetaryspendingscore
INTO Monetaryvalue2
FROM Monetaryvalue1
-------------------------------------------------------------------
SELECT * FROM Monetaryvalue2
-------------------------------------------------------------------


SELECT
    R2.[CustomerID],
    R2.Recency,
    R2.Recencyscore,
    F2.frequency,
    F2.frequencyscore,
    M2.monetaryvalue,
    M2.monetaryspendingscore
INTO #RFManalysis
FROM Recency2 AS R2
INNER JOIN Frequency2 AS F2 
ON R2.[CustomerID] = F2.[CustomerID]
INNER JOIN Monetaryvalue2 AS M2
ON F2.[CustomerID] = M2.[CustomerID]
--INNER JOIN Frequency1 F1
--ON M1.[CustomerID] = F1.[CustomerID]
--INNER JOIN Monetaryvalue1 M1 
--ON F1.[CustomerID] = M1.[CustomerID]
ORDER BY R2.Recencyscore ASC    
--------------------------------------------------------------------------------
SELECT * FROM #RFManalysis
--------------------------------------------------------------------------------


/* F) This sql code create customer segmentation based on RFM(Recency,Frequency and Monetary Value) criteria,.It categorizes customer into 
segments such 'High Value Customers','Big Spender','Loyal Spender','Potential Loyalists','Churned Customer'and 'Other'based on their recency, 
frequency and monetary value. the result are ordered according to the segmentation categories */
 --WITH CustomerSegments
 --AS
 --(
    SELECT
       [CustomerID],
       Recency,
       Recencyscore,
       frequency,
       frequencyscore,
       monetaryvalue,
       monetaryspendingscore,
    CASE
       WHEN (recency = 'very recent' OR recency = 'moderately recent')
         AND (Frequency = 'high Frequency' OR frequency = 'moderate frequency')
         AND monetaryvalue = 'high spending' THEN 'High Value Customer'
       WHEN recency = 'moderately recent'
         AND (frequency = 'lowfrequency') 
         AND monetaryvalue = 'high spending' THEN 'Big Spender'
       WHEN (recency = 'very recent' OR recency = 'moderately recent')
         AND (frequency = 'high frequency' OR frequency = 'moderate frequency')
         AND monetaryvalue ='low spending' Or monetaryvalue = 'more spending' THEN 'Loyal Custmer'
       WHEN (recency = 'very recent' OR recency = 'moderately recent')
         AND frequency = 'low frequency' AND ( monetaryvalue = 'low spending'
         OR  monetaryvalue = 'moderate spending') THEN 'Potential Loyalists'
       WHEN recency = 'not so recent' 
         AND (frequency = 'high frequency' OR frequency ='moderate frequency')
         AND monetaryvalue = 'low spending' THEN 'Churned Customer'
       ELSE 'Other'
       END AS customer_segmentation
       INTO Customerssegments
       FROM #RFManalysis
----------------------------------------------------------------------------------------------------------------------
SELECT * FROM Customerssegments
-----------------------------------------------------------------------------------------------------------------------

SELECT 
    CS.customer_segmentation,
    CS.[CustomerID], 
    SC.[PersonID], 
    P.[FirstName], 
    P.[MiddleName], 
    P.[LastName],
    ts.total_spent,
    CS.monetaryspendingscore, CS.monetaryvalue, nd.datedifference, CS.Recencyscore, 
    CS.Recency, 
    sf.Sumofpurchasecount,
    CS.frequencyscore, 
    CS.frequency
FROM Customerssegments CS
JOIN #numberofdays nd ON CS.[CustomerID] = nd.[CustomerID]
JOIN #Sumfrq sf ON nd.[CustomerID] = sf.[CustomerID]
JOIN #totalamtspent ts ON sf.[CustomerID] = ts.[CustomerID]
JOIN [Sales].[Customer] SC ON CS.[CustomerID] = SC.[CustomerID]
JOIN [Person].[Person] P ON SC.[PersonID] = P.[BusinessEntityID]
ORDER BY 
    CASE 
        WHEN customer_segmentation = 'High Value Customers' THEN 1
        WHEN customer_segmentation = 'Big spenders' THEN 2
        WHEN customer_segmentation = 'Loyal Customers' THEN 3
        WHEN customer_segmentation = 'Potential Loyalists' THEN 4
        WHEN customer_segmentation = 'Churned Customers' THEN 5
        WHEN customer_segmentation = 'Low activity' THEN 6
        ELSE 7 -- 'Other'
    END

/* 2) Customer Retention: Table Required 
i.	[Sales].[SalesOrderHeader] & [sales].[customer]
ii.	[Sales].[SalesOrderHeader] & #RFM (from prev question)
iii.[Sales].[Customer], [Person].[Person], [Person].[EmailAddress], [Person].[BusinessEntityAddress], [Person].[Address], [Person].[StateProvince], [Sales].[SalesTerritory]
a) Which customers have not made a purchase in the last 12 months?
b) how can we identify cuxtomer who are at risk of churning.

The provided SQL code retrieves unique CustomerIDs from the SalesOrderHeader table where the 
OrderDate is within the last 12 months based on the current date. It employs the DATEADD function to subtract 
12 months from the current date 
and filters accordingly.*/

SELECT DISTINCT [CustomerID],
                [OrderDate]
FROM [Sales].[SalesOrderHeader]
WHERE [OrderDate] <= DATEADD(month, -12, GETDATE())

/* b) Which customers have shown a decline in their purchase frequency or monetary value? 
This code analyzes customer purchase behavior for the years 2013 and 2014. 
It calculates purchase frequency and monetary value for each customer in these years and 
identifies those who showed a decline in either spending or purchase frequency. 
The final results display customer IDs, spending for both years, the decline in spending, purchase frequency
for both years, and the decline in purchase frequency, ordered by customer ID in descending order */
WITH countfrq 
AS 
(
    SELECT 
        [CustomerID], 
        YEAR([OrderDate]) AS order_year, 
        COUNT([SalesOrderID]) AS purchase_frequency
    FROM 
        [Sales].[SalesOrderHeader]
    WHERE 
        YEAR([OrderDate]) IN (2013, 2014)
    GROUP BY
        [CustomerID], YEAR([OrderDate])
),
monetary_value AS (
    SELECT
        [CustomerID],
        SUM(CASE WHEN YEAR([OrderDate]) = 2013 THEN ([OrderQty] * [UnitPrice]) ELSE 0 END) AS TotalSpent2013,
        SUM(CASE WHEN YEAR([OrderDate]) = 2014 THEN ([OrderQty] * [UnitPrice]) ELSE 0 END) AS TotalSpent2014
    FROM
        #RFM
    WHERE
        YEAR([OrderDate]) IN (2013, 2014)
    GROUP BY
        [CustomerID]
),
sum_purchase_frequency 
AS
(
SELECT 
    cf.[CustomerID],
    SUM(CASE WHEN order_year = 2013 THEN purchase_frequency ELSE 0 END) AS PurchaseFrequency2013,
    SUM(CASE WHEN order_year = 2014 THEN purchase_frequency ELSE 0 END) AS PurchaseFrequency2014
FROM 
    countfrq cf

GROUP BY
        [CustomerID]
)
SELECT spf.[CustomerID], 
       mv.TotalSpent2013, 
       mv.TotalSpent2014, 
      (mv.TotalSpent2014 - mv.TotalSpent2013) total_spent_decline, 
       spf.PurchaseFrequency2013, 
       spf.PurchaseFrequency2014, 
      (spf.PurchaseFrequency2014 - spf.PurchaseFrequency2013) purchase_frq_decline

FROM sum_purchase_frequency spf

JOIN monetary_value mv 
    ON spf.[CustomerID] = mv.[CustomerID]
WHERE 
    mv.TotalSpent2014 < mv.TotalSpent2013 

OR  spf.[CustomerID] IN (SELECT [CustomerID] 

FROM sum_purchase_frequency 

WHERE PurchaseFrequency2014 < PurchaseFrequency2013)

ORDER BY 
    spf.[CustomerID] DESC;	

/* 3)  CROSS SELING AND UPSELLING: 
a)How can we reach out to these customers with personalized offers or interventions?

This SQL query retrieves customer information including their ID, name, email, address, state/province, country/region,
and postal code from the AdventureWorks database. By combining data from various tables to provide comprehensive customer 
information. It joins the [Sales].[Customer], [Person].[Person], [Person].[EmailAddress], [Person].[BusinessEntityAddress], 
[Person].[Address], [Person].[StateProvince], [Sales].[SalesTerritory] tables to retrieve the desired columns.*/
SELECT
    c.[CustomerID],
    e.[BusinessEntityID],
    p.[FirstName],
    p.[MiddleName],
    p.[LastName],
    e.[EmailAddress],
    a.[AddressLine1],
    a.[AddressLine2],
    a.[City],
    s.[Name] state_province,
    st.[Name] country_region,
    a.[PostalCode]
FROM
    [Sales].[Customer] c
INNER JOIN
    [Person].[Person] p 
        ON c.[PersonID] = p.BusinessEntityID
INNER JOIN
    [Person].[EmailAddress] e 
        ON p.BusinessEntityID = e.BusinessEntityID
INNER JOIN
    [Person].[BusinessEntityAddress] b 
        ON e.BusinessEntityID = b.[BusinessEntityID]
INNER JOIN 
    [Person].[Address] a 
        ON b.[AddressID] = a.[AddressID]
INNER JOIN 
    [Person].[StateProvince] s 
        ON a.[StateProvinceID] = s.[StateProvinceID]
INNER JOIN 
    [Sales].[SalesTerritory] st 
        ON s.[TerritoryID] = st.[TerritoryID]

/* b) Which products are frequently purchased together? 

The query identifies pairs of products (identified by ProductID) that are frequently bought together from 
the [Sales].[SalesOrderDetail] table. It counts the occurrences of each pair, excluding cases where a product 
is paired with itself, and presents this information as original_purchase (the first product), bought_with 
(the product it was bought with), and number_of_times (how many times they were bought together). The results 
are sorted in descending order of frequency.*/

SELECT 
   SOD1.[ProductID] AS original_purchase, 
   SOD2.[ProductID] AS bought_with, 
   COUNT(*) AS  number_of_times
FROM [Sales].[SalesOrderDetail] SOD1
JOIN [Sales].[SalesOrderDetail] SOD2
ON SOD1.[SalesOrderID] = SOD2.[SalesOrderID] AND SOD1.[ProductID] != SOD2.[ProductID]
GROUP BY  SOD1.[ProductID], SOD2.[ProductID]
ORDER BY number_of_times DESC

/* c) Which customers have made high-value purchases recently, indicating potential interest in premium upgrades?
This SQL code identifies high-value customers based on their total spending in the last 3 months. It calculates 
the total spent by each customer in this period, categorizing them as either 'High-value customer' if they spent 
more than $100,000 or 'Regular customer' if they spent less. The result is ordered by the total spent in descending 
order.*/
WITH CustomerHighValuePurchases 
AS (
    SELECT
        SOH.[CustomerID],
        SUM(sod.[OrderQty] * sod.[UnitPrice]) AS total_spent
    FROM
        [Sales].[SalesOrderHeader] SOH
    INNER JOIN
        [Sales].[SalesOrderDetail] SOD 
    ON SOH.[SalesOrderID] = SOD.[SalesOrderID]
    WHERE
        SOH.[OrderDate] >= DATEADD(month, -3, 2014/07/01) -- Consider purchases from the last 3 months
    GROUP BY
        SOH.[CustomerID]
)
SELECT
    chv.[CustomerID],
    chv.total_spent,
    CASE
        WHEN chv.total_spent > 100000 THEN 'High-value customer'
        ELSE 'Regular customer'
    END AS customer_category
FROM
    CustomerHighValuePurchases chv
ORDER BY
    chv.total_spent DESC;

--                OR

WITH CustomerHighValuePurchases 
AS (
    SELECT
        SOH.[CustomerID],
        SUM(sod.[OrderQty] * sod.[UnitPrice]) AS total_spent
    FROM
        [Sales].[SalesOrderHeader] SOH
    INNER JOIN
        [Sales].[SalesOrderDetail] SOD ON SOH.[SalesOrderID] = SOD.[SalesOrderID]
    WHERE
        SOH.[OrderDate] >= DATEADD(month, -3, 2014/07/01) -- Consider purchases from the last 3 months
    GROUP BY
        SOH.[CustomerID] )
SELECT
    chv.[CustomerID],
    chv.total_spent
FROM
    CustomerHighValuePurchases chv
    WHERE total_spent >=100000
ORDER BY chv.total_spent DESC;



WITH CustomerSegments AS (
    SELECT 
        [CustomerID], Recency, Recencyscore, frequency, frequencyscore, monetaryvalue, monetaryspendingscore,
        CASE
            WHEN (recency = 'very recent' OR recency = 'moderately recent') AND (frequency = 'high frequency' OR frequency = 'moderate frequency') AND monetaryvalue = 'high spending' THEN 'High Value Customers'
            WHEN recency = 'moderately recent' and frequency = 'low frequency' and monetaryvalue = 'high spending' THEN 'Big spenders'
            WHEN (recency = 'very recent' OR recency = 'moderately recent') AND (frequency = 'high frequency' OR frequency = 'moderate frequency') AND(monetaryvalue = 'low spending' OR monetaryvalue = 'moderate spending') THEN 'Loyal Customers'
            WHEN (recency = 'very recent' OR recency = 'moderately recent') AND frequency = 'low frequency' AND (monetaryvalue = 'low spending' OR monetaryvalue = 'moderate spending') THEN 'Potential Loyalists'
            WHEN recency = 'not so recent' AND (frequency = 'high frequency' OR frequency = 'moderate frequency') AND monetaryvalue = 'low spending' THEN 'Churned Customers'
            ELSE 'Other'
        END AS customer_segmentation
    FROM #RFManalysis
)
SELECT 
    CS.[CustomerID], 
    SC.[PersonID], -- Adding PersonID from Sales.Customer
    P.[FirstName],
    P.[MiddleName],
    P.[LastName],
    CS.Recency, 
    CS.Recencyscore, 
    CS.frequency, 
    CS.frequencyscore, 
    CS.monetaryvalue, 
    CS.monetaryspendingscore, 
    CS.customer_segmentation
FROM CustomerSegments CS
JOIN [Sales].[Customer] SC ON CS.[CustomerID] = SC.[CustomerID]
JOIN [Person].[Person] P ON SC.[PersonID] = P.[BusinessEntityID] -- Joining with BusinessEntityID
ORDER BY 
    CASE 
        WHEN customer_segmentation = 'High Value Customers' THEN 1
        WHEN customer_segmentation = 'Big spenders' THEN 2
        WHEN customer_segmentation = 'Loyal Customers' THEN 3
        WHEN customer_segmentation = 'Potential Loyalists' THEN 4
        WHEN customer_segmentation = 'Churned Customers' THEN 5
        ELSE 6 -- 'Other'
    END
