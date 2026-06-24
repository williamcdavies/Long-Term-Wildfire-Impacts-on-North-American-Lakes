COPY (
WITH lakes_in_country AS (
    SELECT 
        l.id, 
        l.geom
    FROM lakes_points AS l
    JOIN countries    AS c
        ON c.id = 240 OR c.id = 61
    WHERE ST_Within(l.geom, c.geom_4326)
),
xref AS (
    SELECT
        l.id                                 AS l_id,
        s.id                                 AS s_id,
        s.start_year                         AS year,
        (s.start_year * 1000 + s.start_day)  AS start,
        (s.end_year   * 1000 + s.end_day)    AS end,
        d.name                               AS density
    FROM lakes_in_country   AS l
    JOIN hms_smokes{{YEAR}} AS s
        ON ST_Within(l.geom, s.geom)
    LEFT JOIN densities d
        ON s.density = d.id
),
xref_expanded AS (
    SELECT
        l_id,
        s_id,
        year,
        (TO_DATE(start::text, 'YYYYDDD') + i)::date AS day,
        density
    FROM xref,
    generate_series(
        0,
        (TO_DATE("end"::text, 'YYYYDDD') - TO_DATE(start::text, 'YYYYDDD'))::int
    ) AS i
),
xref_ranked AS (
    SELECT
        l_id,
        year,
        day,
        MAX(
            CASE COALESCE(density, '')
                WHEN 'Heavy'  THEN 3
                WHEN 'Medium' THEN 2
                WHEN 'Light'  THEN 1
                ELSE 0
            END
        ) AS density_rank
    FROM xref_expanded
    GROUP BY l_id, year, day
)
SELECT
    day                                          AS date,
    COUNT(CASE WHEN density_rank = 1 THEN 1 END) AS l,
    COUNT(CASE WHEN density_rank = 2 THEN 1 END) AS m,
    COUNT(CASE WHEN density_rank = 3 THEN 1 END) AS h,
    COUNT(CASE WHEN density_rank = 0 THEN 1 END) AS na,
    COUNT(*)                                     AS sum
FROM xref_ranked
GROUP BY day
ORDER BY day
) TO STDOUT WITH CSV HEADER;