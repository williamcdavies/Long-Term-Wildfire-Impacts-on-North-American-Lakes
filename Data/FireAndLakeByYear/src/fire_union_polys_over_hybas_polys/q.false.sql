COPY (
    WITH clipped_watersheds AS (
        SELECT
            hybas.id                              AS id,
            hybas.hybas_id                        AS hybas_id,
            hybas.pfaf_id                         AS pfaf_id,
            hybas.src_rgn                         AS src_rgn,
            hybas.geom_3978                       AS hybas_geom
        FROM      hybas             AS hybas
        JOIN      fire_polys_unions AS fpu ON fpu.year = {{YEAR}}
        WHERE NOT ST_Intersects(hybas.geom_3978, fpu.geom)
    )
    SELECT
        cw.id,
        cw.hybas_id,  
        cw.pfaf_id,
        cw.src_rgn,
        0            AS overlap_percentage,
        l.id         AS hylak_id,
        l.name       AS hylak_name,
        co.name      AS hylak_country,
        cn.name      AS hylak_continent,
        l.lon        AS hylak_lon,
        l.lat        AS hylak_lat
    FROM clipped_watersheds AS cw
    JOIN lakes_points       AS lp ON ST_Intersects(cw.hybas_geom, lp.geom_3978)
    JOIN lakes              AS l  ON l.id = lp.id
    JOIN countries          AS co ON co.id = l.country
    JOIN continents         AS cn ON cn.id = l.continent
    ORDER BY cw.id, l.id
) TO STDOUT WITH CSV HEADER;