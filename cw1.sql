CREATE DATABASE cw1;
CREATE EXTENSION postgis;

CREATE TABLE budynkii (
    id serial PRIMARY KEY,
    nazwa VARCHAR,
    geometria geometry(Polygon,0));
CREATE TABLE drogi (
    id serial PRIMARY KEY,
    nazwa VARCHAR,
    geometria geometry(Linestring,4326));
CREATE TABLE punkty_informacyjne (
    id serial PRIMARY KEY,
    nazwa VARCHAR,
    geometria geometry(Point,4326));
INSERT INTO budynkii (id,nazwa,geometria)
VALUES (0,'BuildingA',ST_GeomFromText('POLYGON((8 4, 10 5.4, 8 1.5, 10.5 1.5, 8 4))', 0)),
       (1,'BuildingB',ST_GeomFromText('POLYGON((4 7, 6 7, 4 5, 6 5, 4 7))', 0)),
       (2,'BuildingC',ST_GeomFromText('POLYGON((3 8, 5 8, 3 6, 5 6, 3 8))', 0)),
       (3,'BuildingD',ST_GeomFromText('POLYGON((9 9, 10 9, 9 8, 10 8, 9 9))', 0)),
       (4,'BuildingF',ST_GeomFromText('POLYGON((1 2, 2 2, 1 1, 2 1, 1 2))', 0));

INSERT INTO drogi (id,nazwa,geometria)
VALUES (0,'RoadX',ST_GeomFromText('LINESTRING(0.4 5, 12 4.5)', 0)),
       (1,'RoadY',ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)', 0));

INSERT INTO punkty_informacyjne (id,nazwa,geometria)
VALUES (0,'K',ST_GeomFromText('POINT(6 9.5)', 0)),
       (1,'J',ST_GeomFromText('POINT(6.5 6)', 0)),
       (2,'I',ST_GeomFromText('POINT(9.5 6)', 0)),
       (3,'G',ST_GeomFromText('POINT(1 3.5)', 0)),
       (4,'h',ST_GeomFromText('POINT(5.5 1.5)', 0));


--Wyznacz całkowitą długość dróg w analizowanym mieście
SELECT SUM(ST_Length(geometria::geometry)) AS calkowita_dlugosc_drog
FROM drogi;

-- Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA.
SELECT
    ST_AsText(geometria) AS geometria_wkt,
    ST_Area(geometria) AS pole_powierzchni,
    ST_Perimeter(geometria) AS obwod
FROM budynkii
WHERE nazwa = 'BuildingA'
LIMIT 1;

--Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.
SELECT nazwa, ST_Area(geometria) AS pole_powierzchni
FROM budynkii
ORDER BY nazwa;

--Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ST_Distance(b.geometria, p.geometria) AS najkrotsza_odleglosc
FROM budynkii AS b, punkty_informacyjne AS p
WHERE b.nazwa = 'BuildingC' AND p.nazwa = 'G'
ORDER BY najkrotsza_odleglosc
LIMIT 1;

--Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB.
SELECT ST_Area(ST_Intersection(c.geometria, b.geometria)) AS pole_powierzchni
FROM budynkii AS c, budynkii AS b
WHERE c.nazwa = 'BuildingC' AND b.nazwa = 'BuildingB'
AND ST_Distance(c.geometria, b.geometria) > 0.5;

--Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi o nazwie RoadX. 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

WITH Centroids AS (
    SELECT b.nazwa AS budynek, ST_Centroid(b.geometria) AS centroid
    FROM budynkii AS b),
Road AS (
    SELECT geometria FROM drogi WHERE nazwa = 'RoadX'),
Poligon AS (
    SELECT ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 4326) AS geometria)
SELECT c.budynek,
       ST_Area(ST_Difference(b.geometria, p.geometria)) AS pole_powierzchni
FROM Centroids AS c
JOIN Poligon AS p ON NOT ST_Intersects(c.centroid, p.geometria)
JOIN budynkii AS b ON c.budynek = b.nazwa
WHERE ST_Y(c.centroid) > ST_Y((SELECT ST_PointN(ST_ExteriorRing(geometria), 1) FROM Road));