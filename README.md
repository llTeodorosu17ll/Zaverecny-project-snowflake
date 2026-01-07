# ELT Process and Data Warehouse (DWH) in Snowflake  
## World Bank – World Development Indicators

---

## 1. Introduction and Source Data Description

This project implements a complete ELT (Extract–Load–Transform) process and a dimensional data warehouse (DWH) in Snowflake.  
All data used in the project comes exclusively from the **Snowflake Marketplace**.

The selected dataset is **World Bank – World Development Indicators (WDI)**.  
It was chosen because it represents a well-structured, real-world analytical dataset containing globally recognized indicators related to population, demographics, and socio-economic development across countries and time.

### Purpose of the Analysis

The goal of the project is to:
- design a scalable star schema,
- enable historical and comparative analysis across countries and years,
- demonstrate correct ELT principles in Snowflake,
- present analytical results using meaningful visualizations.

### Source Dataset

- **Marketplace database:** `SNOWFLAKE_PUBLIC_DATA_FREE`
- **Schema:** `PUBLIC_DATA_FREE`

#### Source Tables

**WORLD_BANK_TIMESERIES**
- Contains time-series values of World Bank indicators.
- Each record represents a value of one indicator for one country and date.
- Key attributes include country identifier, indicator code, date, value, and unit.

**WORLD_BANK_ATTRIBUTES**
- Contains metadata describing indicators.
- Includes indicator names, units, measurement types, frequency, source, and ESG classification.
- Provides descriptive context for analytical interpretation.

### ERD – Source Data Structure

![ERD zdrojových dát](img/ERD_zdrojových_dát.png)

---

## 2. Dimensional Model Design (Star Schema)

The analytical data warehouse is designed using a **Star Schema**, optimized for analytical queries.

### Dimension Tables

**DIM_COUNTRY**
- Stores distinct countries identified by `geo_id`.
- Used for geographical analysis.
- SCD Type: **Type 0** (static reference data).

**DIM_DATE**
- Stores derived calendar attributes.
- Attributes include date, year, and decade.
- Enables time-based analysis.
- SCD Type: **Type 0**.

**DIM_INDICATOR**
- Stores metadata for World Bank indicators.
- Includes indicator code, name, unit, frequency, source, and ESG pillar.
- SCD Type: **Type 0**.

### Fact Table

**FACT_WORLD_BANK_METRICS**
- Stores measured indicator values.
- Grain: one indicator value per country per date.
- Contains surrogate primary key and foreign keys to all dimensions.
- Includes analytical metric `yearly_rank`, derived using window functions.

### Star Schema Diagram

![Star Schema](img/star_schema.jpg)

---

## 3. ELT Process in Snowflake

### Extract

Data is extracted from the Snowflake Marketplace into staging tables using CTAS (CREATE TABLE AS SELECT).

```sql
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
```

### Transform
```sql
CREATE OR REPLACE TABLE finalProjectSchema.dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY date) AS date_id,
    date,
    EXTRACT(YEAR FROM date) AS year,
    FLOOR(EXTRACT(YEAR FROM date) / 10) * 10 AS decade
FROM (
    SELECT DISTINCT date
    FROM finalProjectSchema.STAGING_WORLD_BANK_TIMESERIES
);

CREATE OR REPLACE TABLE finalProjectSchema.dim_country AS
SELECT
    ROW_NUMBER() OVER (ORDER BY geo_id) AS country_id,
    geo_id
FROM (
    SELECT DISTINCT GEO_ID AS geo_id
    FROM finalProjectSchema.STAGING_WORLD_BANK_TIMESERIES
);

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
);
```

### Load
```sql
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
    ON ts.DATE = d.date;
```

---
## Data Visualizations

### Visualization 1: Top 10 Countries by Male Population Share (Latest Year)

This bar chart displays the top 10 countries with the highest male population share (%) in the most recent year.
The ranking is computed using a window function in the fact table.

```sql
SELECT
    c.geo_id AS country,
    f.value
FROM fact_world_bank_metrics f
JOIN dim_country c ON f.country_id = c.country_id
JOIN dim_indicator i ON f.indicator_id = i.indicator_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
  AND d.year = (SELECT MAX(year) FROM dim_date)
  AND f.yearly_rank <= 10
ORDER BY f.value DESC;
```

### Visualization 2: Global Trend of Male Population Share

This line chart shows the global average share of male population (%) over time, allowing observation of long-term demographic stability.

```sql
SELECT
    d.year,
    AVG(f.value) AS avg_population_share
FROM fact_world_bank_metrics f
JOIN dim_indicator i ON f.indicator_id = i.indicator_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
GROUP BY d.year
ORDER BY d.year;
```

### Visualization 3: Male Population Share by Country (USA, Germany, Japan)

This chart compares male population share over time for selected countries to highlight national differences.

```sql
SELECT
    d.year,
    c.geo_id AS country,
    AVG(f.value) AS value
FROM fact_world_bank_metrics f
JOIN dim_country c ON f.country_id = c.country_id
JOIN dim_indicator i ON f.indicator_id = i.indicator_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
  AND c.geo_id IN ('country/USA','country/DEU','country/JPN')
GROUP BY d.year, c.geo_id
ORDER BY d.year;
```

### Visualization 4: Global Share of Working-Age Population (15–64)

This bar chart presents the global proportion of working-age population, an important indicator for economic analysis.

```sql
SELECT
    d.year,
    AVG(f.value) AS value
FROM fact_world_bank_metrics f
JOIN dim_indicator i ON f.indicator_id = i.indicator_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.1564.TO.ZS'
GROUP BY d.year
ORDER BY d.year;
```

### Visualization 5: Gender Composition of Population Over Time

This visualization compares male and female population shares (%) to show long-term gender balance.

```sql
SELECT
    d.year,
    i.variable_name AS gender,
    AVG(f.value) AS value
FROM fact_world_bank_metrics f
JOIN dim_indicator i ON f.indicator_id = i.indicator_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE i.variable IN (
    'WDI_SP.POP.TOTL.MA.ZS',
    'WDI_SP.POP.TOTL.FE.ZS'
)
GROUP BY d.year, i.variable_name
ORDER BY d.year;
```
