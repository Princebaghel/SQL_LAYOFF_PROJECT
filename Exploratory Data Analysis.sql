
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