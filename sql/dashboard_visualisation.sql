SELECT
    c.geo_id AS country,
    f.value
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_country c
    ON f.country_id = c.country_id
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
JOIN finalProjectSchema.dim_date d
    ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
  AND d.year = (
        SELECT MAX(d2.year)
        FROM finalProjectSchema.fact_world_bank_metrics f2
        JOIN finalProjectSchema.dim_date d2
            ON f2.date_id = d2.date_id
        JOIN finalProjectSchema.dim_indicator i2
            ON f2.indicator_id = i2.indicator_id
        WHERE i2.variable = 'WDI_SP.POP.TOTL.MA.ZS'
    )
  AND f.yearly_rank <= 10
ORDER BY f.value DESC;


SELECT
    d.year,
    AVG(f.value) AS avg_population_share
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
JOIN finalProjectSchema.dim_date d
    ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
GROUP BY d.year
ORDER BY d.year;


SELECT
    d.year,
    c.geo_id AS country,
    AVG(f.value) AS value
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_country c
    ON f.country_id = c.country_id
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
JOIN finalProjectSchema.dim_date d
    ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.TOTL.MA.ZS'
  AND c.geo_id IN ('country/USA', 'country/DEU', 'country/JPN')
GROUP BY d.year, c.geo_id
ORDER BY d.year;


SELECT
    d.year,
    AVG(f.value) AS value
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
JOIN finalProjectSchema.dim_date d
    ON f.date_id = d.date_id
WHERE i.variable = 'WDI_SP.POP.1564.TO.ZS'
GROUP BY d.year
ORDER BY d.year;


SELECT
    d.year,
    i.variable_name AS gender,
    AVG(f.value) AS value
FROM finalProjectSchema.fact_world_bank_metrics f
JOIN finalProjectSchema.dim_indicator i
    ON f.indicator_id = i.indicator_id
JOIN finalProjectSchema.dim_date d
    ON f.date_id = d.date_id
WHERE i.variable IN (
    'WDI_SP.POP.TOTL.MA.ZS',
    'WDI_SP.POP.TOTL.FE.ZS'
)
GROUP BY d.year, i.variable_name
ORDER BY d.year;
