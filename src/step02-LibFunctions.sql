/**
 * Install step 2.
 * Module: library of functions (mainly for area correction).
 * Ref: https://gis.stackexchange.com/q/491266/7505 and https://www.linkedin.com/in/jason-balkenbush-99452049/
 */

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
     sin(radians(blat-alat)/2)^2 +
     sin(radians(blng-alng)/2)^2 *
     cos(radians(alat)) *
     cos(radians(blat))
   )
 ) * ($5/1000.0) AS distance;
 -- earthdia use 2 * 6378  km = 12756 km
$f$ language SQL IMMUTABLE
;

CREATE FUNCTION projtest.area_correction_factor(
  probe_geom geometry,  -- any geometry, as "test probe" (sonde)
  alt        float      -- local elevation (altitude) in meters
) RETURNS float AS $f$
WITH probe_points AS (
  select 
        st_pointn(st_exteriorring($1),1) as p1, 
        st_pointn(
          st_exteriorring($1),
          (st_numpoints(st_exteriorring($1))/2)::int
        ) as p2
),
earth_rad AS ( 
  select sqrt(
            (((6378137.0^2) * cos(st_y(p1)))^2 + ((6356752.3142^2) * sin(st_y(p1)))^2)
            /
            ((6378137.0 * cos(st_y(p1)))^2 + (6356752.3142 * sin(st_y(p1)))^2)
         ) as erad
  from probe_points
  )
SELECT ---- the CORRECTION FACTOR: ----
    projtest.geodistance(
      st_y((select p1 from probe_points)),
      st_x((select p1 from probe_points)),
      st_y((select p2 from probe_points)),
      st_x((select p2 from probe_points)),
      (SELECT erad FROM earth_rad) + $2
    )
    /
    projtest.geodistance( 
      st_y((select p1 from probe_points)), 
      st_x((select p1 from probe_points)),
      st_y((select p2 from probe_points)),
      st_x((select p2 from probe_points)), 
      (SELECT erad FROM earth_rad)
    ) -- same as ST_Distance(p1,p2,true)?
$f$ language SQL immutable;
