/* ============================================================
   WORLD LAYOFFS DATA CLEANING PROJECT
   STEP 0: IMPORT CSV INTO MYSQL
   ============================================================ */

/* Enable LOCAL INFILE so MySQL can read local CSV files */
SET GLOBAL local_infile = 1;

/* Verify LOCAL INFILE is enabled */
SHOW GLOBAL VARIABLES LIKE 'local_infile';


/* ============================================================
   STEP 1: CREATE RAW TABLE
   Purpose:
   - Store imported CSV data exactly as it appears.
   - No cleaning should be performed on this table.
   ============================================================ */

DROP TABLE IF EXISTS layoffs;

CREATE TABLE layoffs (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off TEXT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions TEXT
);


/* ============================================================
   STEP 2: LOAD CSV INTO RAW TABLE
   Purpose:
   - Import CSV file into MySQL.
   - IGNORE 1 ROWS skips the header row.
   ============================================================ */

LOAD DATA LOCAL INFILE '/Users/sasankageetanathgorthi/Desktop/MySQL/world_layoffs/layoffs.csv'
INTO TABLE layoffs
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


/* Verify all rows were imported */
SELECT COUNT(*)
FROM layoffs;


/* ============================================================
   STEP 3: CREATE STAGING TABLE
   Purpose:
   - Never clean the raw table directly.
   - Use a replica table for all cleaning operations.
   ============================================================ */

DROP TABLE IF EXISTS layoffs_staging;

CREATE TABLE layoffs_staging
LIKE layoffs;


/* Copy data from raw table into staging table */
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;


/* Verify data exists in staging table */
SELECT *
FROM layoffs_staging;


/* ============================================================
   STEP 4: IDENTIFY DUPLICATES
   Purpose:
   - Check whether exact duplicate records exist.
   - Since there is no Primary Key, use ROW_NUMBER().
   ============================================================ */

WITH CTE_duplicate_staging AS (
	SELECT *,
		   ROW_NUMBER() OVER(
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
FROM CTE_duplicate_staging
WHERE row_num > 1;


/* ============================================================
   STEP 5: INVESTIGATE DUPLICATES
   Purpose:
   - Never delete data before verifying it.
   - Inspect duplicate candidates manually.
   ============================================================ */

SELECT *
FROM layoffs_staging
WHERE company = 'Casper'
ORDER BY company;


/* ============================================================
   STEP 6: CREATE DEDUPLICATION TABLE
   Purpose:
   - Store duplicate flag (row_num).
   - Makes deletion easier and safer.
   ============================================================ */

DROP TABLE IF EXISTS layoffs_staging2;

CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off TEXT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions TEXT,
    row_num INT
);


/* Populate table with duplicate indicators */
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER(
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
FROM layoffs_staging2
WHERE row_num > 1;


/* Count duplicates before deletion */
SELECT COUNT(*)
FROM layoffs_staging2
WHERE row_num > 1;


/* ============================================================
   STEP 7: REMOVE DUPLICATES
   Purpose:
   - Keep row_num = 1
   - Remove row_num > 1
   ============================================================ */

/* Disable Safe Update Mode temporarily */
SET SQL_SAFE_UPDATES = 0;


/* Delete duplicate rows */
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


/* Re-enable Safe Update Mode */
SET SQL_SAFE_UPDATES = 1;


/* Verify duplicates were removed */
SELECT COUNT(*)
FROM layoffs_staging2
WHERE row_num > 1;


/* ============================================================
   DUPLICATES CLEANING COMPLETE
   Next Step:
   - Standardization
   - Check company, industry, country, and location
     for inconsistent values and formatting.
   ============================================================ */