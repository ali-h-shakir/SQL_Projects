/* TITLE: Number of Medical Doctors Analysis
   DATA FILE: doctors_data.csv
   CONCEPTS USED: 
	Aggregation Functions
	Window Functions
	Case Statements
	Group By Functions
	Virtual Tables
*/

--- 1: Selecting all columns to review the file.
SELECT
  *
FROM
  medical_doctors.doctors_data
LIMIT
  1000

--- 2: AGGREGATION FUNCTIONS - Generated a table for total number of medical doctors by country for 2020 sorted in descending manner using Aggregate Functions. Insight obtained that China had the most number of doctors in 2020, followed by US. 

SELECT
  Countries__territories_and_areas,
  Year,
  SUM(Medical_doctors__number_) AS Total_Doctors,
  SUM(Generalist_medical_practitioners__number_) AS GPs,
  SUM(Specialist_medical_practitioners__number_) AS Specialists,
  SUM(Medical_doctors_not_further_defined__number_) AS UnDefined
FROM
  `disco-parsec-349213.medical_doctors.doctors_data`
WHERE
  Year = 2020
GROUP BY
  Countries__territories_and_areas,
  Year
ORDER BY
  SUM(Medical_doctors__number_) DESC


--- 3: WINDOWS FUNCTIONS - Generated 'Cumulative Total' for the total number of doctors across years for India using Windows Functions. Insight obtained that only three years of data present for India. 

SELECT
  Countries__territories_and_areas AS Country,
  Year,
  Medical_doctors__number_ AS Total_Doctors,
  SUM(Medical_doctors__number_) OVER (ORDER BY Year) AS Running_Total
FROM
  `disco-parsec-349213.medical_doctors.doctors_data`
WHERE
  Countries__territories_and_areas = "India"
ORDER BY
  Year

--- 4: CASE STATEMENTS - Modified query using CASE statement to generate % growth between years. Insight obtained that between number of doctors in India grew the most from 2018 to 2020 by 109%, whereas it only grew by 85% from 1991 to 2018.

SELECT
  a1.Countries__territories_and_areas AS Country,
  a1.Year,
  a1.Medical_doctors__number_ AS Total_Doctors,
  SUM(a1.Medical_doctors__number_) OVER (ORDER BY a1.Year) AS Running_Total,
  ROUND(SUM(a1.Medical_doctors__number_) OVER (ORDER BY a1.Year) / a2.Tot_Dr * 100,2) AS Percent_of_Total,
  CASE
    WHEN LAG(a1.Year) OVER (ORDER BY a1.Year) IS NULL THEN NULL -- Handle FIRST year
  ELSE
  ROUND( (a1.Medical_doctors__number_ / LAG(a1.Medical_doctors__number_) OVER (ORDER BY a1.Year)) * 100, 2 )
  END AS Percent_Growth
FROM
  `disco-parsec-349213.medical_doctors.doctors_data` a1,
  (
  SELECT
    SUM(Medical_doctors__number_) AS Tot_Dr
  FROM
    `disco-parsec-349213.medical_doctors.doctors_data`
  WHERE
    Countries__territories_and_areas = "India") a2
WHERE
  Countries__territories_and_areas = "India"
ORDER BY
  Year


--- 5: GROUP BY - Obtaining top 5 years which saw the highest number of doctors per 10000 population. Insight obtained that since 2017, there has been a decrease in the number of available doctors per 10000 population.
 
SELECT
  Year,
  ROUND(SUM(Medical_doctors__per_10_000_population_),2) AS Drs_Per_10K
FROM
  `disco-parsec-349213.medical_doctors.doctors_data`
GROUP BY
  Year
ORDER BY
  SUM(Medical_doctors__per_10_000_population_) DESC
LIMIT
  5


--- 6: RANK FUNCTIONS - Obtained ranking of top 10 countries in 2021 which had lowest % of Specialists per total number of doctors (limited to data where there were no null values for each column). Insight obtained that Guineau-Bissau had the lowest % of Specialists in 2021

SELECT
  Countries__territories_and_areas AS Country,
  ROUND(SUM(Generalist_medical_practitioners__number_) / SUM(Medical_doctors__number_)*100,2) AS Percent_GPs,
  ROUND(SUM(Specialist_medical_practitioners__number_) / SUM(Medical_doctors__number_)*100,2) AS Percent_Specialist,
  ROUND(SUM(Medical_doctors_not_further_defined__number_) / SUM(Medical_doctors__number_)*100,2) AS Percent_Undefined,
  DENSE_RANK() OVER (ORDER BY SUM(Specialist_medical_practitioners__number_) / SUM(Medical_doctors__number_)) AS Rank
FROM
  `disco-parsec-349213.medical_doctors.doctors_data`
WHERE
Year  = 2021 
AND Generalist_medical_practitioners__number_ IS NOT NULL
AND Specialist_medical_practitioners__number_ IS NOT NULL
AND Medical_doctors_not_further_defined__number_ IS NOT NULL
GROUP BY
Countries__territories_and_areas
ORDER BY
Rank


--- 7: VIRTUAL TABLES - Created virtual table focusing on one country (Australia), then wrote query to calculate the increase of % of GPs year over year and filtered table to obtain the 2 years that saw the most growth in % of GPs year over year (2019 and 2000).


WITH Australia AS (

SELECT
  Year,
  SUM(Medical_doctors__number_) AS Total_Doctors,
  SUM(Generalist_medical_practitioners__number_) AS GPs,
  SUM(Specialist_medical_practitioners__number_) AS Specialists,
  SUM(Medical_doctors_not_further_defined__number_) AS Undefined
FROM
  `disco-parsec-349213.medical_doctors.doctors_data`
WHERE
  Countries__territories_and_areas = "Australia"
GROUP BY
  Countries__territories_and_areas,
  Year
)

SELECT
Australia.Year,
Australia.Total_Doctors,
ROUND(Australia.GPs / Australia.Total_Doctors*100, 2) AS Percent_GPs,
ROUND(Australia.Specialists / Australia.Total_Doctors*100, 2) AS Percent_Specialists,
ROUND(Australia.Undefined / Australia.Total_Doctors*100, 2) AS Percent_Undefined,
CASE 
  WHEN LAG(Australia.Year) OVER (ORDER BY Australia.Year) IS NULL THEN NULL
  ELSE (
        Australia.GPs / Australia.Total_Doctors - (LAG(Australia.GPs / Australia.Total_Doctors) OVER (ORDER BY Australia.Year)))
  END AS Growth_GPs
FROM Australia
WHERE 
Australia.GPs IS NOT NULL
AND Australia.Specialists IS NOT NULL
AND Australia.Year != 2020
ORDER BY
Growth_GPs DESC
LIMIT 2




















