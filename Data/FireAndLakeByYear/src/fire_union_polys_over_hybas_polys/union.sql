CREATE TABLE IF NOT EXISTS fire_area_canada_usa_unions (
    year        INTEGER NOT NULL,
    geometry    geometry(Geometry,3978),
    
    PRIMARY KEY ("year")
);


CREATE INDEX IF NOT EXISTS
    idx_fire_area_canada_usa_unions_geometry
ON 
    fire_area_canada_usa_unions
USING 
    GIST ("geometry");


INSERT INTO 
    fire_area_canada_usa_unions (year, geometry)
SELECT 
    {{YEAR}} 
        AS year,
    ST_Union(original.simple_geometry) 
        AS geometry
FROM 
    fire_area_canada_usa{{YEAR}} 
        AS original;