CREATE DATABASE cw3;

CREATE EXTENSION postgis;

--Zad.1.
--Znajdź budynki, które zostały costam na przestrzeni roku (pomiędzy 2018 a 2019).


CREATE TABLE nowe_bud AS
SELECT b2019.gid, b2019.polygon_id, b2019.name, b2019.type, b2019.height, b2019.geom FROM t2019_kar_buildings b2019
LEFT OUTER JOIN t2018_kar_buildings b2018 ON b2019.geom=b2018.geom --lewy join z 2019 na geom
WHERE b2018.geom IS NULL; --ogranicza wyniki do tych co nie mają tych samych

SELECT * FROM nowe_bud; --co zmienione

--zad 2
--poi 500m od bud z 1zad

CREATE TABLE nowe_poi AS --ile tych wszystkich nowych jak w 1
SELECT pt19.gid, pt19.poi_id, pt19.link_id, pt19.type, pt19.poi_name, pt19.st_name, pt19.lat, pt19.lon, pt19.geom
FROM t2019_kar_poi_table pt19
LEFT OUTER JOIN t2018_kar_poi_table pt18
ON pt19.geom=pt18.geom
WHERE pt18.geom IS NULL;

SELECT * FROM nowe_poi;

WITH OnePolygon AS ( --obejmuje wszystkie nowe budynki i jest używany do znalezienia POI w srodku
    SELECT ST_Union(ST_Buffer(geom,500)) AS geom
    FROM nowe_bud
)
SELECT p.type, COUNT(*) AS liczba_punktow
FROM OnePolygon g
LEFT JOIN nowe_poi p
ON ST_Within(p.geom, g.geom)
GROUP BY p.type;

--zad 3
--Utwórz ‘streets_reprojected’,  dane z tabeli przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

SELECT * FROM T2019_KAR_STREETS;

CREATE TABLE streets_reprojected AS
SELECT gid,link_id,st_name,ref_in_id,nref_in_id,func_class,speed_cat, fr_speed_l,to_speed_l,dir_travel,
	ST_Transform(geom, 3068) AS geom
FROM T2019_KAR_STREETS;

SELECT * FROM streets_reprojected;
SELECT ST_SRID(geom) FROM streets_reprojected;


--zad 4
-- ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
CREATE TABLE input_points (
	id INT,
	geom GEOMETRY(point, 4326)
);

INSERT INTO input_points VALUES (0, ST_GeomFromText('POINT(8.36093 49.03174)'));
INSERT INTO input_points VALUES (1, ST_GeomFromText('POINT(8.39876 49.00644)'));

SELECT ST_Srid(geom) FROM input_points;
SELECT id, ST_AsText(geom) FROM input_points;

--zad 5
--Zaktualizuj ‘input_points’ tak,punkty te były w układzie współrzędnych DHDN.Berlin/Cassini.

ALTER TABLE input_points
ALTER COLUMN geom
TYPE GEOMETRY(Point, 3068)
USING ST_Transform(geom, 3068);

SELECT ST_Srid(geom) FROM input_points;

--zad 6
--Znajdź wszystkie skrzyżowania, w odległości 200 m od linii ‘input_points’.  Dokonaj reprojekcji geometrii

SELECT count(*) FROM t2019_kar_street_node; --zlicza

SELECT * FROM t2019_kar_street_node
WHERE ST_Within(
	    		geom,
	   			ST_Transform(
				 ST_Buffer(
	 	 		  ST_MakeLine( --tworzy linię, łącząc dwie punkty.
		  		   (SELECT geom FROM input_points WHERE id=0),
		  		   (SELECT geom FROM input_points WHERE id=1)
		 		  ), 200
				 ), 4326
	   			)
	  );

--7
--. Policz jak wiele sklepów sportowych odległości 300 m od parków (LAND_USE_A). 27

SELECT * FROM t2019_kar_land_use_a
SELECT ST_Srid(geom) FROM t2019_kar_land_use_a; --zwraca numer SRID dla geometrii.

SELECT COUNT(*)
FROM t2019_kar_poi_table p
WHERE ST_Within(p.geom,
                (SELECT ST_union(ST_buffer(geom,300))
                 FROM t2019_kar_land_use_a
                 WHERE type='Park (City/County)'))
AND p.type='Sporting Goods Store';

--8.
-- Znajdź punkty przecięcia torów  z ciekami . Zapisz znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

SELECT * FROM t2019_kar_railways;
SELECT * FROM t2019_kar_water_lines;

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT DISTINCT(ST_Intersection(r.geom, w.geom)) AS geom
FROM t2019_kar_railways r, t2019_kar_water_lines w;

SELECT * FROM T2019_KAR_BRIDGES;