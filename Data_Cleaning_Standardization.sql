/* ============================================================
   STEP 8: STANDARDIZATION
   Purpose:
   - Clean inconsistent text values.
   - Make sure categories are grouped correctly during EDA.
   - Do not update blindly; investigate first, then update.
   ============================================================ */


/* ============================================================
   8.1 REVIEW THE CLEANED STAGING TABLE
   Purpose:
   - Quickly inspect the current working table after duplicates
     have been removed.
   ============================================================ */

SELECT *
FROM layoffs_staging2;


/* ============================================================
   8.2 STANDARDIZE COMPANY NAMES
   Purpose:
   - Remove leading/trailing spaces from company names.
   - Example: ' Airbnb' or 'Airbnb ' becomes 'Airbnb'.
   ============================================================ */

/* Preview company names before and after trimming */
SELECT company, TRIM(company)
FROM layoffs_staging2;

/* Apply trimming to company names */
UPDATE layoffs_staging2
SET company = TRIM(company);

/* Review distinct company names after trimming */
SELECT DISTINCT company
FROM layoffs_staging2
ORDER BY company;


/* ============================================================
   8.3 STANDARDIZE INDUSTRY VALUES
   Purpose:
   - Review unique industry values.
   - Fix categories that represent the same industry but are
     written differently.
   ============================================================ */

/* Review unique industry values */
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

/* Investigate industry values that start with 'Crypto' */
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

/* Standardize all Crypto-related values to 'Crypto' */
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

/* Verify Crypto values after update */
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

/* Review industry values again after standardization */
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;


/* ============================================================
   8.4 STANDARDIZE LOCATION VALUES
   Purpose:
   - Review unique location values.
   - Identify possible spelling or formatting issues.
   - In this dataset, 'Shenzen' looked suspicious, so we inspect it.
   ============================================================ */

/* Review unique locations */
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

/* Investigate suspicious location spelling */
SELECT *
FROM layoffs_staging2
WHERE location LIKE 'Shen%';

/*
   Decision:
   - If only one version exists, for example 'Shenzen',
     and no duplicate version like 'Shenzhen' exists,
     we may leave it as-is for grouping purposes.
   - This can be corrected later for reporting quality if needed.
*/


/* ============================================================
   8.5 STANDARDIZE COUNTRY VALUES
   Purpose:
   - Review country names.
   - Fix punctuation, spacing, or formatting inconsistencies.
   ============================================================ */

/* Review unique countries */
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

/* Investigate United States values with extra punctuation */
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States.%';

/* Standardize 'United States.' to 'United States' */
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country = 'United States.';

/* Preview country values before and after trimming */
SELECT DISTINCT country, TRIM(country)
FROM layoffs_staging2;

/* Remove leading/trailing spaces from country names */
UPDATE layoffs_staging2
SET country = TRIM(country);

/* Review country values after standardization */
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;


/* ============================================================
   STEP 9: DATE DATA TYPE CLEANING
   Purpose:
   - Convert the date column from TEXT to a proper DATE type.
   - This allows time-based EDA such as layoffs by year/month.
   ============================================================ */

/* Review original date values */
SELECT `date`
FROM layoffs_staging2;

/* Test date conversion before updating */
SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y') AS converted_date
FROM layoffs_staging2;

/*
   STR_TO_DATE explanation:
   - Current format: MM/DD/YYYY
   - '%m/%d/%Y' tells MySQL how to interpret the text date.
   - Example: '4/21/2020' becomes '2020-04-21'.
*/

/* Convert text dates into MySQL date format */
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

/* Verify date values after conversion */
SELECT `date`
FROM layoffs_staging2;

/* Change column data type from TEXT to DATE */
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

/* Verify if any date values became NULL after conversion */
SELECT COUNT(*)
FROM layoffs_staging2
WHERE `date` IS NULL;


/* ============================================================
   STANDARDIZATION + DATE CLEANING COMPLETE
   Next Step:
   - Handle NULL and blank values.
   ============================================================ */