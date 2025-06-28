IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Czech' AND TABLE_NAME = 'FACT_SALES'
)
DROP TABLE Czech.FACT_SALES;
GO

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Czech' AND TABLE_NAME = 'DIM_CUSTOMER'
)
DROP TABLE Czech.DIM_CUSTOMER;
GO

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Czech' AND TABLE_NAME = 'DIM_PRODUCT'
)
DROP TABLE Czech.DIM_PRODUCT;
GO

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Czech' AND TABLE_NAME = 'DIM_SALESPERSON'
)
DROP TABLE Czech.DIM_SALESPERSON;
GO

IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'Czech' AND TABLE_NAME = 'DIM_TIME'
)
DROP TABLE Czech.DIM_TIME;
GO

IF EXISTS (
	SELECT *
	FROM INFORMATION_SCHEMA.SCHEMATA
	WHERE SCHEMA_NAME = 'Czech' AND CATALOG_NAME = 'AdventureWorks2014')
	DROP SCHEMA Czech;
GO

CREATE SCHEMA Czech;
GO


-- Tworzenie tabel wymiarów
CREATE TABLE Czech.DIM_CUSTOMER (
    CustomerID INT,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(10),
    City NVARCHAR(50),
    TerritoryName NVARCHAR(50),
    CountryRegionCode NVARCHAR(10),
    [Group] NVARCHAR(50),
	CONSTRAINT PK_DIM_CUSTOMER PRIMARY KEY (CustomerID)
);

CREATE TABLE Czech.DIM_PRODUCT (
    ProductID INT,
    Name NVARCHAR(100) NOT NULL,
    ListPrice DECIMAL(10,2) NOT NULL CHECK (ListPrice >= 0),
    Color NVARCHAR(20),
    SubCategoryName NVARCHAR(50),
    CategoryName NVARCHAR(50),
    Weight DECIMAL(10,2) CHECK (Weight >= 0),
    Size NVARCHAR(10),
    IsPurchased BIT NOT NULL,
	CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (ProductID)
);

CREATE TABLE Czech.DIM_SALESPERSON (
    SalesPersonID INT,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(10),
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    CountryRegionCode NVARCHAR(10),
    [Group] NVARCHAR(50),
	CONSTRAINT PK_DIM_SALESPERSON PRIMARY KEY (SalesPersonID)
);

CREATE TABLE Czech.DIM_TIME (
    PK_TIME INT, -- np. 20240421
    Rok INT,
    Kwartal INT,
    Miesiac INT,
    Miesiac_Slow NVARCHAR(20),
    Dzien_Tygodnia_Slow NVARCHAR(20),
    Dzien_Miesiaca INT
	CONSTRAINT PK_DIM_TIME PRIMARY KEY (PK_TIME)
);

-- Tworzenie tabeli faktów
CREATE TABLE Czech.FACT_SALES (
    ProductID INT NOT NULL,
    CustomerID INT,
    SalesPersonID INT,
    OrderDate INT NOT NULL CHECK (OrderDate BETWEEN 20000101 AND 21001231),
    ShipDate INT CHECK (ShipDate BETWEEN 20000101 AND 21001231),
    OrderQty INT NOT NULL CHECK (OrderQty > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    UnitPriceDiscount DECIMAL(5,2) DEFAULT 0 CHECK (UnitPriceDiscount >= 0),
    LineTotal DECIMAL(18,2) NOT NULL CHECK (LineTotal >= 0),
    CONSTRAINT FK_FACT_SALES_Product FOREIGN KEY (ProductID) REFERENCES Czech.DIM_PRODUCT(ProductID) ON DELETE NO ACTION,
    CONSTRAINT FK_FACT_SALES_Customer FOREIGN KEY (CustomerID) REFERENCES Czech.DIM_CUSTOMER(CustomerID) ON DELETE SET NULL, -- Usunięcie klienta ustawia NULL w sprzedaży
    CONSTRAINT FK_FACT_SALES_SalesPerson FOREIGN KEY (SalesPersonID) REFERENCES Czech.DIM_SALESPERSON(SalesPersonID) ON DELETE SET NULL, -- Usunięcie sprzedawcy ustawia NULL
	CONSTRAINT FK_FACT_SALES_OrderDate FOREIGN KEY (OrderDate) REFERENCES Czech.DIM_TIME(PK_TIME) ON DELETE NO ACTION);


--Customer
WITH AddressPriority AS (
    SELECT 
        bea.BusinessEntityID, 
        a.City, 
        ROW_NUMBER() OVER (
            PARTITION BY bea.BusinessEntityID 
            ORDER BY 
                CASE WHEN at.Name = 'Home' THEN 1 ELSE 2 END, -- Priorytet: Home → inny
                bea.AddressID -- Jeśli nie ma Home, wybierz najniższy AddressID
        ) AS rn
    FROM Person.BusinessEntityAddress bea
    JOIN Person.Address a ON bea.AddressID = a.AddressID
    JOIN Person.AddressType at ON bea.AddressTypeID = at.AddressTypeID
)
INSERT INTO Czech.DIM_CUSTOMER (CustomerID, FirstName, LastName, Title, City, TerritoryName, CountryRegionCode, [Group])
SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    p.Title,
    ap.City,  
    st.Name AS TerritoryName,
    st.CountryRegionCode,
    st.[Group]
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN AddressPriority ap ON c.PersonID = ap.BusinessEntityID AND ap.rn = 1
LEFT JOIN Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID;


SELECT * FROM Czech.DIM_CUSTOMER;

INSERT INTO Czech.DIM_PRODUCT (ProductID, Name, ListPrice, Color, SubCategoryName, CategoryName, Weight, Size, IsPurchased)
SELECT DISTINCT
    p.ProductID,
    p.Name,
    p.ListPrice,
    p.Color,
    psc.Name AS SubCategoryName,
    pc.Name AS CategoryName,
    p.Weight,
    p.Size,
    1 AS IsPurchased
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
INNER JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID;

SELECT * FROM Czech.DIM_PRODUCT;

INSERT INTO Czech.DIM_SALESPERSON (SalesPersonID, FirstName, LastName, Title, Gender, CountryRegionCode, [Group])
SELECT 
    sp.BusinessEntityID AS SalesPersonID,
    p.FirstName,
    p.LastName,
    p.Title,
    e.Gender,
    st.CountryRegionCode,
    st.[Group]
FROM Sales.SalesPerson sp
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID;

SELECT * FROM Czech.DIM_SALESPERSON;

--zad2. lista 5


IF OBJECT_ID('tempdb..#Miesiace') IS NOT NULL
    DROP TABLE #Miesiace;

IF OBJECT_ID('tempdb..#DniTygodnia') IS NOT NULL
    DROP TABLE #DniTygodnia;

CREATE TABLE #Miesiace (
    Miesiac INT PRIMARY KEY,
    Miesiac_Slow NVARCHAR(20)
);

INSERT INTO #Miesiace (Miesiac, Miesiac_Slow)
VALUES 
(1, 'Styczeń'), (2, 'Luty'), (3, 'Marzec'), (4, 'Kwiecień'),
(5, 'Maj'), (6, 'Czerwiec'), (7, 'Lipiec'), (8, 'Sierpień'),
(9, 'Wrzesień'), (10, 'Październik'), (11, 'Listopad'), (12, 'Grudzień');

CREATE TABLE #DniTygodnia (
    Dzien_Tygodnia INT PRIMARY KEY,
    Dzien_Tygodnia_Slow NVARCHAR(20)
);

INSERT INTO #DniTygodnia (Dzien_Tygodnia, Dzien_Tygodnia_Slow)
VALUES 
(1, 'Niedziela'), (2, 'Poniedziałek'), (3, 'Wtorek'), (4, 'Środa'),
(5, 'Czwartek'), (6, 'Piątek'), (7, 'Sobota');


WITH CTE_Dates AS (
    SELECT CAST('20110531' AS DATE) AS D
    UNION ALL
    SELECT DATEADD(DAY, 1, D)
    FROM CTE_Dates
    WHERE D < '20141231'
)
INSERT INTO Czech.DIM_TIME 
(PK_TIME, Rok, Kwartal, Miesiac, Miesiac_Slow, Dzien_Tygodnia_Slow, Dzien_Miesiaca)
SELECT 
    CONVERT(INT, FORMAT(D, 'yyyyMMdd')) AS PK_TIME,
    DATEPART(YEAR, D) AS Rok,
    DATEPART(QUARTER, D) AS Kwartal,
    DATEPART(MONTH, D) AS Miesiac,
    m.Miesiac_Slow,
    dt.Dzien_Tygodnia_Slow,
    DATEPART(DAY, D) AS Dzien_Miesiaca
FROM CTE_Dates
JOIN #Miesiace m ON DATEPART(MONTH, D) = m.Miesiac
JOIN #DniTygodnia dt ON DATEPART(WEEKDAY, D) = dt.Dzien_Tygodnia
OPTION (MAXRECURSION 10000);

SELECT * FROM Czech.DIM_TIME;

INSERT INTO Czech.FACT_SALES 
(ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal)
SELECT 
    sod.ProductID,
    soh.CustomerID,
    soh.SalesPersonID,
    CAST(FORMAT(soh.OrderDate, 'yyyyMMdd') AS INT) AS OrderDate, 
    CAST(FORMAT(soh.ShipDate, 'yyyyMMdd') AS INT) AS ShipDate, 
    sod.OrderQty,
    sod.UnitPrice,
    sod.UnitPriceDiscount,
    sod.LineTotal
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID;

SELECT * FROM Czech.FACT_SALES ORDER BY OrderDate, SalesPersonID;

--zad4.

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FACT_SALES_Product' AND parent_object_id = OBJECT_ID('Czech.FACT_SALES'))
BEGIN
    ALTER TABLE Czech.FACT_SALES
    DROP CONSTRAINT FK_FACT_SALES_Product;
END

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FACT_SALES_Customer' AND parent_object_id = OBJECT_ID('Czech.FACT_SALES'))
BEGIN
    ALTER TABLE Czech.FACT_SALES
    DROP CONSTRAINT FK_FACT_SALES_Customer;
END

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FACT_SALES_SalesPerson' AND parent_object_id = OBJECT_ID('Czech.FACT_SALES'))
BEGIN
    ALTER TABLE Czech.FACT_SALES
    DROP CONSTRAINT FK_FACT_SALES_SalesPerson;
END

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FACT_SALES_Date' AND parent_object_id = OBJECT_ID('Czech.FACT_SALES'))
BEGIN
    ALTER TABLE Czech.FACT_SALES
    DROP CONSTRAINT FK_FACT_SALES_OrderDate;
END

-- Definiowanie kluczy głównych dla tabel wymiarów
-- Sprawdzenie i usunięcie istniejącego klucza podstawowego dla tabeli DIM_PRODUCT
IF EXISTS (SELECT * FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Czech.DIM_PRODUCT'))
BEGIN
    ALTER TABLE Czech.DIM_PRODUCT
    DROP CONSTRAINT PK_DIM_PRODUCT;
END

-- Dodanie nowego klucza podstawowego
ALTER TABLE Czech.DIM_PRODUCT
ADD CONSTRAINT PK_DIM_PRODUCT PRIMARY KEY (ProductID);

-- Sprawdzenie i usunięcie istniejącego klucza podstawowego dla tabeli DIM_CUSTOMER
IF EXISTS (SELECT * FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Czech.DIM_CUSTOMER'))
BEGIN
    ALTER TABLE Czech.DIM_CUSTOMER
    DROP CONSTRAINT PK_DIM_CUSTOMER;
END

-- Dodanie nowego klucza podstawowego
ALTER TABLE Czech.DIM_CUSTOMER
ADD CONSTRAINT PK_DIM_CUSTOMER PRIMARY KEY (CustomerID);

-- Sprawdzenie i usunięcie istniejącego klucza podstawowego dla tabeli DIM_SALESPERSON
IF EXISTS (SELECT * FROM sys.key_constraints WHERE type = 'PK' AND parent_object_id = OBJECT_ID('Czech.DIM_SALESPERSON'))
BEGIN
    ALTER TABLE Czech.DIM_SALESPERSON
    DROP CONSTRAINT PK_DIM_SALESPERSON;
END

-- Dodanie nowego klucza podstawowego
ALTER TABLE Czech.DIM_SALESPERSON
ADD CONSTRAINT PK_DIM_SALESPERSON PRIMARY KEY (SalesPersonID);



ALTER TABLE Czech.FACT_SALES
ADD CONSTRAINT FK_FACT_SALES_Product 
    FOREIGN KEY (ProductID) REFERENCES Czech.DIM_PRODUCT(ProductID) ON DELETE NO ACTION,
CONSTRAINT FK_FACT_SALES_Customer 
    FOREIGN KEY (CustomerID) REFERENCES Czech.DIM_CUSTOMER(CustomerID) ON DELETE SET NULL, -- Usunięcie klienta ustawia NULL w sprzedaży
CONSTRAINT FK_FACT_SALES_SalesPerson 
    FOREIGN KEY (SalesPersonID) REFERENCES Czech.DIM_SALESPERSON(SalesPersonID) ON DELETE SET NULL; -- Usunięcie sprzedawcy ustawia NULL


CREATE INDEX IDX_FACT_SALES_Product ON Czech.FACT_SALES(ProductID);
CREATE INDEX IDX_FACT_SALES_Customer ON Czech.FACT_SALES(CustomerID);
CREATE INDEX IDX_FACT_SALES_SalesPerson ON Czech.FACT_SALES(SalesPersonID);

ALTER TABLE Czech.FACT_SALES 
ADD CONSTRAINT CHK_FACT_SALES_ValidDates CHECK (ShipDate >= OrderDate);

ALTER TABLE Czech.DIM_PRODUCT 
ADD CONSTRAINT CHK_DIM_PRODUCT_ValidPrice CHECK (ListPrice >= 0);


--zadanie 3. lista 5
UPDATE Czech.DIM_PRODUCT
SET Color = 'Unknown'
WHERE Color IS NULL;

UPDATE Czech.DIM_PRODUCT
SET SubCategoryName = 'Unknown'
WHERE SubCategoryName IS NULL;

UPDATE Czech.DIM_CUSTOMER
SET CountryRegionCode = '000'
WHERE CountryRegionCode IS NULL;

UPDATE Czech.DIM_CUSTOMER
SET [Group] = 'Unknown'
WHERE [Group] IS NULL;