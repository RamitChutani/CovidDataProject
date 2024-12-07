-- checking tables imported correctly

SELECT *
FROM CovidProject..CovidDeaths
order by 3, 4

SELECT *
FROM CovidProject..CovidVaccinations
order by 3, 4


-- selecting relevant data columns

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
order by 1, 2


-- comparing Total Cases & Total Deaths
-- calculating Deaths as percentage of Total Cases 
-- querying various conditions

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM CovidProject..CovidDeaths
WHERE location = 'india'
AND total_deaths IS NOT NULL
AND total_cases > 10000
AND date > '2021-01-01'
order by 5 desc


-- comparing Total Cases & Population
-- calulating Cases as percentage of Population (Infection Rate)

SELECT location, date, total_cases, population, (total_cases/population)*100 as infection_rate
FROM CovidProject..CovidDeaths
-- WHERE location = 'india'
-- AND (total_cases/population)*100 > 1
order by 1,2


-- querying to find Countries with Highest Infection Rate (the max of each country will be reached on different dates, this is a comparision of each country's peak)

SELECT location, population, MAX(total_cases) as peak_infected, MAX((total_cases/population)*100) as peak_infection_rate
FROM CovidProject..CovidDeaths
group by location, population
order by 4 desc


-- querying to find Countries with Highest Death rate
-- realized that total_deaths is nvarchar(255) because ordering was messed up
-- filtering out continents and grouping of countries

SELECT location, population, MAX(cast(total_deaths as int)) as peak_deaths
FROM CovidProject..CovidDeaths
WHERE continent is not null
group by location, population
order by peak_deaths desc


-- breakdown by contintent

SELECT location, population, MAX(cast(total_deaths as int)) as peak_deaths
FROM CovidProject..CovidDeaths
WHERE continent is null
group by location, population
order by peak_deaths desc


-- global calculations by date

SELECT /*date,*/ SUM(new_cases) as total_cases_calc, SUM(cast(new_deaths as int)) as total_deats_calc, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deaths_percentage
FROM CovidProject..CovidDeaths
WHERE continent is not null
-- group by date
order by 1,2


-- joining CovidDeaths and CovidVaccinations tables

SELECT * 
FROM CovidProject..CovidDeaths as d
JOIN CovidProject..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
ORDER BY d.location, d.date


-- comparing Total Population and Vaccinations
-- calculating moving sum of vaccinations per location
-- window functions cannot be referenced as part of calculation

SELECT d.continent,	d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as rolling_vaccination_count--, (rolling_vaccination_count/population)*100 as rolling_vaccinated_percentage
FROM CovidProject..CovidDeaths as d
JOIN CovidProject..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- using Subquery

SELECT *, (rolling_vaccination_count/population)*100 as rolling_vaccinated_percentage
FROM (
	SELECT d.continent,	d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as rolling_vaccination_count
	FROM CovidProject..CovidDeaths as d
	JOIN CovidProject..CovidVaccinations as v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent IS NOT NULL
) AS subquery
ORDER BY 2,3


-- using CTE (Common Table Expression)

WITH cte /*(continent, location, date, population, new_vaccinations, rolling_vannination_count)*/ AS (
	SELECT d.continent,	d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as rolling_vaccination_count
	FROM CovidProject..CovidDeaths as d
	JOIN CovidProject..CovidVaccinations as v
		ON d.location = v.location
		AND d.date = v.date
		WHERE d.continent IS NOT NULL
)
SELECT *, (rolling_vaccination_count/population)*100 as rolling_vaccinated_percentage
FROM cte
ORDER BY 2,3


-- using Temp Table

DROP TABLE if exists #RollingVaccinatedPercent -- in case we make edits to table later
CREATE TABLE #RollingVaccinatedPercent 
(
contintent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination_count numeric
)

INSERT INTO #RollingVaccinatedPercent
SELECT d.continent,	d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as rolling_vaccination_count
FROM CovidProject..CovidDeaths as d
JOIN CovidProject..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (rolling_vaccination_count/population)*100 as rolling_vaccinated_percentage
FROM #RollingVaccinatedPercent


-- creating View (permanent table) to store data for visualizations

CREATE VIEW RollingVaccinatedPercent AS
SELECT d.continent,	d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as rolling_vaccination_count
FROM CovidProject..CovidDeaths as d
JOIN CovidProject..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *
FROM RollingVaccinatedPercent