--zad 1

--a
SELECT CONCAT(p.LastName, ' ', p.FirstName) AS Klient, Year(soh.OrderDate) AS Rok, CAST(SUM(TotalDue) AS DECIMAL(10,2)) AS SumaTransakcji
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.CustomerID = p.BusinessEntityID
GROUP BY ROLLUP(YEAR(soh.OrderDate), CONCAT(p.LastName, ' ', p.FirstName))
ORDER BY 3 DESC;

SELECT CONCAT(p.LastName, ' ', p.FirstName) AS Klient, Year(soh.OrderDate) AS Rok, CAST(SUM(TotalDue) AS DECIMAL(10,2)) AS SumaTransakcji
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.CustomerID = p.BusinessEntityID
GROUP BY CUBE(YEAR(soh.OrderDate), CONCAT(p.LastName, ' ', p.FirstName))
ORDER BY 1,2;

SELECT CONCAT(p.LastName, ' ', p.FirstName) AS Klient, Year(soh.OrderDate) AS Rok, CAST(SUM(TotalDue) AS DECIMAL(10,2)) AS SumaTransakcji
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.CustomerID = p.BusinessEntityID
GROUP BY GROUPING SETS(YEAR(soh.OrderDate), CONCAT(p.LastName, ' ', p.FirstName), (YEAR(soh.OrderDate), CONCAT(p.LAstName, ' ', p.FirstName)))
ORDER BY 1,2;

SELECT CONCAT(p.LastName, ' ', p.FirstName) AS Klient, Year(soh.OrderDate) AS Rok, CAST(SUM(TotalDue) AS DECIMAL(10,2)) AS SumaTransakcji
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.CustomerID = p.BusinessEntityID
GROUP BY GROUPING SETS((YEAR(soh.OrderDate), CONCAT(p.LAstName, ' ', p.FirstName)))
ORDER BY  DESC;

SELECT CONCAT(p.LastName, ' ', p.FirstName) AS Klient, Year(soh.OrderDate) AS Rok, CAST(SUM(TotalDue) AS DECIMAL(10,2)) AS SumaTransakcji,
	ROW_NUMBER() OVER(ORDER BY SUM(TotalDue) DESC) AS NajwiekszaSumaOgolnie,
	ROW_NUMBER() OVER(PARTITION BY YEAR(soh.OrderDate) ORDER BY SUM(TotalDue) DESC) AS NajwiekszaSumaRok
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.CustomerID = p.BusinessEntityID
GROUP BY CONCAT(p.LastName, ' ', p.FirstName), Year(soh.OrderDate)
ORDER BY NajwiekszaSumaRok, Rok;

--b
SELECT pc.Name AS Kategoria, p.Name AS Produkt, YEAR(soh.OrderDate) AS Rok, SUM(UnitPriceDiscount * OrderQty * UnitPrice) AS SumaZnizek
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY GROUPING SETS((pc.Name, p.Name, YEAR(soh.OrderDate)))
ORDER BY 1, 2, 3;


--zad2 
WITH SprzedazeKategorii AS (
SELECT pc.Name AS Kategoria, YEAR(soh.OrderDate) AS Rok, SUM(sod.LineTotal) AS kwotaSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Bikes'
GROUP BY pc.Name, YEAR(soh.OrderDate)
)
SELECT Kategoria, Rok, 
CAST((100 * kwotaSprzedazy / SUM(kwotaSprzedazy) OVER ()) AS DECIMAL(10,2)) AS ProcentSprzedazy
FROM SprzedazeKategorii
GROUP BY Kategoria, Rok, kwotaSprzedazy;

WITH SprzedazeKategorii AS (
SELECT pc.Name AS Kategoria, YEAR(soh.OrderDate) AS Rok, SUM(sod.LineTotal) AS kwotaSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Accessories'
GROUP BY pc.Name, YEAR(soh.OrderDate)
)
SELECT Kategoria, Rok, 
CAST((100 * kwotaSprzedazy / SUM(kwotaSprzedazy) OVER ()) AS DECIMAL(4,2)) AS ProcentSprzedazy
FROM SprzedazeKategorii
GROUP BY Kategoria, Rok, kwotaSprzedazy;

WITH SprzedazeKategorii AS (
SELECT pc.Name AS Kategoria, YEAR(soh.OrderDate) AS Rok, SUM(sod.LineTotal) AS kwotaSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name = 'Clothing'
GROUP BY pc.Name, YEAR(soh.OrderDate)
)
SELECT Kategoria, Rok, 
CAST((100 * kwotaSprzedazy / SUM(kwotaSprzedazy) OVER ()) AS DECIMAL(4,2)) AS ProcentSprzedazy
FROM SprzedazeKategorii
GROUP BY Kategoria, Rok, kwotaSprzedazy;

WITH SprzedazeKategorii AS (
SELECT pc.Name AS Kategoria, YEAR(soh.OrderDate) AS Rok, SUM(sod.LineTotal) AS kwotaSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name, YEAR(soh.OrderDate)
)
SELECT Kategoria, Rok, 
CAST((100 * kwotaSprzedazy / SUM(kwotaSprzedazy) OVER (PARTITION BY Kategoria)) AS DECIMAL(4,2)) AS ProcentSprzedazy
FROM SprzedazeKategorii
GROUP BY Kategoria, Rok, kwotaSprzedazy;


--b
SELECT CONCAT(p.FirstName, ' ', p.LastName) AS Sprzedawca, YEAR(soh.OrderDate) AS Rok, MONTH(soh.OrderDate) AS Miesiac,
COUNT(soh.SalesOrderID) AS TransakcjeMiesiac,
SUM(COUNT(soh.SalesOrderID) OVER()) AS TransakcjeRok
FROM Sales.SalesOrderHeader soh
JOIN Person.Person p ON soh.SalesPersonID= p.BusinessEntityID
GROUP BY CONCAT(p.FirstNAme, ' ', p.LastName), Year(soh.OrderDate), MONTH(soh.OrderDate);

SELECT * FROM Sales.SalesPerson;
SELECT * FROM HumanResources.Employee WHERE BusinessEntityID BETWEEN 274 AND 288;
SELECT * FROM Person.Person;

WITH OrdersByMonth AS (
    SELECT 
		CONCAT(p.FirstName, ' ', p.LastName) AS Sprzedawca,
        YEAR(soh.OrderDate) AS Rok,
        MONTH(soh.OrderDate) AS Miesiac,
        COUNT(soh.SalesOrderID) AS LiczbaZamowien
    FROM Sales.SalesOrderHeader soh
	JOIN Person.Person p ON soh.SalesPersonID = p.BusinessEntityID
    GROUP BY 
		CONCAT(p.FirstName, ' ', p.LastName),
        YEAR(soh.OrderDate), 
        MONTH(soh.OrderDate) 
)
SELECT 
    Sprzedawca,
    Rok,
    Miesiac,
    LiczbaZamowien AS LiczbaZamowienMiesiac,
	SUM(LiczbaZamowien) OVER (PARTITION BY Sprzedawca, Rok) AS LiczbaZamowienRok,
    SUM(LiczbaZamowien) OVER (PARTITION BY Sprzedawca, Rok ORDER BY Miesiac) AS LiczbaZamowienRokNarastajaco,
    -- Liczba zamówień w bieżącym i poprzednim miesiącu
    LiczbaZamowien + COALESCE(LAG(LiczbaZamowien) OVER(PARTITION BY Sprzedawca, Rok ORDER BY Miesiac), 0) AS LiczbaZamowienMiesiacIPoprzedni
FROM OrdersByMonth obm
ORDER BY 
	Sprzedawca,
    Rok, 
    Miesiac;





SELECT DISTINCT CONCAT(p.FirstName, ' ', p.LastName) AS Sprzedawca, YEAR(soh.OrderDate) AS Rok, MONTH(soh.OrderDate) AS Miesiac,
	COUNT(soh.SalesOrderID) OVER(PARTITION BY CONCAT(p.FirstName, ' ', p.LastName), YEAR(soh.OrderDate), MONTH(soh.OrderDate)) AS LiczbaZamowienMiesiac,
	COUNT(soh.SalesOrderID) OVER(PARTITION BY CONCAT(p.FirstName, ' ', p.LastName), YEAR(soh.OrderDate)) AS LiczbaZamowienRok,
	COUNT(soh.SalesOrderID) OVER(PARTITION BY CONCAT(p.FirstName, ' ', p.LastName), YEAR(soh.OrderDate) ORDER BY MONTH(soh.OrderDate)) AS LiczbaZamowienRokNarastajaco,
	COUNT(soh.SalesOrderID) OVER(PARTITION BY CONCAT(p.FirstName, ' ', p.LastName), YEAR(soh.OrderDate), MONTH(soh.OrderDate)) + LAG(COUNT(soh.SalesOrderID) OVER(PARTITION BY CONCAT(p.FirstName, ' ', p.LastName), YEAR(soh.OrderDate), MONTH(soh.OrderDate))) OVER(ORDER BY MONTH(soh.OrderDate)) ASD
FROM Sales.SalesOrderHeader soh JOIN Person.Person p ON soh.SalesPersonID = p.BusinessEntityID;




--c 
SELECT CONCAT(p.FirstName, ' ', p.LastName) AS Klient, SUM(sod.OrderQty) AS LiczbaProduktow,
	RANK() OVER(ORDER BY SUM(sod.OrderQty) DESC) AS Rank,
	DENSE_RANK() OVER(ORDER BY SUM(sod.OrderQty) DESC) AS DenseRank
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
GROUP BY CONCAT(p.FirstName, ' ', p.LastName);

--d
SELECT p.Name, CAST(CAST(SUM(sod.OrderQty) AS FLOAT)/COUNT(*) AS DECIMAL(10,3)) AS SredniaLiczbaWZamowieniu,
NTILE(3) OVER(ORDER BY CAST(SUM(sod.OrderQty) AS FLOAT)/COUNT(*) DESC) AS GrupaSprzedazy
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY 2 DESC;

