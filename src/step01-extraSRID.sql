/**
 * (adapted from pubLib05pgis-extraSRID.sql of https://git.AddressForAll.org/pg_pubLib-v1 )
 * Module: PostGIS general complements. Fragment.
 */

CREATE extension IF NOT EXISTS postgis;

INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) VALUES
   -- -- -- --
(  -- IBGE Albers, SRID number convention in Project DigitalGuard-BR:
  952019,
  'BR:IBGE',
  52019,
  '+proj=aea +lat_0=-12 +lon_0=-54 +lat_1=-2 +lat_2=-22 +x_0=5000000 +y_0=10000000 +ellps=WGS84 +units=m +no_defs',
  $$PROJCS[
  "Conica_Equivalente_de_Albers_Brasil",
  GEOGCS[
    "GCS_SIRGAS2000",
    DATUM["D_SIRGAS2000",SPHEROID["Geodetic_Reference_System_of_1980",6378137,298.2572221009113]],
    PRIMEM["Greenwich",0],
    UNIT["Degree",0.017453292519943295]
  ],
  PROJECTION["Albers"],
  PARAMETER["standard_parallel_1",-2],
  PARAMETER["standard_parallel_2",-22],
  PARAMETER["latitude_of_origin",-12],
  PARAMETER["central_meridian",-54],
  PARAMETER["false_easting",5000000],
  PARAMETER["false_northing",10000000],
  UNIT["Meter",1]
 ]$$
),
  -- -- -- --
( -- Grid of Colombia, IGAC MAGNA-SIRGAS / Origen-Nacional:
  9377, -- official EPSG number
  'CO:IGAC',
  9377,
  '+proj=tmerc +lat_0=4.0 +lon_0=-73.0 +k=0.9992 +x_0=5000000 +y_0=2000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs',
  $$PROJCS[
    "MAGNA-SIRGAS / Origen-Nacional",
    GEOGCS[
      "MAGNA-SIRGAS",
      DATUM[
        "Marco_Geocentrico_Nacional_de_Referencia",
        SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],
        TOWGS84[0,0,0,0,0,0,0],
        AUTHORITY["EPSG","6686"]
      ],
      PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],
      UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],
      AUTHORITY["EPSG","4686"]
    ],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",4.0],
    PARAMETER["central_meridian",-73.0],
    PARAMETER["scale_factor",0.9992],
    PARAMETER["false_easting",5000000],
    PARAMETER["false_northing",2000000],
    UNIT["metre",1,AUTHORITY["EPSG","9001"]],
    AUTHORITY["EPSG","9377"]
  ]$$
),
  -- -- -- --
  --  "DGGS projections" from SRID 955001 to 955099.
  --
( -- rHEALPix default, PROJ v4.8+
  955001,  'DGGS:001:rHEALPix',  1,
  '+proj=rhealpix',
  NULL -- no srtext
),
( -- rHEALPix variant 2, PROJ v4.8+
  955002,  'DGGS:002:rHEALPix',  2,
  '+proj=rhealpix +ellps=WGS84 +south_square=0 +north_square=2',
  NULL -- no srtext
),

( -- QSC default
  955010,  'DGGS:010:QSC',  10,
  '+proj=qsc',
  NULL -- no srtext
),

( -- ISEA default
  955030,  'DGGS:030:ISEA',  30,
  '+proj=isea',
  NULL -- no srtext
),
( -- ISEA variant 2
  955032,  'DGGS:032:ISEA',  32,
  '+proj=isea +ellps=WGS84',
  NULL -- no srtext
)

ON CONFLICT DO NOTHING;
