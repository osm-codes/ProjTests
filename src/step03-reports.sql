/**
 * Install step 3.
 * Module: tables and views for reports.
 * Ref: https://www.linkedin.com/in/jason-balkenbush-99452049/
 */

-----------
-- SAMPLES:

CREATE VIEW projtest.vw01_SRIDs AS
  SELECT srid, auth_name
  FROM spatial_ref_sys
  WHERE srid IN (952019,955001,955002,955010,955030,955032)
;
CREATE VIEW projtest.vw03_refPoints AS
  SELECT * FROM ( VALUES
    (ST_Point(-46.633956,-23.550385,4326), 'BR', 'Sao Paulo', 760 ), 
    (ST_Point(-68.13333,-16.496,4326), 'BO', 'La Paz', 3650 ),
    (ST_Point(-60.023333,-3.130278,4326), 'BR', 'Manaus', 90 ), 
    (ST_Point(-38.522481,-3.807267,4326), 'BR', 'Fortaleza', 20 ), 
    (ST_Point(-57.03694, -29.78333,4326), 'BR', 'Uruguaiana', 70 ), 
    (ST_Point(-53.807348,-29.685718,4326), 'BR', 'Santa Maria', 110 ),
    (ST_Point(-47.899213,-15.78340,4326), 'BR', 'Mané Garrincha (estadio)', 1200 ), 
    (ST_Point(-29.326123,-20.508324,4326), 'BR', 'Trindade (ilha)', 170 )
  ) t1 (pt_geom,country_code,city_name,elevation)
;
       
CREATE VIEW projtest.vw05_samples AS
   SELECT *, ST_SetSRID(ST_GeomFromGeoHash(ghs),4326) geom
   FROM generate_series(5,7) t0(ghs_digits), LATERAL (
     SELECT ST_GeoHash( pt_geom, ghs_digits ) as ghs, *
     FROM projtest.vw03_refPoints
  ) t1
  ORDER BY 1
;

-----------
-- REPORTS:

CREATE VIEW projtest.vw02_proj_cmp_raw AS
 SELECT auth_name ||' (srid'||srid||')' as proj_name,
  '`'|| ghs ||'`' AS ghs,
  city_name,
  round( m2/1000.0^2, 5) as km2,
  round( ST_Area(geom)/1000.0^2, 5) as proj_km2
 FROM (
  SELECT i.*, s.ghs, s.city_name, s.elevation,
         ST_Area(s.geom,true) AS m2, 
         ST_Transform(s.geom, i.srid) as geom
  FROM projtest.vw01_SRIDs i, projtest.vw05_samples s
  WHERE s.country_code='BR'
 ) t1
 ORDER BY 1,2
;

CREATE VIEW projtest.vw04_proj_cmp_full AS
 SELECT proj_name, 
    ghs ||' ('|| city_name ||')' as ghs_and_city,
    km2,
    proj_km2,
    round(100*abs(km2-proj_km2)/km2, 1)::text || '%' AS proj_diff
 FROM projtest.vw02_proj_cmp_raw
;

CREATE VIEW projtest.vw06_proj_cmp_summary AS
 SELECT proj_name, round( 100*avg( abs(km2-proj_km2)/km2 ), 1)::text||'%' AS proj_diff_avg
 FROM projtest.vw02_proj_cmp_raw
 GROUP BY 1
 ORDER BY 1
;

CREATE VIEW projtest.vw04_area_factors AS
 -- adapted from https://gis.stackexchange.com/q/491266/7505
 SELECT '`'||ghs||'`' as ghs, city_name, elevation,
  round( sea_m2/1000^2, 5) as sea_km2,
  round( sea_m2*afat/1000^2, 5) as elev_km2,
  round(100.0*afat - 100, 4)::text||'%' km2_change
 FROM (
  SELECT *, ST_Area(geom,true) AS sea_m2, 
            projtest.area_correction_factor(geom,elevation) as afat
  FROM projtest.vw05_samples
 ) t1 ORDER BY 1,2
;

/* ----- SHOW report:
SELECT * FROM projtest.vw04_proj_cmp_full ;
SELECT * FROM projtest.vw06_proj_cmp_summary;
SELECT * FROM projtest.vw04_area_factors;
*/
