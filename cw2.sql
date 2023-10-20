CREATE DATABASE cw2;

--1.Wyznacz liczbę budynków położonych w odległości mniejszej niż 1000 jednostek od głównych rzek costam...

CREATE TABLE IF NOT EXISTS tableBB AS
SELECT p.*
FROM popp p
JOIN majrivers r ON ST_DWithin(p.geom, r.geom, 1000)
WHERE p.f_codedesc = ('Building');

SELECT COUNT(*) AS liczba_budynkow FROM tableBB; --licze budynki

--2. Utwórz tabelę o nazwie airportsNew costamcostam

CREATE TABLE airportsNew AS
SELECT
    name,
    geom,
    elev
FROM airports;

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód. zach ATKA wsch ANNETTE ISLAND
SELECT
    name,
    geom,
    elev
FROM airportsNew
ORDER BY ST_X(geom) ASC --sort wzgl X rasnaco i 1 record
LIMIT 1;
SELECT
    name,
    geom,
    elev
FROM airportsNew
ORDER BY ST_X(geom) DESC
LIMIT 1;
--b)punkt posrodku
WITH midpoint AS (
    SELECT
        ST_LineInterpolatePoint(ST_MakeLine(a.geom, a.geom), 0.5) AS midpoint --punkt na linii łączącej punkty
    FROM
        airports a
    WHERE
        a.name IN ('ATKA', 'ANNETTE ISLAND')
)
INSERT INTO airportsNew (name, geom, elev)
SELECT
    'airportB',
    midpoint,
    2137
FROM
    midpoint;


--3. Wyznacz pole powierzchni obszaru,  mniej niż 1000  najkrótszej linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER” 1481587.4954202627

WITH shortest_line AS (
    SELECT
        ST_ShortestLine(l.geom, a.geom) AS shortest_line
    FROM
        lakes l
    JOIN
        airports a ON a.name = 'AMBLER'
    WHERE
        l.names = 'Iliamna Lake'
)
SELECT
    ST_Area(ST_Intersection(l.geom, ST_Buffer(sl.shortest_line, 1000))) AS powierzchnia --pole przecięciambufora z geome jeziora
FROM
    lakes l
JOIN
    shortest_line sl ON true
WHERE
    l.names = 'Iliamna Lake';

--4 pola typow drzew z bagna i tundry (agreg)

SELECT
    cat,
    SUM(area_km2) AS total_area --zew zapytanie sum dla tych sam cat
FROM
    (
        SELECT cat, area_km2 FROM tundra
        UNION ALL
        SELECT cat, areakm2 FROM swamp
    ) combined_data --podzapytanuie
GROUP BY
    cat
ORDER BY
    cat;
