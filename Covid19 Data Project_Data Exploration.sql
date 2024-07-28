
--DATA EXPLORATION OF COVID19 DATA SET

/*
Covid 19 Data Exploration Project

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
	SELECT *
	FROM ProjectPortfolio..CovidDeathsData
	;

	SELECT *
	FROM ProjectPortfolio..CovidVaccinationData
	;

	--split the large dataset into CovidDeaths dataset and Covid Vaccination dataset
	--Download the the dataset [https://ourworldindata.org/covid-deaths]
	--Download the dataset of covid vaccinations dataset [https://tinyurl.com/5yryh9e8]
	--Download dataset for covid deaths dataset [https://tinyurl.com/nhhz63rn]

	
	-- from CovidDeaths dataset lets return columns of interest

SELECT
	location, 
	date, 
	total_cases,   
	new_cases, 
	total_deaths, 
	population 
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL
ORDER BY 1, 2
;




-- total cases vs total deaths = Percentage Death
-- it return the likelihood of one dying after contracting covid19 taking UK and US as case study


	-- looking for propability of dying after contracting covid in the US

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
    (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeathsData
WHERE location LIKE '%United Kingdom%'
ORDER BY 
    location, 
    date;





	-- looking for propability of dying after contracting covid in the US

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
    (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS DeathPercentage
FROM ProjectPortfolio..CovidDeathsData
WHERE location LIKE '%states%' AND continent IS NOT NULL 
ORDER BY 
    location, 
    date;


-- Looking at total cases vs population
-- show population that got covid

SELECT
	location, 
	date, 
	total_cases, 
	population,
	(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT)) * 100 AS PercentPopulationInfected
FROM ProjectPortfolio..CovidDeathsData
ORDER BY 1, 2
;




-- looking at country with highest infection rate compared to population

SELECT
	Location, 
	Population, 
		MAX(total_cases) AS HighestInfectionCount,
		MAX((CAST(total_cases AS FLOAT)/CAST(population AS FLOAT)) * 100) AS MaxPercentPopulationInfected
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestInfectionCount DESC
;




-- DRILL DOWN TO CONTINENTS
-- Showing countries with highes death count

SELECT 
	Location, 
		Max(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathsCount DESC
;




--removing non contient values 

SELECT 
	location, 
		Max(CAST(total_deaths AS INT)) AS ContinentTotalDeathsCount
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NULL AND location NOT IN ('High income', 'Low income', -- filter non countries from the list
		'Upper middle income', 'Lower middle income', 'World')
GROUP BY location
ORDER BY ContinentTotalDeathsCount DESC
;



--Showing the continenet with highest death count  per population

SELECT 
	continent, 
		Max(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathsCount DESC
;




--LETS EXPLORE THE GLOBAL NUMBER
-- looking at global total number of recent deaths vs new cases


SELECT 
	SUM(new_cases) AS total_new_cases,
	SUM(new_deaths) AS total_new_deaths,
	(SUM(new_deaths)/SUM(new_cases))*100 AS DeathsPercentage
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL
ORDER BY 1, 2
;




-- to avoid divisible error in the future we add logic to control the new data

SELECT 
	date, 
		SUM(CAST(new_cases AS INT)) AS total_new_cases, 
		SUM(new_deaths) AS total_new_deaths, 
		CASE
			WHEN SUM(CAST(new_cases AS INT))  > 0 THEN (SUM(new_deaths)/SUM(new_cases))*100
			ELSE NULL
		END AS DeathPercentage
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY  DeathPercentage
;




-- FROM COVID VACCINATION TABLE 
-- Looking at Total Population vs Vaccination, we join the both table together 


SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.date) AS rollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeathsData cd
JOIN ProjectPortfolio..CovidVaccinationData cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--AND cd.location like '%canada%'
ORDER BY cd.location, cd.date;




-- USE CTE

WITH PopvsVac (
	Continent, 
	Location, 
	Date, 
	Population, 
	New_vaccinations,  rollingPeopleVaccinated) AS
(SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.date) AS rollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeathsData cd
JOIN ProjectPortfolio..CovidVaccinationData cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
) 
SELECT *, (rollingPeopleVaccinated / Population) * 100 AS PercentagePopulationVac 
FROM PopvsVac
;





-- looking for percentage vacinted for individual countries let take 'Andorra' as case study

WITH PopvsVac (
	Continent, 
	Location, 
	Date, 
	Population, 
	New_vaccinations,  rollingPeopleVaccinated) AS
(SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.date) AS rollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeathsData cd
JOIN ProjectPortfolio..CovidVaccinationData cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL 
	AND cd.location LIKE 'Andorra'
) 
SELECT *, (rollingPeopleVaccinated / Population) * 100 AS PercentagePopulationVac 
FROM PopvsVac
;





--rename the table for more advance calculation
--Creat CTE2

WITH PeopleVaccinated_CTE AS (
    SELECT 
        cd.continent, 
        cd.location, 
        cd.date, 
        cd.population, 
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS BIGINT)) OVER(PARTITION BY cd.location ORDER BY cd.date) AS RollingPeopleVaccinated
    FROM ProjectPortfolio..CovidDeathsData cd
    JOIN ProjectPortfolio..CovidVaccinationData cv
        ON cd.location = cv.location
        AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL 
      --AND cd.location LIKE '%United States%'
    GROUP BY 
        cd.continent,
        cd.location,
        cd.date,
        cd.population,
        cv.new_vaccinations
)
SELECT
    Continent, 
    Location, 
    Date, 
    Population, 
    New_vaccinations,
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated/population) * 100 AS PercentageVac
	FROM PeopleVaccinated_CTE
ORDER BY 
    location, 
    date
;





	-- to avoid Null/zero divisible error for feature  data update 
--CREATE CTE3

	WITH PopvsVac_CTE AS (
    SELECT 
        cd.continent, 
        cd.location, 
        cd.date, 
        cd.population, 
        cv.new_vaccinations,
        SUM(CAST(cv.new_vaccinations AS FLOAT)) 
        OVER(PARTITION BY cd.location
             ORDER BY cd.date) AS rollingPeopleVaccinated  -- Removed cd.location from ORDER BY
    FROM ProjectPortfolio..CovidDeathsData cd
    JOIN ProjectPortfolio..CovidVaccinationData cv
        ON cd.location = cv.location
        AND cd.date = cv.date
    WHERE cd.continent IS NOT NULL 
)
SELECT 
    continent, 
    location, 
    date, 
    population, 
    rollingPeopleVaccinated,
    CASE 
        WHEN population > 0 AND rollingPeopleVaccinated <= population THEN (rollingPeopleVaccinated / population) * 100 
        ELSE NULL
    END AS percentageVaccinated
FROM PopvsVac_CTE
WHERE population > 0
ORDER BY location, date
;





-- TEMP TABLE
-- lets create temporatry table from CTE1

DROP TABLE IF EXISTS PercentagePopulationVaccinated;
CREATE TABLE PercentagePopulationVaccinated (
	continent NVARCHAR (255),
	location NVARCHAR (255),
	date DATETIME ,
	population NUMERIC, 
	new_vaccinations NUMERIC,
	rollingPeopleVaccinated NUMERIC
	)
											
INSERT INTO PercentagePopulationVaccinated 
SELECT  
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.date) AS rollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeathsData cd
JOIN ProjectPortfolio..CovidVaccinationData cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY cd.location, cd.date

SELECT *, (rollingPeopleVaccinated / Population) * 100  AS PercentagePeopleVac
FROM PercentagePopulationVaccinated 
;




-- LETS CREATE FOR FOR VISUALISATIONS 
--creating view for percentage of peeople vaccinated by countries 
DROP VIEW dbo.PercentagePopulationVaccinated_View; 
CREATE VIEW dbo.PercentagePopulationVaccinated_View AS 
SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS FLOAT)) 
    OVER (PARTITION BY cd.location ORDER BY cd.date) AS rollingPeopleVaccinated
FROM ProjectPortfolio..CovidDeathsData cd
JOIN ProjectPortfolio..CovidVaccinationData cv
    ON cd.location = cv.location
    AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
;

SELECT *
FROM dbo.PercentagePopulationVaccinated_View
; 




	
-- creating view for new total deaths counts due to new cases by countries 

DROP VIEW dbo.ContinentTotalDeathsCount;
CREATE VIEW dbo.ContinentTotalDeathsCount AS
SELECT 
	location, 
		Max(CAST(total_deaths AS INT)) AS ContinentTotalDeathsCount
FROM ProjectPortfolio..CovidDeathsData
WHERE continent IS NULL AND location NOT IN ('High income', 'Low income', -- filter non countries from the list
		'Upper middle income', 'Lower middle income', 'World')
GROUP BY location
;



SELECT *
FROM.ContinentTotalDeathsCount

--Checkout my Tableau projects for data visualisation of the analysis.








	