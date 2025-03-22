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
  WHERE srid IN (952019,9377,955001,955010,955030,955032)
;
CREATE VIEW projtest.vw03_refPoints AS
  SELECT * FROM ( VALUES
    (ST_Point(-46.63333,-23.550,4326), 'Sao Paulo', 760 ), 
    (ST_Point(-68.13333,-16.496,4326), 'La Paz', 3650 ) 
  ) t1 (pt_geom,city_name,elevation)
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
 SELECT auth_name as proj_name,
  '`'|| ghs ||'`' AS ghs,
  city_name,
  round( m2/1000.0^2, 5) as km2,
  round( ST_Area(geom)/1000.0^2, 5) as proj_km2
 FROM (
  SELECT i.*, s.ghs, s.city_name, s.elevation,
         ST_Area(s.geom,true) AS m2, 
         ST_Transform(s.geom, i.srid) as geom
  FROM projtest.vw01_SRIDs i, projtest.vw05_samples s
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

----- SHOW report:

SELECT * FROM projtest.vw04_proj_cmp_full ;
SELECT * FROM projtest.vw06_proj_cmp_summary;
SELECT * FROM projtest.vw04_area_factors;
