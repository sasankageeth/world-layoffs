/* ============================================================
   WORLD LAYOFFS DATA CLEANING PROJECT
   Working Table: layoffs_staging3

   Cleaning Steps:
   1. Remove duplicates
   2. Standardize text values
   3. Handle NULL / missing values
   4. Fix data types
   5. Remove unnecessary rows/columns
   ============================================================ */


/* ============================================================
   STEP 1: CHECK COMPANIES WITH MULTIPLE RECORDS
   Note:
   - Multiple records for a company does NOT always mean duplicates.
   - A company can have multiple layoff events on different dates.
   ============================================================ */

SELECT company,
       COUNT(*) AS comp_count
FROM layoffs_staging
GROUP BY company
HAVING COUNT(*) > 1;


/* ============================================================
   STEP 2: IDENTIFY EXACT DUPLICATES
   Purpose:
   - Since there is no Primary Key, use ROW_NUMBER().
   - Partition by all columns to find exact duplicate rows.
   ============================================================ */

WITH cte_comp_dup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company,
                            location,
                            industry,
                            total_laid_off,
                            percentage_laid_off,
                            `date`,
                            stage,
                            country,
                            funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)

SELECT *
FROM cte_comp_dup
WHERE row_num > 1;


/* ============================================================
   STEP 3: CREATE CLEANING TABLE WITH ROW NUMBER
   Purpose:
   - Create a working table that includes row_num.
   - row_num helps identify duplicate copies.
   ============================================================ */

DROP TABLE IF EXISTS layoffs_staging3;

CREATE TABLE layoffs_staging3 AS
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company,
                        location,
                        industry,
                        total_laid_off,
                        percentage_laid_off,
                        `date`,
                        stage,
                        country,
                        funds_raised_millions
       ) AS row_num
FROM layoffs_staging;


/* Review duplicate rows before deleting */
SELECT *
FROM layoffs_staging3
WHERE row_num > 1;


/* Remove duplicate rows */
DELETE
FROM layoffs_staging3
WHERE row_num > 1;


/* Verify duplicates are removed */
SELECT COUNT(*)
FROM layoffs_staging3
WHERE row_num > 1;


/* ============================================================
   STEP 4: STANDARDIZE COMPANY NAMES
   Purpose:
   - Remove leading/trailing spaces from company names.
   ============================================================ */

SELECT company,
       TRIM(company) AS trimmed_company
FROM layoffs_staging3;

UPDATE layoffs_staging3
SET company = TRIM(company);


/* ============================================================
   STEP 5: STANDARDIZE INDUSTRY VALUES
   Purpose:
   - Remove spaces.
   - Standardize similar industry names.
   ============================================================ */

SELECT industry,
       TRIM(industry) AS trimmed_industry
FROM layoffs_staging3;

UPDATE layoffs_staging3
SET industry = TRIM(industry);


/* Review Crypto-related industry values */
SELECT DISTINCT industry
FROM layoffs_staging3
WHERE industry LIKE 'Cryp%';


/* Standardize Crypto variations */
UPDATE layoffs_staging3
SET industry = 'Crypto'
WHERE industry LIKE 'Cryp%';


/* Verify industry values */
SELECT DISTINCT industry
FROM layoffs_staging3
ORDER BY industry;


/* ============================================================
   STEP 6: STANDARDIZE LOCATION VALUES
   Purpose:
   - Remove leading/trailing spaces from location.
   ============================================================ */

SELECT DISTINCT location
FROM layoffs_staging3
ORDER BY location;

UPDATE layoffs_staging3
SET location = TRIM(location);


/* ============================================================
   STEP 7: STANDARDIZE COUNTRY VALUES
   Purpose:
   - Fix country formatting issues.
   - Example: 'United States.' → 'United States'
   ============================================================ */

SELECT DISTINCT country
FROM layoffs_staging3
WHERE country LIKE 'Unite%';


UPDATE layoffs_staging3
SET country = 'United States'
WHERE country = 'United States.';


SELECT country,
       TRIM(country) AS trimmed_country
FROM layoffs_staging3;

UPDATE layoffs_staging3
SET country = TRIM(country);


/* Verify country values */
SELECT DISTINCT country
FROM layoffs_staging3
ORDER BY country;


/* ============================================================
   STEP 8: HANDLE NULL / BLANK INDUSTRY VALUES
   Purpose:
   - Convert blank industry values to NULL.
   - Fill NULL industries only when evidence exists from
     the same company.
   ============================================================ */

SELECT *
FROM layoffs_staging3
WHERE industry IS NULL
   OR industry = '';


UPDATE layoffs_staging3
SET industry = NULL
WHERE industry = '';


/* Fill Airbnb missing industry using known Airbnb industry */
SELECT *
FROM layoffs_staging3
WHERE company = 'Airbnb';

UPDATE layoffs_staging3
SET industry = 'Travel'
WHERE company = 'Airbnb'
  AND industry IS NULL;


/* Fill Carvana missing industry using known Carvana industry */
SELECT *
FROM layoffs_staging3
WHERE company = 'Carvana';

UPDATE layoffs_staging3
SET industry = 'Transportation'
WHERE company = 'Carvana'
  AND industry IS NULL;


/* Fill Juul missing industry using known Juul industry */
SELECT *
FROM layoffs_staging3
WHERE company = 'Juul';

UPDATE layoffs_staging3
SET industry = 'Consumer'
WHERE company = 'Juul'
  AND industry IS NULL;


/* Review remaining NULL industries */
SELECT *
FROM layoffs_staging3
WHERE industry IS NULL;


/* ============================================================
   STEP 9: CONVERT DATE COLUMN
   Purpose:
   - Convert date from TEXT to proper DATE datatype.
   - This helps with EDA by year, month, and time trends.
   ============================================================ */

SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y') AS converted_date
FROM layoffs_staging3;


UPDATE layoffs_staging3
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');


ALTER TABLE layoffs_staging3
MODIFY COLUMN `date` DATE;


/* Verify date conversion */
SELECT `date`
FROM layoffs_staging3;


/* ============================================================
   STEP 10: REMOVE UNUSABLE ROWS
   Purpose:
   - If both total_laid_off and percentage_laid_off are NULL,
     the row does not tell us useful layoff impact.
   ============================================================ */

SELECT *
FROM layoffs_staging3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


DELETE
FROM layoffs_staging3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


/* ============================================================
   STEP 11: DROP HELPER COLUMN
   Purpose:
   - row_num was only used for duplicate removal.
   - It is no longer needed for analysis.
   ============================================================ */

ALTER TABLE layoffs_staging3
DROP COLUMN row_num;


/* ============================================================
   FINAL VALIDATION CHECKS
   Purpose:
   - Confirm the dataset is ready for EDA.
   ============================================================ */

SELECT *
FROM layoffs_staging3;


SELECT COUNT(*)
FROM layoffs_staging3;


SELECT DISTINCT industry
FROM layoffs_staging3
ORDER BY industry;


SELECT DISTINCT country
FROM layoffs_staging3
ORDER BY country;


DESCRIBE layoffs_staging3;


/* ============================================================
   DATA CLEANING COMPLETE
   ============================================================ */