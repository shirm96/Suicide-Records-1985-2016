USE Sucide

--Cheking at all the null values
SELECT SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_country',
		SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_year',
		SUM(CASE WHEN sex IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_sex',
		SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_age',
		SUM(CASE WHEN suicides_no IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_suicides_no',
		SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_population',
		SUM(CASE WHEN suicides_100k_pop IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_suicides_100k_pop',
		SUM(CASE WHEN HDI_for_year IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_HDI_for_year',
		SUM(CASE WHEN gdp_for_year IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_ gdp_for_year',
		SUM(CASE WHEN gdp_per_capita IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_gdp_per_capita',
		SUM(CASE WHEN generation IS NULL THEN 1 ELSE 0 END) AS 'Sum_null_generation'
FROM suicide_records

--deleting unnecessary column such as country_year and coulmn with too many null values - HDI for year
ALTER TABLE suicide_records
DROP COLUMN country_year;

ALTER TABLE suicide_records
DROP COLUMN HDI_for_year;

--Looking at the age and gender distribution
SELECT sex, COUNT(*)  AS num_of_ppl
FROM suicide_records
GROUP BY sex

SELECT age, COUNT(*)  AS num_of_ppl
FROM suicide_records
GROUP BY age


--Looking at the missing data, checking which years we have their recordes from each country
SELECT country,
	CASE WHEN (2017-1985)-(COUNT(DISTINCT year)) =0  THEN 'Non_missing'
		WHEN (2017-1985)-(COUNT(DISTINCT year)) BETWEEN 1 AND 5  THEN 'Under_5_missing'
		WHEN (2017-1985)-(COUNT(DISTINCT year)) BETWEEN 6 AND 10  THEN 'Under_10_missing'
		WHEN (2017-1985)-(COUNT(DISTINCT year)) BETWEEN 11 AND 15  THEN 'Under_15_missing'
		WHEN (2017-1985)-(COUNT(DISTINCT year)) BETWEEN 16 AND 20  THEN 'Under_20_missing'
		ELSE 'Over_20_missing'
		END AS 'Years_without_record'
FROM suicide_records
GROUP BY country
ORDER BY Years_without_record

--Looking how many countries we don't have their data in each continent
SELECT  CC.continent,
		 COUNT(DISTINCT su.country) AS 'num_countries_in_data',
		 COUNT(DISTINCT cc.country) AS 'num_countries_generaly'
FROM suicide_records su
RIGHT JOIN countryContinent cc
	ON cc.country=SU.country
GROUP BY CC.continent
-- We can see we have very little information about Africa and countries in Oceania

-- The average of suicides per 100k people, and general number of suiside per year by country and year
SELECT  country,
		year ,
		AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K', 
		SUM(suicides_no) AS 'Total_Num_of_suicides'
FROM suicide_records
GROUP BY country, year
ORDER BY year, Num_of_suicides_per_100K DESC


-- The average of suicides per 100k people, and general number of suiside per year by Continent and the total for the all years
;WITH Continent_count AS
	(
		SELECT CC.continent,
				su.year,
				AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K',
				SUM(suicides_no) AS 'Total_Num_of_suicides',
				AVG(AVG(suicides_100k_pop)) OVER (PARTITION BY CC.continent )AS 'Continent_suicides_per_100K_overall',
				SUM(SUM(suicides_no))  OVER (PARTITION BY CC.continent ) AS 'Total_suicides_Overall'
		FROM suicide_records su
		LEFT JOIN countryContinent cc
			ON cc.country=SU.country
		WHERE CC.continent NOT IN ('Africa','Oceania')
		GROUP BY CC.continent, su.year
	)
SELECT *, DENSE_RANK() OVER(PARTITION BY year ORDER BY Num_of_suicides_per_100K DESC) AS Drank
FROM Continent_count

-- looking for a different in the suicide rate between the generations

SELECT  Generation,
		AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K',
		SUM(suicides_no) AS 'Total_Num_of_suicides',
		DENSE_RANK() OVER(ORDER BY AVG(suicides_100k_pop*1.0) DESC) AS Drank
FROM suicide_records 
GROUP BY Generation


-- looking for a different in the suicide rate between the age groups

SELECT  age,
		AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K',
		SUM(suicides_no) AS 'Total_Num_of_suicides',
		DENSE_RANK() OVER(ORDER BY AVG(suicides_100k_pop*1.0) DESC) AS Drank
FROM suicide_records 
GROUP BY age

-- looking for a different in the suicide rate between the sex

SELECT  sex,
		AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K',
		SUM(suicides_no) AS 'Total_Num_of_suicides',
		DENSE_RANK() OVER(ORDER BY AVG(suicides_100k_pop*1.0) DESC) AS Drank
FROM suicide_records 
GROUP BY sex

-- looking for a different in the suicide rate between the years and filtering the years with a data of less than 60 countries

SELECT  year,
		AVG(suicides_100k_pop*1.0) AS 'Num_of_suicides_per_100K',
		SUM(suicides_no) AS 'Total_Num_of_suicides',
		DENSE_RANK() OVER(ORDER BY AVG(suicides_100k_pop*1.0) DESC) AS Drank
FROM suicide_records 
GROUP BY year
HAVING COUNT(DISTINCT country)>60


-- looking for a different in the suicide rate between the gdp per capita level

;WITH gdp_group_capita AS
	(
		SELECT *, CASE WHEN gdp_per_capita <=10000 THEN 'Less_then_10K'
					WHEN gdp_per_capita BETWEEN 10001 AND 20000 THEN '10K-20K'
					WHEN gdp_per_capita BETWEEN 20001 AND 30000 THEN '20K-30K'
					WHEN gdp_per_capita BETWEEN 30001 AND 40000 THEN '30K-40K'
					WHEN gdp_per_capita BETWEEN 40001 AND 50000 THEN '40K-50K'
					WHEN gdp_per_capita BETWEEN 50001 AND 60000 THEN '50K-60K'
					WHEN gdp_per_capita BETWEEN 60001 AND 70000 THEN '60K-70K'
					WHEN gdp_per_capita BETWEEN 70001 AND 80000 THEN '70K-80K'
					WHEN gdp_per_capita BETWEEN 80001 AND 90000 THEN '80K-90K'
					WHEN gdp_per_capita BETWEEN 90001 AND 100000 THEN '90K-100K'
					ELSE '100K+'
					END AS gdp_per_capita_level
		FROM suicide_records
	)
SELECT gdp_per_capita_level,
		AVG(suicides_100k_pop) AS 'AVG_suicides_100k_pop',
		DENSE_RANK() OVER(ORDER BY AVG(suicides_100k_pop) DESC ) AS 'DRANK'
FROM gdp_group_capita
GROUP BY gdp_per_capita_level



-- looking for a diffrent by the suicide rate between the gdp per year level


;WITH gdp_group AS
	(
		SELECT *, CASE WHEN gdp_for_year <=100000000 THEN 'Less_then_100M'
					WHEN gdp_for_year BETWEEN 100000001 AND 1000000000 THEN '100M-1KM'
					WHEN gdp_for_year BETWEEN 1000000001 AND 1000000000 THEN '1KM-10KM'
					WHEN gdp_for_year BETWEEN 1000000001 AND 10000000000 THEN '10KM-100KM'
					WHEN gdp_for_year BETWEEN 10000000001 AND 100000000000 THEN '100KM-1000KM'
					ELSE '1000KM+'
					END AS gdp_for_year_level
		FROM suicide_records
	)
SELECT gdp_for_year_level,
		AVG(suicides_100k_pop) AS 'AVG_suicides_100k_pop'
FROM gdp_group
GROUP BY gdp_for_year_level


--PIVOT to see the age and sex connection with suicideds per 100K
SELECT *  
FROM   (SELECT sex, age, suicides_100k_pop FROM suicide_records) AS TBL 
PIVOT  (AVG(suicides_100k_pop) FOR sex IN ([Female],[Male])) AS PVT 