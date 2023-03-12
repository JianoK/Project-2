USE PortfolioProject

Select *
From PortfolioProject..public_job_order_data

--Convert to General Date


Select DATEAPPROVED, CONVERT(date,DATEAPPROVED)
From PortfolioProject..public_job_order_data

Alter Table public_job_order_data
Add DateApproval date

Update public_job_order_data
Set DateApproval = CONVERT(date,DATEAPPROVED)

ALTER TABLE public_job_order_data
DROP COLUMN DATEAPPROVED;

--Convert ID to nvarchar
	-- Note: I tried to convert it directly to nvarchar but it is still the same as the ID so I proceed with this query;


Select ID,Cast(ID as dec(38,0))as IDNew
From public_job_order_data

Update public_job_order_data
Set IDNew = Cast(id as dec(38,0)) 

Select ID,IDnew,Convert(nvarchar(100),IDnew)ID_N
From public_job_order_data

Alter Table public_job_order_data
Add ID_N nvarchar(100)

Update public_job_order_data
Set ID_N = Convert(nvarchar(100),IDnew)

Alter Table public_job_order_data
Drop Column IDnew; 


-- Clearing Country Extension Name (except Czech Rep.)


Select Distinct(JOBSITE)
From public_job_order_data
Where JOBSITE Like '%Republic O%'

Select Distinct(JOBSITE),
Case
	When Jobsite ='CHINA PEOPLES REPUBLIC OF' Then 'CHINA'
	When Jobsite ='GERMANY REPUBLIC OF' Then 'GERMANY'
	When Jobsite ='DJIBOUTI REPUBLIC OF' Then 'DJIBOUTI'
	ELSE Jobsite 
	End 
From public_job_order_data
Where JOBSITE Like '%Republic O%'

Alter Table public_job_order_data
Add Jobsitenew varchar(100)

Update public_job_order_data
Set Jobsitenew = Case
	When Jobsite ='CHINA PEOPLES REPUBLIC OF' Then 'CHINA'
	When Jobsite ='GERMANY REPUBLIC OF' Then 'GERMANY'
	When Jobsite ='DJIBOUTI REPUBLIC OF' Then 'DJIBOUTI'
	ELSE Jobsite 
	End 

--Data Analysation


--Create a new Table then extract the cleaned data

Drop Table if exists Pub_Job_Ord_Dat

Create Table Pub_Job_Ord_Dat(
ID nvarchar(100),
JobTitle varchar (255),
Agency varchar (255),
CompanyName varchar (255),
Country varchar (255),
JobOffer int,
DateofPosting Date)

Insert into Pub_Job_Ord_Dat
Select ID_N,Position,Agency,PrincipalName,Jobsite,JObalance,DateApproval
From Public_Job_order_data

Select *
From Pub_Job_Ord_Dat


-- IF Created  as a TempTable then extract the cleaned data


----Drop Table if exists TempPub_Job_Ord_Dat
----Create Table #TempPub_Job_Ord_Dat(
----ID nvarchar(100),
----JobTitle varchar (255),
----Agency varchar (255),
----CompanyName varchar (255),
----Country varchar (255),
----JobOffer int,
----DateofPosting Date)

----Insert into #TempPub_Job_Ord_Dat
----Select ID_N,Position,Agency,PrincipalName,Jobsite,JObalance,DateApproval
----From Public_Job_order_data

----Select *
----From #TempPub_Job_Ord_Dat


--Create the Ranking of Agency with basis from MostJobOffer 

SELECT Agency, SUM(JobOffer) AS TotalJobOffer,
ROW_NUMBER() OVER (ORDER BY SUM(JobOffer) DESC) AS AgencyRank
FROM Pub_Job_Ord_Dat 
GROUP BY Agency
Order by TotalJobOffer DESC

--Create the Ranking of Agency with basis from AgencyFrequency 


Select Agency,COUNT(Agency) AgencyFre,
ROW_NUMBER() OVER (ORDER BY COUNT(Agency) DESC) AS AgencyRank
FROM  Pub_Job_Ord_Dat 
GROUP BY Agency
ORDER BY AgencyFre DESC


--Create the Agency over TotalJob Percentage 


With CTE_Agency AS
(
SELECT Agency, SUM(JobOffer) AS TotalJobOffer
FROM Pub_Job_Ord_Dat PJOD
GROUP BY Agency
)

Select CTEA.Agency, TotalJobOffer,(Cast((TotalJobOffer) as decimal (10,5))/210584)*100 AgencyJobPercent
FROM CTE_Agency CTEA
Full Outer Join Pub_Job_Ord_Dat PJOD
	On CTEA.Agency = PJOD.Agency
GROUP BY CTEA.Agency, TotalJobOffer
ORDER BY AgencyJobPercent DESC


--Create the Ranking of Country with basis from the TotalJobOffer and CountryFrequency 


With CTE_Country AS 
(
SELECT Country, SUM(JobOffer) AS TotalJobOffer,Count(Agency)CountryFre
FROM Pub_Job_Ord_Dat PJOD
GROUP BY Country
)

Select CTEC.Country, TotalJobOffer,CountryFre,(Cast((TotalJobOffer) as decimal (10,5))/210584)*100 CountryJobPercent,
ROW_NUMBER() OVER (ORDER BY COUNT(TotalJobOffer) DESC) AS CountryRank
FROM CTE_Country CTEC
Full Outer Join Pub_Job_Ord_Dat PJOD
	On CTEC.Country = PJOD.Country
GROUP BY CTEC.Country, TotalJobOffer,CountryFre
ORDER BY CountryRank,TotalJobOffer DESC


--Create the Country over TotalJob Percentage 

With CTE_Country AS 
(
SELECT Country, SUM(JobOffer) AS TotalJobOffer
FROM Pub_Job_Ord_Dat PJOD
GROUP BY Country
)

Select CTEC.Country, TotalJobOffer,(Cast((TotalJobOffer) as decimal (10,5))/210584)*100 CountryJobPercent
FROM CTE_Country CTEC
Full Outer Join Pub_Job_Ord_Dat PJOD
	On CTEC.Country = PJOD.Country
GROUP BY CTEC.Country, TotalJobOffer
ORDER BY CountryJobPercent DESC,TotalJobOffer 


--Create the Ranking of Company with basis from the TotalJobOffer and CountryFrequency 


With CTE_CompanyName AS 
(
SELECT CompanyName, SUM(JobOffer) AS TotalJobOffer,Count(CompanyName)CompanyFre
FROM Pub_Job_Ord_Dat PJOD
GROUP BY CompanyName
)

Select CTECN.CompanyName, TotalJobOffer,CompanyFre,
ROW_NUMBER() OVER (ORDER BY COUNT(TotalJobOffer) DESC) AS CompanyRank
FROM CTE_CompanyName CTECN
Full Outer Join Pub_Job_Ord_Dat PJOD
	On CTECN.CompanyName = PJOD.Country
GROUP BY CTECN.CompanyName, TotalJobOffer,CompanyFre
ORDER BY CompanyRank 


-- JobTitle Ranking for most TotalJobOffer 


WITH CTE_JobCount AS 
(
  SELECT JobTitle, COUNT(JobTitle) AS JobTitleFre,
  SUM(JobOffer) AS TotalJobOffer
  FROM Pub_Job_Ord_Dat
  GROUP BY JobTitle
)

SELECT CTEJC.JobTitle,TotalJobOffer,JobTitleFre,
	ROW_NUMBER() OVER (ORDER BY TotalJobOffer DESC) JobTitleRank
FROM CTE_JobCount CTEJC
FULL OUTER JOIN Pub_Job_Ord_Dat PJOD
ON CTEJC.JobTitle = PJOD.JobTitle
GROUP BY CTEJC.JobTitle, TotalJobOffer, JobTitleFre
ORDER BY TotalJobOffer DESC, JobTitleRank
