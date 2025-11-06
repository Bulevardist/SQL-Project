--Proiect 



--1.Total vanzari si profit pe categorii de produse(Pe toti anii) 

      select pc.ProductCategoryID,
	         pc.[Name],
			 SUM(soh.TotalDue) as TotalSales,
			 SUM(sod.LineTotal-p.StandardCost*sod.OrderQty) as LineProfit
 from Sales.SalesOrderDetail sod
	 join Sales.SalesOrderHeader soh
	 on sod.SalesOrderID= soh.SalesOrderID
	 join Production.Product p
	 on p.ProductID= sod.ProductID
	 join Production.ProductSubcategory ps
	 on p.ProductSubcategoryID= ps.ProductSubcategoryID
	 join Production.ProductCategory pc
	 on pc.ProductCategoryID= ps.ProductCategoryID
	 group by pc.ProductCategoryID,pc.[Name]
	 order by ProductCategoryID asc







create procedure TotalSalesAndProfit
as
begin
select pc.ProductCategoryID,
	         pc.[Name],
			 SUM(soh.TotalDue) as TotalSales,
			 SUM(sod.LineTotal-p.StandardCost*sod.OrderQty) as LineProfit
 from Sales.SalesOrderDetail sod
	 join Sales.SalesOrderHeader soh
	 on sod.SalesOrderID= soh.SalesOrderID
	 join Production.Product p
	 on p.ProductID= sod.ProductID
	 join Production.ProductSubcategory ps
	 on p.ProductSubcategoryID= ps.ProductSubcategoryID
	 join Production.ProductCategory pc
	 on pc.ProductCategoryID= ps.ProductCategoryID
	 group by pc.ProductCategoryID,pc.[Name]
	 order by ProductCategoryID asc
end


exec TotalSalesAndProfit




--2.Vanzare produse pe regiuni

 select cr.[Name] as CountryName, 
        pc.ProductCategoryID,
		 pc.[Name] as CategoryName ,
		 COUNT(distinct soh.SalesOrderID) as TotalOrders,
		 SUM(soh.TotalDue) as TotalSales,
		 SUM(sod.LineTotal-p.StandardCost*sod.OrderQty) as LineProfit
		 from Sales.SalesOrderDetail sod 
  join Sales.SalesOrderHeader soh
  on sod.SalesOrderID= soh.SalesOrderID
  join Production.Product p
  on sod.ProductID=p.ProductID
  join Production.ProductSubcategory ps
  on p.ProductSubcategoryID= ps.ProductSubcategoryID
  join Production.ProductCategory pc
  on ps.ProductCategoryID= pc.ProductCategoryID
  join Sales.SalesTerritory st
  on soh.TerritoryID= st.TerritoryID 
  join Person.CountryRegion cr
  on st.CountryRegionCode= cr.CountryRegionCode
  group by  cr.[Name],pc.ProductCategoryID,pc.[Name]
  order by pc.ProductCategoryID


create procedure SalesPerRegion 
@ProductCategoryID int
as
begin
 select cr.[Name] as CountryName, 
        pc.ProductCategoryID,
		 pc.[NAME] as CategoryName ,
		 COUNT(distinct soh.SalesOrderID) as TotalOrders,
		 SUM(soh.TotalDue) as TotalSales,
		 SUM(sod.LineTotal-p.StandardCost*sod.OrderQty) as LineProfit
		 from Sales.SalesOrderDetail sod 
  join Sales.SalesOrderHeader soh
  on sod.SalesOrderID= soh.SalesOrderID
  join Production.Product p
  on sod.ProductID=p.ProductID
  join Production.ProductSubcategory ps
  on p.ProductSubcategoryID= ps.ProductSubcategoryID
  join Production.ProductCategory pc
  on ps.ProductCategoryID= pc.ProductCategoryID
  join Sales.SalesTerritory st
  on soh.TerritoryID= st.TerritoryID 
  join Person.CountryRegion cr
  on st.CountryRegionCode= cr.CountryRegionCode
  where pc.ProductCategoryID = @ProductCategoryID
  group by  cr.[Name],pc.ProductCategoryID,pc.[Name]
  order by pc.ProductCategoryID
 end

exec SalesPerRegion 4




  --3.Performanta Angajati

	select p.BusinessEntityID,
		   dbo.fnFullName(p.BusinessEntityID) as SalesPersonName,
		   e.JobTitle,
		   COUNT(distinct soh.SalesOrderID) as TotalOrders,
		   SUM(soh.TotalDue) as TotalSales		   
	from Sales.SalesOrderHeader soh
	join Sales.SalesPerson sp
	on sp.BusinessEntityID=soh.SalesPersonID
	join HumanResources.Employee e
	on e.BusinessEntityID= sp.BusinessEntityID
	join Person.Person p
	on p.BusinessEntityID= e.BusinessEntityID
	join Sales.SalesOrderDetail sod
	on soh.SalesOrderID = sod.SalesOrderID
	group by p.BusinessEntityID, p.FirstName,p.LastName,e.JobTitle
	order by TotalSales desc



create function fnFullName (@BusinessEntityID INT)
returns varchar(30)
as
begin
declare @NumePrenume varchar(30)
select @NumePrenume = FirstName + ' ' + LastName
from Person.Person 
where BusinessEntityID = @BusinessEntityID
return @NumePrenume
end








--3.1.Ce persoana a vandut cel mai bine fiecare categorie de produse la nivel mondial

		with SalesByEmployeeAndCategory as (
			select 
				p.BusinessEntityID,
				p.FirstName + ' ' + p.LastName AS SalesPersonName,
				e.JobTitle,
				pc.[Name] AS ProductCategory,
				SUM(sod.LineTotal) AS TotalSales
			from Sales.SalesOrderHeader soh
			join Sales.SalesPerson sp 
			on sp.BusinessEntityID = soh.SalesPersonID
			join HumanResources.Employee e 
			on e.BusinessEntityID = sp.BusinessEntityID
			join Person.Person p 
			on p.BusinessEntityID = e.BusinessEntityID
			join Sales.SalesOrderDetail sod 
			on sod.SalesOrderID = soh.SalesOrderID
			join Production.Product pr 
			on sod.ProductID = pr.ProductID
			join Production.ProductSubcategory ps 
			on pr.ProductSubcategoryID = ps.ProductSubcategoryID
			join Production.ProductCategory pc 
			on ps.ProductCategoryID = pc.ProductCategoryID
			group by p.BusinessEntityID, p.FirstName, p.LastName, e.JobTitle, pc.[Name]
		),
		TopSellerByCategory as (
			select *,
				   RANK() OVER (partition by ProductCategory order by TotalSales desc) as BestEmployee
			from SalesByEmployeeAndCategory
		)
		select
			ProductCategory,
			SalesPersonName,
			JobTitle,
			TotalSales
		from TopSellerByCategory
		where BestEmployee = 1
		order by ProductCategory;




--4.Statistica pe anotimp

create procedure SeasonSales
@Season varchar(10)
as
begin
select pc.ProductCategoryID,
	         pc.[Name],
			 SUM(soh.TotalDue) as TotalSales,
			 case
					when MONTH(soh.OrderDate) in (12,1,2) then 'Winter'
					when MONTH(soh.OrderDate) in (3,4,5) then 'Spring'
					when MONTH(soh.OrderDate) in (6,7,8) then 'Summer'
					else 'Autumn'
					end as Seasons
 from Sales.SalesOrderDetail sod
	 join Sales.SalesOrderHeader soh
	 on sod.SalesOrderID= soh.SalesOrderID
	 join Production.Product p
	 on p.ProductID= sod.ProductID
	 join Production.ProductSubcategory ps
	 on p.ProductSubcategoryID= ps.ProductSubcategoryID
	 join Production.ProductCategory pc
	 on pc.ProductCategoryID= ps.ProductCategoryID
	 group by pc.ProductCategoryID,pc.[Name],
	 case
					when MONTH(soh.OrderDate) in (12,1,2) then 'Winter'
					when MONTH(soh.OrderDate) in (3,4,5) then 'Spring'
					when MONTH(soh.OrderDate) in (6,7,8) then 'Summer'
					else 'Autumn'
					end
      having case
					when MONTH(soh.OrderDate) in (12,1,2) then 'Winter'
					when MONTH(soh.OrderDate) in (3,4,5) then 'Spring'
					when MONTH(soh.OrderDate) in (6,7,8) then 'Summer'
					else 'Autumn'
					end=@Season
	 order by ProductCategoryID asc, TotalSales desc
end


exec SeasonSales 'Autumn'


 select pc.ProductCategoryID,
	         pc.[Name],
			 SUM(soh.TotalDue) as TotalSales,
			 case
					when MONTH(soh.OrderDate) in (12,1,2) then 'Winter'
					when MONTH(soh.OrderDate) in (3,4,5) then 'Spring'
					when MONTH(soh.OrderDate) in (6,7,8) then 'Summer'
					else 'Autumn'
					end as Seasons
 from Sales.SalesOrderDetail sod
	 join Sales.SalesOrderHeader soh
	 on sod.SalesOrderID= soh.SalesOrderID
	 join Production.Product p
	 on p.ProductID= sod.ProductID
	 join Production.ProductSubcategory ps
	 on p.ProductSubcategoryID= ps.ProductSubcategoryID
	 join Production.ProductCategory pc
	 on pc.ProductCategoryID= ps.ProductCategoryID
	 group by pc.ProductCategoryID,pc.[Name],
	 case
					when MONTH(soh.OrderDate) in (12,1,2) then 'Winter'
					when MONTH(soh.OrderDate) in (3,4,5) then 'Spring'
					when MONTH(soh.OrderDate) in (6,7,8) then 'Summer'
					else 'Autumn'
					end
	 order by ProductCategoryID asc, TotalSales desc
	 


--5. Rata de vanzare a fiecarui produs per luna

	   
	   WITH ProductOrderFrequency AS (
    SELECT 
        sod.ProductID,
        p.[Name] as ProductName,
		pc.[Name] as CategoryName,
        COUNT(*) as TotalOrders,
        MIN(soh.OrderDate) as FirstOrderDate,
        MAX(soh.OrderDate) as LastOrderDate,
		SUM(soh.TotalDue) as TotalSales
    from 
        Sales.SalesOrderDetail sod
    join 
        Production.Product p 
		on sod.ProductID = p.ProductID
    join 
        Sales.SalesOrderHeader soh 
		on sod.SalesOrderID = soh.SalesOrderID
	join Production.ProductSubcategory ps
		on p.ProductSubcategoryID= ps.ProductSubcategoryID
	join Production.ProductCategory pc
	 on pc.ProductCategoryID= ps.ProductCategoryID
   group by 
        sod.ProductID, p.[Name], pc.[Name]
)
SELECT TOP 10 
    ProductID,
    ProductName,
	CategoryName,
    TotalOrders,
    DATEDIFF(MONTH, FirstOrderDate, LastOrderDate) + 1 AS MonthsOnSale,
	TotalSales/(TotalOrders / (DATEDIFF(MONTH, FirstOrderDate, LastOrderDate) + 1)) as TotalSalesPerMonth,
	TotalOrders / (DATEDIFF(MONTH, FirstOrderDate, LastOrderDate) + 1) AS AvgOrdersPerMonth

FROM 
    ProductOrderFrequency
ORDER BY 
    AvgOrdersPerMonth DESC;



	  
	  select * from Sales.SalesOrderHeader