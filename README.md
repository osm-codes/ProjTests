# ProjTests
Map projection tests of [PROJ.org library](https://PROJ.org)  projections, using PostGIS.

## Install
On Linux with PostgreSQL v9+.
```sh
cd ProjTests/src
cat step0*.sql | psql postgres://postgres@localhost/test
```
## Testing DGGS
Some [DGGS projections](https://www.iso.org/standard/32588.html) with "good fit to WGS84" claims ([ref1](https://doi.org/10.1080/20964471.2022.2094926), [ref2](https://doi.org/10.1080/17538947.2019.1645893)), that are not seems realistic for Brazilian territory.

At [this PostGIS SQL scripts](src), using `ST_Area(geom,true)` as reference of "WGS84 area measure", and `ST_Area(geom)` as projected sample, we can reproduce the `projtest.vw06_proj_cmp_summary` report:

projection label and definition            | proj_diff_avg 
--------------------------------|---------------
_BR:IBGE_  &nbsp; [classical Albers equal-area](https://proj.org/en/stable/operations/projections/aea.html),<br> `+proj=aea +lat_0=-12 +lon_0=-54 +lat_1=-2 +lat_2=-22 +ellps=WGS84`          | 0.0%
*DGGS:001:rHEALPix*  &nbsp; [`+proj=rhealpix`](https://proj.org/en/stable/operations/projections/rhealpix.html) (default `+ellps=GRS80`) | 17.8%
*DGGS:002:rHEALPix*   &nbsp; `+proj=rhealpix +ellps=WGS84` | **17.8%**
 *DGGS:030:ISEA*   &nbsp;  [`+proj=isea`](https://proj.org/en/stable/operations/projections/isea.html)   | 0.5%
 *DGGS:032:ISEA*    &nbsp; `+proj=isea +ellps=WGS84`  | 0.5%

The column `proj_diff_avg` is the average of area-difference of some sample zones (Geohash rectangles with different areas) at Brazil. The VIEW `projtest.vw02_proj_cmp_raw` shows raw data. To see Geohash cells ("ghs" column), use [viewer1](https://geohash.softeng.co/6dxqw4) or [viewer2](https://www.movable-type.co.uk/scripts/geohash.html).

The projection _BR:IBGE_ is the official, used by Census, demonstrating that PROJ Lib can fit to WGS84.

## Testing area distortion by elevation
Using `projtest.vw04_area_factors_summary` we can show that the "WGS84 area measure" distortion (column "km2_change") grows with elevation, and that from \~1 km elevation upwards, the distortion of \~0.01% (or more) cannot be ignored.

city_name         | elevation | km2_change 
-------------------------|----------|------------
Fortaleza                |        20 | 0.0003%
 Uruguaiana               |        70 | 0.0011%
 Manaus                   |        90 | 0.0014%
 Santa Maria              |       110 | 0.0017%
 Trindade (ilha)          |       170 | 0.0027%
 Sao Paulo                |       760 | 0.0120%
 Mané Garrincha (estadio) |      1200 | 0.0188%
 La Paz                   |      3650 | 0.0573%

## License
[CC0](https://creativecommons.org/publicdomain/zero/1.0/).
