-- ==================================================================
-- SQL DATA CLEANING
-- TABLE: `stable-hybrid-398218.sql_practice.shipments`
-- ==================================================================

SELECT * FROM `stable-hybrid-398218.sql_practice.shipments` LIMIT 1000 ;

-- ==================================================================
-- QUERY 1: Remove Leading/Trailing Whitespace
-- ==================================================================

SELECT 
  shipment_id,
  TRIM(origin_warehouse) AS origin_warehouse,
  TRIM(destination_city) AS destination_city,
  TRIM(destination_state) AS destination_state,
  TRIM(carrier) AS carrier,
  TRIM(shipment_status) AS shipment_status,
  TRIM(damage_reported) AS damage_reported
FROM `stable-hybrid-398218.sql_practice.shipments`;

-- ==================================================================
-- QUERY 2: Standardize Text Casing
-- ==================================================================

SELECT 
  shipment_id,
  INITCAP(TRIM(origin_warehouse)) AS origin_warehouse,
  INITCAP(TRIM(destination_city)) AS destination_city,
  UPPER(TRIM(destination_state)) AS destination_state,
  INITCAP(TRIM(carrier)) AS carrier,
  INITCAP(TRIM(shipment_status)) AS shipment_status,
  INITCAP(TRIM(damage_reported)) AS damage_reported
FROM `stable-hybrid-398218.sql_practice.shipments`;

-- ==================================================================
-- QUERY 3: Replace Srting "NULL" & Handle True NULLs
-- ==================================================================

SELECT 
  shipment_id,
  CASE 
    WHEN damage_reported = 'NULL' THEN NULL
    ELSE INITCAP(TRIM(damage_reported))
  END AS damage_reported,

  COALESCE(INITCAP(TRIM(destination_city)), 'Unknown') AS destination_city,
  COALESCE(INITCAP(TRIM(shipment_status)), 'Not Yet Delivered') AS shipment_status

FROM `stable-hybrid-398218.sql_practice.shipments`;

-- ==================================================================
-- QUERY 4: Remove Exact Duplicate Rows
-- ==================================================================
SELECT
  shipment_id,
  COUNT(*) AS row_count
FROM `stable-hybrid-398218.sql_practice.shipments`
GROUP BY shipment_id
HAVING COUNT(*) > 1; -- No exact identical rows

WITH ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER ( -- Assigns a number to each row within each duplicate group
      PARTITION BY
      -- Defining what counts as a duplicate
      -- shipment_id is not here, we're assuming two different IDs can still represent duplicate shipment records
        origin_warehouse,
        destination_city,
        carrier,
        ship_date,
        CAST(weight_kg AS STRING),
        CAST(freight_cost AS STRING)
      ORDER BY shipment_id
    ) AS row_num
  FROM `stable-hybrid-398218.sql_practice.shipments`
)

SELECT * EXCEPT(row_num) -- Remove our helper column
FROM ranked
WHERE row_num = 1;

-- ==================================================================
-- QUERY 5: Fix Negative & Suspicious Numeric Values
-- ==================================================================

SELECT 
  shipment_id, 
  CASE 
    WHEN weight_kg < 0 THEN ABS(weight_kg) 
    WHEN weight_kg = 0 THEN NULL 
    ELSE weight_kg 
    END AS weight_kg_cleaned 
    
FROM stable-hybrid-398218.sql_practice.shipments;

-- Checking if there are any negative values in freight_cost column
SELECT
  MIN(freight_cost) AS min_cost,
  MAX(freight_cost) AS max_cost,
  COUNTIF(freight_cost < 0) AS negative_costs,
  COUNTIF(freight_cost = 0) AS zero_costs
FROM `stable-hybrid-398218.sql_practice.shipments`;

-- ==================================================================
-- QUERY 6: Validate Date Logic (Delivery After Ship Date)
-- ==================================================================
WITH cleaned_dates AS (
  SELECT
    shipment_id,
    ship_date,
    delivery_date,

    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', ship_date),
      SAFE.PARSE_DATE('%Y/%m/%d', ship_date),
      SAFE.PARSE_DATE('%B %e %Y', ship_date),
      SAFE.PARSE_DATE('%b %e %Y', ship_date)
    ) AS ship_date_cleaned,

    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', delivery_date),
      SAFE.PARSE_DATE('%Y/%m/%d', delivery_date),
      SAFE.PARSE_DATE('%B %e %Y', delivery_date),
      SAFE.PARSE_DATE('%b %e %Y', delivery_date)
    ) AS delivery_date_cleaned

  FROM `stable-hybrid-398218.sql_practice.shipments`
)

SELECT
  shipment_id,
  ship_date,
  delivery_date,
  ship_date_cleaned,
  delivery_date_cleaned,

  DATE_DIFF(
    delivery_date_cleaned,
    ship_date_cleaned,
    DAY
  ) AS transit_days,

  CASE
    WHEN delivery_date_cleaned < ship_date_cleaned THEN 'INVALID'
    WHEN delivery_date_cleaned = ship_date_cleaned THEN 'SAME DAY DELIVERY'
    ELSE 'VALID'
  END AS data_quality_flag

FROM cleaned_dates;

-- ==================================================================
-- QUERY 7: Detect & Cap Outliers - IQR Method
-- ==================================================================

WITH percentiles AS (
  SELECT
    APPROX_QUANTILES(freight_cost, 100)[OFFSET(25)] AS q1,
    APPROX_QUANTILES(freight_cost, 100)[OFFSET(75)] AS q3
  FROM `stable-hybrid-398218.sql_practice.shipments`
  WHERE freight_cost > 0
),

bounds AS (
  SELECT
    q1 - 1.5 * (q3 - q1) AS lower_bound,
    q3 + 1.5 * (q3 - q1) AS upper_bound
  FROM percentiles
)

SELECT
  shipment_id,
  freight_cost,

  CASE
    WHEN freight_cost > upper_bound THEN upper_bound
    WHEN freight_cost < lower_bound THEN lower_bound
    ELSE freight_cost
  END AS freight_cost_capped,

  CASE
    WHEN freight_cost > upper_bound
      OR freight_cost < lower_bound
    THEN 'OUTLIER'
    ELSE 'NORMAL'
  END AS outlier_flag

FROM `stable-hybrid-398218.sql_practice.shipments`
CROSS JOIN bounds;
