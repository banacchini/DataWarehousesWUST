--zad 1

SELECT YEAR(soh.OrderDate) AS Year, MONTH(soh.OrderDate) AS Month, COUNT(DISTINCT soh.CustomerID) AS UniqueCustomersCount
FROM Sales.SalesOrderHeader soh
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY 1, 2;

SELECT * FROM (
	SELECT YEAR(soh.OrderDate) AS Year, MONTH(soh.OrderDate) AS Month, soh.CustomerID
	FROM Sales.SalesOrderHeader soh
	GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), soh.CustomerID)
	AS SourceData
	PIVOT (
		COUNT(CustomerID)
		FOR Month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
		) 
		AS PivotTable
	ORDER BY Year;

--zad2 
WITH SalesPersonTransactions AS (
    SELECT 
        CONCAT(sp.FirstName, ' ', sp.LastName) AS Name, 
        YEAR(soh.OrderDate) AS Year, 
        COUNT(soh.SalesOrderID) AS TransactionCount
    FROM 
        Sales.SalesOrderHeader soh
    JOIN 
        HumanResources.Employee e ON soh.SalesPersonID = e.BusinessEntityID
    JOIN 
        Person.Person sp ON e.BusinessEntityID = sp.BusinessEntityID
    GROUP BY 
        sp.FirstName, sp.LastName, YEAR(soh.OrderDate), soh.SalesPersonID
)
SELECT 
	*
FROM 
    SalesPersonTransactions
PIVOT (
	SUM(TransactionCount)
	FOR Year in ([2011], [2012], [2013], [2014])
	) AS PivotTable
WHERE (
	[2011] IS NOT NULL AND
	[2012] IS NOT NULL AND
	[2013] IS NOT NULL AND
	[2014] IS NOT NULL
	)
ORDER BY 
    1;



-- szukamy jilla
SELECT * FROM Sales.SalesPerson sp JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID;


SELECT soh.OrderDate, soh.SalesOrderID, st.Name, soh.TotalDue, COUNT(sod.SalesOrderDetailID) AS ProductCount, SUM(sod.OrderQty) AS ProductQty
FROM
Sales.SalesOrderHeader soh 
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
WHERE
SalesPersonID = 274
GROUP BY soh.OrderDate, soh.SalesOrderID, soh.TotalDue, st.Name
ORDER BY 1;


--zad3

SELECT 
    YEAR(soh.OrderDate) AS Year, 
    MONTH(soh.OrderDate) AS Month, 
    DAY(soh.OrderDate) AS Day, 
    CAST(SUM(sod.LineTotal) AS DECIMAL(9,2)) AS SalesSum,  --nie mozemy sumowac po TotalDue z powodu powtorzen
    COUNT(DISTINCT sod.ProductID) AS ProductsCount
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY 
    YEAR(soh.OrderDate), MONTH(soh.OrderDate), DAY(soh.OrderDate)
ORDER BY 
    1, 2, 3;


--zad4
SELECT 
    MONTH(soh.OrderDate) AS Month, 
    CASE DATEPART(dw, soh.OrderDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS WeekDay,
    CAST(SUM(sod.LineTotal) AS DECIMAL(12,2)) AS SalesSum, 
    COUNT(DISTINCT sod.ProductID) AS ProductCount
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY 
    MONTH(soh.OrderDate), DATEPART(dw, soh.OrderDate)
ORDER BY 1, 2;

--zad 5

WITH AllCategoriesOrders AS (
    SELECT soh.SalesOrderID, soh.CustomerID
    FROM Sales.SalesOrderHeader soh 
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN Production.Product p ON sod.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
    GROUP BY soh.SalesOrderID, soh.CustomerID
    HAVING COUNT(DISTINCT sc.ProductCategoryID) = 4
), 
AboveAverageOrders AS (
    SELECT SalesOrderID, CustomerID,
        CASE 
            WHEN TotalDue > 2.5 * (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader) THEN 1
            ELSE 0
        END AS AboveAvg
    FROM Sales.SalesOrderHeader
),
CustomerOrderCount AS (
    SELECT CustomerID, 
           COUNT(SalesOrderID) AS OrderCount, 
           SUM(AboveAvg) AS AboveAvgOrderCount
    FROM AboveAverageOrders
    GROUP BY CustomerID
) SELECT p.FirstName, p.LastName, coc.OrderCount, CAST(SUM(soh.TotalDue) AS DECIMAL(9,2)) AS TransactionSum, 
	CASE
		WHEN coc.OrderCount >= 4 AND coc.AboveAvgOrderCount >= 2 AND soh.CustomerID IN (SELECT CustomerID FROM AllCategoriesOrders) THEN 'Platinum'
		WHEN coc.OrderCount >= 4 AND coc.AboveAvgOrderCount >= 2 THEN 'Gold'
		WHEN coc.OrderCount >= 2 THEN 'Silver'
		ELSE NULL
		END AS CardColor
	FROM 
	Sales.SalesOrderHeader soh 
	JOIN CustomerOrderCount coc ON soh.CustomerID = coc.CustomerID
	JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
	JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
	GROUP BY soh.CustomerID, p.FirstName, p.LastName, coc.OrderCount, coc.AboveAvgOrderCount;


SELECT st.Name, MIN(soh.OrderDate)
FROM Sales.SalesOrderHeader soh JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY 2;

SELECT OrderDate FROM Sales.SalesOrderHeader;

SELECT sp.BusinessEntityID, AVG(soh.TotalDue) FROM Sales.SalesPerson sp JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
GROUP BY sp.BusinessEntityID;


WITH SaleSeason AS (
	SELECT SalesOrderID,
	CASE WHEN MONTH(OrderDate) IN (12, 1, 2) THEN 'winter'
     WHEN MONTH(OrderDate) in (3, 4, 5) then 'spring'
     WHEN MONTH(OrderDate) in (6, 7, 8) then 'summer'
     WHEN MONTH(OrderDate) in (9, 10, 11) then 'autumn'
	 END AS Season
	FROM Sales.SalesOrderHeader),
	CategorySeasonSales AS
	(SELECT pc.Name, ss.Season, SUM(sod.OrderQty) as ProductsSold
	FROM SaleSeason ss JOIN Sales.SalesOrderHeader soh ON ss.SalesOrderID = soh.SalesOrderID
	JOIN Sales.SalesOrderDetail sod ON ss.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product p ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
	GROUP BY pc.Name, ss.Season
	)
SELECT *
FROM CategorySeasonSales
PIVOT (
	SUM(ProductsSold)
	FOR Season IN ([winter], [spring], [summer], [autumn])
)AS PivotTable;



WITH SaleSeason AS (
	SELECT soh.SalesOrderID,
	--najpierw australia
	CASE WHEN MONTH(soh.OrderDate) IN (12, 1, 2) AND st.CountryRegionCode = 'AU' THEN 'summer'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) AND st.CountryRegionCode = 'AU' then 'autumn'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) AND st.CountryRegionCode = 'AU' then 'winter'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) AND st.CountryRegionCode = 'AU' then 'spring'
	 WHEN MONTH(soh.OrderDate) IN (12, 1, 2) THEN 'winter'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) then 'spring'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) then 'summer'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) then 'autumn'
	 END AS Season
	FROM Sales.SalesOrderHeader soh
	JOIN Sales.SalesTerritory st ON soh.TerritoryID = soh.TerritoryID),
	CategorySeasonSales AS
	(SELECT pc.Name, ss.Season, SUM(sod.OrderQty) as ProductsSold
	FROM SaleSeason ss JOIN Sales.SalesOrderHeader soh ON ss.SalesOrderID = soh.SalesOrderID
	JOIN Sales.SalesOrderDetail sod ON ss.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product p ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
	GROUP BY pc.Name, ss.Season
	)
SELECT *
FROM CategorySeasonSales
PIVOT (
	SUM(ProductsSold)
	FOR Season IN ([winter], [spring], [summer], [autumn])
)AS PivotTable;

WITH SaleSeason AS (
	SELECT soh.SalesOrderID,
	--najpierw australia
	CASE WHEN MONTH(soh.OrderDate) IN (12, 1, 2) AND st.CountryRegionCode = 'AU' THEN 'summer'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) AND st.CountryRegionCode = 'AU' then 'autumn'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) AND st.CountryRegionCode = 'AU' then 'winter'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) AND st.CountryRegionCode = 'AU' then 'spring'
	 WHEN MONTH(soh.OrderDate) IN (12, 1, 2) THEN 'winter'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) then 'spring'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) then 'summer'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) then 'autumn'
	 END AS Season
	FROM Sales.SalesOrderHeader soh
	JOIN Sales.SalesTerritory st ON soh.TerritoryID = soh.TerritoryID),
	CategorySeasonSales AS
	(SELECT pc.Name, ss.Season, SUM(sod.OrderQty) as ProductsSold
	FROM SaleSeason ss JOIN Sales.SalesOrderHeader soh ON ss.SalesOrderID = soh.SalesOrderID
	JOIN Sales.SalesOrderDetail sod ON ss.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product p ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
	GROUP BY pc.Name, ss.Season
	)
SELECT * FROM CategorySeasonSales;


WITH 
SaleSeason AS (
	SELECT soh.SalesOrderID,
	--najpierw australia
	CASE WHEN MONTH(soh.OrderDate) IN (12, 1, 2) AND st.CountryRegionCode = 'AU' THEN 'summer'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) AND st.CountryRegionCode = 'AU' then 'autumn'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) AND st.CountryRegionCode = 'AU' then 'winter'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) AND st.CountryRegionCode = 'AU' then 'spring'
	 WHEN MONTH(soh.OrderDate) IN (12, 1, 2) THEN 'winter'
     WHEN MONTH(soh.OrderDate) in (3, 4, 5) then 'spring'
     WHEN MONTH(soh.OrderDate) in (6, 7, 8) then 'summer'
     WHEN MONTH(soh.OrderDate) in (9, 10, 11) then 'autumn'
	 END AS Season
	FROM Sales.SalesOrderHeader soh
	JOIN Sales.SalesTerritory st ON soh.TerritoryID = soh.TerritoryID),
CategorySeasonSales AS
	(SELECT pc.Name, ss.Season, sod.OrderQty as ProductsSold
	FROM SaleSeason ss JOIN Sales.SalesOrderHeader soh ON ss.SalesOrderID = soh.SalesOrderID
	JOIN Sales.SalesOrderDetail sod ON ss.SalesOrderID = sod.SalesOrderID
	JOIN Production.Product p ON sod.ProductID = p.ProductID
	JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
	JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
	)
SELECT *
FROM CategorySeasonSales
PIVOT (
	SUM(ProductsSold)
	FOR Season IN ([winter], [spring], [summer], [autumn])
)AS PivotTable;