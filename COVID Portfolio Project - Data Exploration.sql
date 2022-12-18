/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select Data that we are going to be starting with

Select Location, date , total_cases, new_cases, total_deaths, population
From CovidDeaths
order by 1,2

-- Country Wise Population
select location, max(Population) Population from covidDeaths
group by location
order by Population desc

--Total Cases
select sum(new_cases) Total_Cases from CovidDeaths

--Total Deaths
select sum(cast(new_Deaths as bigint)) Total_Deaths from CovidDeaths

--Total Test Taken by Each Country
select location, sum(cast(new_tests as bigint)) Total_Test from CovidVaccinations
group by location
order by Total_Test desc

-- Total Vaccination Drive by Each Country
select location, sum(cast(new_vaccinations as bigint)) Total_Vaccinated from CovidVaccinations
group by location
order by Total_Vaccinated desc

--Total Boosters Dose by Each Country
select location,  max(cast(Total_boosters as bigint)) Total_Booster_Dose from CovidVaccinations
group by location
order by Total_Booster_Dose desc

-- Total ICU Patients by Each Country
select distinct(location), sum(cast(icu_patients as bigint)) Total_ICU_Patient from CovidDeaths where icu_patients is not null
group by location
order by Total_ICU_Patient desc

Select *
from CovidDeaths
order by 3,4

select * 
from Covidvaccinations
order by 3,4


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, Date, total_cases, total_deaths, Round((total_deaths/total_cases),4)*100 as DeathPercentage
From CovidDeaths
Where location like '%India%'
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  Round((total_cases/population),4)*100 as PercentPopulationInfected
From CovidDeaths
Where location like '%India%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Round(Max((total_cases/population)),4)*100 as PercentPopulationInfected
From CovidDeaths
--Where location like '%India%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%India%'
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, Sum(cast(New_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%India%'
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	   SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
--Where location like '%India%'
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Inner Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, vac.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Inner Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
)
select *
from PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population Bigint,
New_vaccinations Bigint,
RollingPeopleVaccinated Bigint
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
where New_vaccinations is not null
order by 2,3



-- Creating View to store data for later visualizations

Create or alter View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Inner Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

select *, round((rollingpeopleVaccinated/Population),4)*100 PercentPeopleVaccinated from PercentPopulationVaccinated
where new_vaccinations is not null 
order by 2,3
