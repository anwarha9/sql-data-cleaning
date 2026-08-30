# SQL Data Cleaning

A SQL project cleaning and validating a shipment dataset using **Google BigQuery**.

## What I cleaned

- Removed leading and trailing whitespace
- Standardized text casing and formatting
- Handled missing and NULL values
- Identified duplicate records
- Checked and cleaned suspicious numeric values
- Standardized date formats and validated date logic
- Detected and capped outliers using the IQR method

## Tools

- SQL
- Google BigQuery

## Dataset

The project uses the `shipments.csv` dataset.

## SQL concepts practiced

`CTEs` · `CASE WHEN` · `COALESCE()` · `TRIM()` · `INITCAP()` · `UPPER()` · `ROW_NUMBER()` · `PARTITION BY` · `CAST()` · `SAFE.PARSE_DATE()` · `DATE_DIFF()` · `APPROX_QUANTILES()` · aggregations
