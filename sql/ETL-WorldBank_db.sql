CREATE OR REPLACE TABLE STAGING_WORLD_BANK_TIMESERIES AS
SELECT
    GEO_ID,
    VARIABLE,
    VARIABLE_NAME,
    DATE,
    VALUE,
    UNIT
FROM SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.WORLD_BANK_TIMESERIES
WHERE VALUE IS NOT NULL;

SELECT COUNT(*) 
FROM STAGING_WORLD_BANK_TIMESERIES;

CREATE OR REPLACE TABLE STAGING_WORLD_BANK_ATTRIBUTES AS
SELECT
    VARIABLE,
    VARIABLE_NAME,
    MEASURE,
    UNIT,
    FREQUENCY,
    SOURCE,
    WORLD_BANK_SOURCE,
    ESG_PILLAR
FROM SNOWFLAKE_PUBLIC_DATA_FREE.PUBLIC_DATA_FREE.WORLD_BANK_ATTRIBUTES;

CREATE OR REPLACE TABLE finalProjectSchema.dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY date) AS date_id,
    date,
    EXTRACT(YEAR FROM date) AS year,
    FLOOR(EXTRACT(YEAR FROM date) / 10) * 10 AS decade
FROM (
    SELECT DISTINCT
        date
    FROM finalProjectSchema.STAGING_WORLD_BANK_TIMESERIES
)
ORDER BY date;

CREATE OR REPLACE TABLE finalProjectSchema.dim_country AS
SELECT
    ROW_NUMBER() OVER (ORDER BY geo_id) AS country_id,
    geo_id
FROM (
    SELECT DISTINCT GEO_ID AS geo_id
    FROM finalProjectSchema.STAGING_WORLD_BANK_TIMESERIES
)
ORDER BY geo_id;

CREATE OR REPLACE TABLE finalProjectSchema.dim_indicator AS
SELECT
    ROW_NUMBER() OVER (ORDER BY variable) AS indicator_id,
    variable,
    variable_name,
    measure,
    unit,
    frequency,
    source,
    world_bank_source,
    esg_pillar
FROM (
    SELECT DISTINCT
        VARIABLE AS variable,
        VARIABLE_NAME AS variable_name,
        MEASURE,
        UNIT,
        FREQUENCY,
        SOURCE,
        WORLD_BANK_SOURCE,
        ESG_PILLAR
    FROM finalProjectSchema.STAGING_WORLD_BANK_ATTRIBUTES
)
ORDER BY variable;

CREATE OR REPLACE TABLE finalProjectSchema.fact_world_bank_metrics AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ts.GEO_ID, ts.VARIABLE, ts.DATE) AS fact_id,
    c.country_id,
    i.indicator_id,
    d.date_id,
    ts.VALUE AS value,
    ROW_NUMBER() OVER (
        PARTITION BY i.indicator_id, d.year
        ORDER BY ts.VALUE DESC
    ) AS yearly_rank
FROM finalProjectSchema.STAGING_WORLD_BANK_TIMESERIES ts
JOIN finalProjectSchema.dim_country c
    ON ts.GEO_ID = c.geo_id
JOIN finalProjectSchema.dim_indicator i
    ON ts.VARIABLE = i.variable
JOIN finalProjectSchema.dim_date d
    ON ts.DATE = d.date
WHERE ts.VALUE IS NOT NULL;

SELECT
    i.variable,
    i.variable_name,
    COUNT(*) AS rows_in_fact
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
WHERE i.variable LIKE 'NY.%'
   OR i.variable LIKE 'FP.%'
   OR i.variable LIKE 'FS.%'
   OR i.variable LIKE 'FM.%'
GROUP BY i.variable, i.variable_name
ORDER BY rows_in_fact DESC
LIMIT 20;
