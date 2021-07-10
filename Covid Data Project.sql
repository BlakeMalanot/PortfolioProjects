select * from [Portfolio Project - Covid Deaths]..CovidDeaths$
order by 3, 4

-- select * from CovidVaccines$
-- order by 3, 4


-- Lets demonstrate some basic ability to query the data
-- Selct the data we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project - Covid Deaths]..CovidDeaths$
order by 1, 2


-- look at total deaths as a percentage of total cases

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from [Portfolio Project - Covid Deaths]..CovidDeaths$
--where location like '%Australia%'
order by 1, 2


-- Looking at total cases as a percentage of the population
select location, date, total_cases, population, (total_cases/population)*100 as cases_percentage
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where location like '%Australia%'
order by 1, 2

-- Look at total infection rate accross countries and sort in descending order
select location, population, max(total_cases) as Max_cases, max(total_cases/population*100) as percent_pop_infected
from [Portfolio Project - Covid Deaths]..CovidDeaths$
group by location, population
order by percent_pop_infected desc

-- Look at total death rate accross countries and sort in descending order
select location, population, max(cast(total_deaths as int)) as Max_deaths, max(total_deaths/population*100) as percent_pop_deceased
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where continent is not null
group by location, population
order by Max_deaths desc

-- CONTINENT NUMBERS

-- Look at total death rate accross continents and sort in descending order
select location, population, max(cast(total_deaths as int)) as Total_Death_Count, max(total_deaths/population*100) as percent_pop_deceased
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where continent is null
and location not in ('world', 'European Union', 'International')
group by location, population
order by Total_Death_Count desc

-- GLOBAL NUMBERS

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where continent is not null
--group by location
order by 1

-- JOIN TABLES
-- Lookings at total vaccinations vs population
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Portfolio Project - Covid Deaths]..CovidDeaths$ dea	
join [Portfolio Project - Covid Deaths]..CovidVaccines$ vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 2, 3


-- USE CTE

with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Portfolio Project - Covid Deaths]..CovidDeaths$ dea	
join [Portfolio Project - Covid Deaths]..CovidVaccines$ vac
	on dea.location = vac.location
	and dea.date = vac.date
--order by 2, 3
)
select *, (RollingPeopleVaccinated/population*100) as PercentageVaccinated
from PopVsVac
order by 2, 3


-- CREATE TEMP TABLE. Note: could not get this to work.

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Portfolio Project - Covid Deaths]..CovidDeaths$ dea	
join [Portfolio Project - Covid Deaths]..CovidVaccines$ vac
	on dea.location = vac.location
	and dea.date = vac.date

select *, (RollingPeopleVaccinated/population*100) as PercentageVaccinated
from #PercentPopulationVaccinated
--order by 2, 3

--	Vaccinations per country over time 
select location, date, people_vaccinated, people_vaccinated_per_hundred, people_fully_vaccinated, people_fully_vaccinated_per_hundred
from [Portfolio Project - Covid Deaths]..CovidVaccines$
order by 1, 2


--	Aggregate Vaccinations per country
select location, max(people_vaccinated) as people_vaccinated, max(people_vaccinated_per_hundred) as people_vaccinated_per_hundred
, max(people_fully_vaccinated) as people_fully_vaccinated, max(people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred
from [Portfolio Project - Covid Deaths]..CovidVaccines$
group by location
order by 1

-- create views for import into tableau

--	Percent of population vaccinated

--		Specify the database where we want the view to be created in:
use [Portfolio Project - Covid Deaths]
Go

--		Create the view:
create view PercentPopulationVaccinated as
with PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Portfolio Project - Covid Deaths]..CovidDeaths$ dea	
join [Portfolio Project - Covid Deaths]..CovidVaccines$ vac
	on dea.location = vac.location
	and dea.date = vac.date
--order by 2, 3
)
select *, (RollingPeopleVaccinated/population*100) as PercentageVaccinated
from PopVsVac
--order by 2, 3

create view Global_Mortality_Rate as
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where continent is not null
--group by location
--order by 1

create view Continent_Mortality_Rate as
select location, population, max(cast(total_deaths as int)) as Total_Death_Count, max(total_deaths/population*100) as percent_pop_deceased
from [Portfolio Project - Covid Deaths]..CovidDeaths$
where continent is null
and location not in ('world', 'European Union', 'International')
group by location, population
--order by Total_Death_Count desc

create view Country_Infection_Rate as
select location, population, max(total_cases) as Max_cases, max(total_cases/population*100) as percent_pop_infected
from [Portfolio Project - Covid Deaths]..CovidDeaths$
group by location, population
--order by percent_pop_infected desc

create view Country_Cases as
select location, date, total_cases, population, (total_cases/population)*100 as cases_percentage
from [Portfolio Project - Covid Deaths]..CovidDeaths$
--where location like '%Australia%'
--order by 1, 2

--	Vaccinations per country over time 
create view Vaccinations_over_time as
select location, date, population, convert(float, people_vaccinated) as people_vaccinated
, convert(float, people_vaccinated_per_hundred) as people_vaccinated_per_hundred 
, convert(float, people_fully_vaccinated) as people_fully_vaccinated
, convert(float, people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred
from [Portfolio Project - Covid Deaths]..CovidDeaths$
--order by 1, 2


--	Aggregate Vaccinations per country
create view Vaccinations_Aggregate as
select location, max(convert(float, people_vaccinated)) as people_vaccinated, max(convert(float, people_vaccinated_per_hundred)) as people_vaccinated_per_hundred
, max(convert(float, people_fully_vaccinated)) as people_fully_vaccinated, max(convert(float, people_fully_vaccinated_per_hundred)) as people_fully_vaccinated_per_hundred
from [Portfolio Project - Covid Deaths]..CovidVaccines$
group by location
--order by 1



--	 total percentage of population vaccinated by location with data obtained from the created view
--select location, max(PercentageVaccinated) as TotalPercentVaccinated from [Portfolio Project - Covid Deaths]..PercentPopulationVaccinated
--group by location
--order by 1





-- Lets open and copy the data (ctrl + shft + c) from our views to save as excel files to upload to Tableau Public:
select * from Global_Mortality_Rate

select * from Continent_Mortality_Rate

select * from Country_Infection_Rate
order by 4 desc

select * from Country_Cases
order by 1, 2

select * from PercentPopulationVaccinated
order by 2, 3

select * from Vaccinations_over_time
order by 1, 2

select * from Vaccinations_Aggregate
order by 1 desc
