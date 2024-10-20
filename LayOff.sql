
-- Data Cleaning

Select * 
FROM layoffs;

-- Creating a copy of the table layoffs.
CREATE TABLE layoffs_copy
LIKE layoffs;

INSERT layoffs_copy
SELECT * FROM layoffs;

SELECT * FROM layoffs_copy;

-- 1.Removing Duplicates

SELECT * 
FROM(SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS Row_Num
FROM layoffs_copy) x
WHERE x.Row_Num > 1;

SELECT * FROM layoffs_copy
WHERE company In ('Casper','Yahoo');

-- Deleting Dupticate values by creating a Backup table.
CREATE TABLE layoffs_copy_bkp AS
SELECT DISTINCT *
FROM layoffs_copy;

Select * from layoffs_copy_bkp;

DROP TABLE layoffs_copy;

ALTER TABLE layoffs_copy_bkp RENAME TO layoffs_copy;

SELECT * FROM layoffs_copy;


-- 2.Standardizing the data

-- Removing the Leading and trailing spaces.
SELECT company, TRIM(company) as After_Removing_Spaces
FROM layoffs_copy;

UPDATE layoffs_copy
SET company = TRIM(company);

SELECT * FROM layoffs_copy;

-- Selecting distinct industries from the layoffs_copy table and orders them alphabetically.
SELECT DISTINCT industry
FROM layoffs_copy
ORDER BY 1;

-- Retrieving all records from the layoffs_copy table where the industry starts with "Crypto".
SELECT *
FROM layoffs_copy
WHERE industry like "Crypto%";

-- Updating the industry values to "Crypto" for all records where the industry starts with "Crypto".
UPDATE layoffs_copy
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

SELECT DISTINCT location
FROM layoffs_copy;

SELECT DISTINCT country
FROM layoffs_copy;

SELECT DISTINCT country
FROM layoffs_copy
WHERE country LIKE "United States%";

-- Updating the country to "United States" for all records where the country starts with "United States
UPDATE layoffs_copy
SET country = TRIM(TRAILING "." FROM country)
WHERE country LIKE "United States%";

-- Changing the date column to date format
SELECT `date`,STR_TO_DATE(`date`,'%m/%d/%Y') AS "Updated Date"
FROM layoffs_copy;

UPDATE layoffs_copy
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');
ALTER TABLE layoffs_copy
MODIFY COLUMN `date` DATE;



-- 3.NUll values or blank values

-- Updating empty industry values to NULL
SELECT * FROM layoffs_copy
WHERE industry IS NULL OR industry = "";

Select * from layoffs_copy
where company = "Airbnb";	

UPDATE layoffs_copy
SET industry  = NULL
WHERE industry = "";

/*
Finding Industries with Null Values,
that match with Not Null industries for the same company.alter.
Updating the Null industry values with corresponding non Null values.
*/

SELECT * FROM layoffs_copy
WHERE industry IS NULL OR industry = "";

SELECT t1.industry,t2.industry
FROM layoffs_copy AS t1
JOIN layoffs_copy AS t2 
	ON t1.company = t2.company
WHERE (t1.industry IS NULL 
	AND t2.industry IS NOT NULL);

UPDATE layoffs_copy t1
JOIN layoffs_copy t2
	ON t1.company  = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL 
	AND t2.industry IS NOT NULL);
    
-- Deleting all the record where total laid off
-- and percentage laid off column are NULL    

SELECT * FROM layoffs_copy
WHERE (percentage_laid_off IS NULL
AND total_laid_off IS NULL);

DELETE
FROM layoffs_copy
WHERE (percentage_laid_off IS NULL
AND total_laid_off IS NULL);

SELECT * FROM layoffs_copy;




-- Exploratory Data Analysis

SELECT * 
FROM layoffs_copy;

SELECT MAX(total_laid_off)
FROM layoffs_copy;

-- The companies which have 1 is basically 100 percent of they company laid off
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time

-- Looking at Percentage to see how big these layoffs were
SELECT *
FROM layoffs_copy
WHERE  percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Companies which had high funding and had to laid off employees.
SELECT *
FROM layoffs_copy
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Companies with most Total layoffs
SELECT company,SUM(total_laid_off)
FROM layoffs_copy
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- Companies with most Total layoffs by location
SELECT location,SUM(total_laid_off)
FROM layoffs_copy
GROUP BY location
ORDER BY 2 DESC
LIMIT 5;

-- Companies with most Total layoffs by Industry
SELECT industry,SUM(total_laid_off) AS 'Total Lay Off'
FROM layoffs_copy
GROUP BY industry
ORDER BY 2 DESC;
-- LIMIT 5;

-- Layoffs Per Year
SELECT YEAR(`date`),SUM(total_laid_off) AS 'Total Lay Off'
FROM layoffs_copy
GROUP BY YEAR(`date`);


-- Rolling Total of Layoffs Per Month
SELECT * 
FROM layoffs_copy;

SELECT SUBSTR(`DATE`,1,7) AS `MONTH`,SUM(total_laid_off)
FROM layoffs_copy
WHERE SUBSTR(`DATE`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1;

WITH Rolling_Total AS
(
SELECT SUBSTR(`DATE`,1,7) AS `MONTH`,SUM(total_laid_off) AS Monthly_Total
FROM layoffs_copy
WHERE SUBSTR(`DATE`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1	
)

SELECT 
	`MONTH`,
     Monthly_Total,
     SUM(Monthly_Total) OVER(ORDER BY `MONTH`) AS Rolling_total
FROM Rolling_Total;



-- Companies with the most layoffs for each year
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_copy
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;