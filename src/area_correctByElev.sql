-- AREA CORRECTION BY ELEVATION
-- AREA CORRECTION FACTOR
-- See https://gis.stackexchange.com/q/491266/7505

DROP SCHEMA IF EXISTS projtest CASCADE
;
CREATE SCHEMA projtest;

CREATE FUNCTION projtest.geodistance(
  alat float,
  alng float,
  blat float,
  blng float,
  earthdia float default 12756*1000.0 -- meters
) RETURNS float AS
$f$
SELECT asin(
  sqrt(
    sin(radians($3-$1)/2)^2 +
    sin(radians($4-$2)/2)^2 *
    cos(radians($1)) *
    cos(radians($3))
  )
) * ($5/1000.0) AS distance;
-- earthdia use 2 * 6378  km = 12756 km
$f$ language SQL IMMUTABLE
;

CREATE FUNCTION projtest.area_correction_factor(
  probe_geom geometry,  -- any geometry
  alt float       -- local elevation in m
) RETURNS float AS $f$
WITH points AS (
  select 
        st_pointn(st_exteriorring($1),1) as p1, 
        st_pointn(st_exteriorring($1),
        (st_numpoints(st_exteriorring($1))/2)::int) as p2
),
earth_rad AS ( 
  select sqrt(
            (((6378137.0^2) * cos(st_y(st_pointn(st_exteriorring($1),1))))^2 + ((6356752.3142^2) * sin(st_y(st_pointn(st_exteriorring($1),1))))^2)/
                ((6378137.0 * cos(st_y(st_pointn(st_exteriorring($1),1))))^2 + (6356752.3142 * sin(st_y(st_pointn(st_exteriorring($1),1))))^2)
            ) as erad
  )
SELECT ---- the CORRECTION FACTOR: ----
    projtest.geodistance(
      st_y((select p1 from points)),
      st_x((select p1 from points)),
      st_y((select p2 from points)),
      st_x((select p2 from points)),
      (SELECT erad FROM earth_rad) + $2
    )
    /
    projtest.geodistance(
      st_y((select p1 from points)), 
      st_x((select p1 from points)),
      st_y((select p2 from points)),
      st_x((select p2 from points)), 
      (SELECT erad FROM earth_rad)
    )
$f$ language SQL immutable;

CREATE VIEW projtest.vw01_area_factors AS
 SELECT '`'||ghs||'`' as ghs, city_name, elevation,
  round( sea_m2/1000^2, 5) as sea_km2,
  round( sea_m2*afat/1000^2, 5) as elev_km2,
  round(100.0*afat - 100, 4)::text||'%' km2_change
 FROM (
  SELECT *, ST_Area(geom,true) AS sea_m2, 
            projtest.area_correction_factor(geom,elevation) as afat
  FROM (
   SELECT *, ST_GeomFromGeoHash(ghs) geom
   FROM generate_series(5,7) t0(ghs_digits), LATERAL ( VALUES
     (ST_GeoHash( ST_Point(-46.63333,-23.550,4326), ghs_digits ), 'Sao Paulo', 760 ), 
     (ST_GeoHash( ST_Point(-68.13333,-16.496,4326), ghs_digits ), 'La Paz', 3650 ) 
   ) t1 (ghs,city_name,elevation)
  ) t2
 ) t3 ORDER BY 1,2
;
-- SELECT * FROM projtest.vw01_area_factors;
