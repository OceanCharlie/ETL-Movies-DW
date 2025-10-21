USE DB_Movies;
GO

/* Stored procedure untuk memuat data dari staging ke tabel transformasi */
CREATE OR ALTER PROCEDURE transformasi.load_to_transform
AS
BEGIN
    TRUNCATE TABLE transformasi.imdb;
    TRUNCATE TABLE transformasi.tmdb;

    INSERT INTO transformasi.imdb (
        tconst, primaryTitle, startYear, rank_score, averageRating,
        numVotes, runtimeMinutes, directors, writers, genres
    )
    SELECT
        tconst, primaryTitle, startYear, rank_score, averageRating,
        numVotes, runtimeMinutes, directors, writers, genres
    FROM ekstraksi.imdb_stg;

    INSERT INTO transformasi.tmdb (
        IMDb_ID, Title, [Year], Runtime, Director, Writer, Budget, Revenue, Country, Languages
    )
    SELECT
        IMDb_ID, Title, [Year], Runtime, Director, Writer, Budget, Revenue, Country, Languages
    FROM ekstraksi.tmdb_stg;
END;
GO

-- Eksekusi pemuatan data ke tabel transformasi
EXEC transformasi.load_to_transform;
GO

-- DATA CLEANSING IMDB
/* 1. Menghapus baris dengan nilai null */
DELETE FROM transformasi.imdb
WHERE tconst IS NULL OR primaryTitle IS NULL OR startYear IS NULL OR rank_score IS NULL OR averageRating IS NULL OR numVotes IS NULL 
OR runtimeMinutes IS NULL OR directors IS NULL OR writers IS NULL OR genres IS NULL;
GO

/* 2. Menghapus leading/trailing space */
UPDATE transformasi.imdb
SET 
  primaryTitle = LTRIM(RTRIM(primaryTitle)),
  directors = LTRIM(RTRIM(directors)),
  writers = LTRIM(RTRIM(writers)),
  genres = LTRIM(RTRIM(genres));
GO

-- DATA CLEANSING TMDB
/* 1. Menghapus baris dengan nilai null */
DELETE FROM transformasi.tmdb
WHERE IMDb_ID IS NULL 
    OR Title IS NULL 
    OR [Year] IS NULL 
    OR Runtime IS NULL 
    OR Director IS NULL
    OR Writer IS NULL 
    OR Budget IS NULL 
    OR Revenue IS NULL 
    OR Country IS NULL 
    OR Languages IS NULL;
GO

/* 2. Menghapus baris dengan nilai tidak valid/placeholder ('nan', 0) */
DELETE FROM transformasi.tmdb
WHERE 
    Runtime = 0 OR
    Country = 'nan' OR 
    Languages = 'nan' OR 
    Budget = 0 OR 
    Revenue = 0;
GO

/* 3. Menghapus leading/trailing space */
UPDATE transformasi.tmdb
SET 
    Title = LTRIM(RTRIM(Title)),
    Country = LTRIM(RTRIM(Country)),
    Languages = LTRIM(RTRIM(Languages)),
    Director = LTRIM(RTRIM(Director)),
    Writer = LTRIM(RTRIM(Writer));
GO

/* 4. Konversi tipe data numerik (menggunakan kolom raw yang sudah dibuat) */
UPDATE transformasi.tmdb
SET 
  runtime_raw = CAST(runtime AS VARCHAR),
  budget_raw = CAST(budget AS VARCHAR),
  revenue_raw = CAST(revenue AS VARCHAR);

UPDATE transformasi.tmdb
SET 
  runtime = TRY_CAST(LTRIM(RTRIM(runtime_raw)) AS BIGINT),
  budget = TRY_CAST(LTRIM(RTRIM(budget_raw)) AS BIGINT),
  revenue = TRY_CAST(LTRIM(RTRIM(revenue_raw)) AS BIGINT);
GO

/* Membuat View untuk menyimpan film yang berhasil dicocokkan (Valid Match) */
CREATE OR ALTER VIEW transformasi.valid_match_movies AS
SELECT 
    imdb.tconst,
    imdb.startYear,
    imdb.averageRating,
    imdb.numVotes,
    imdb.rank_score,
    imdb.directors,
    imdb.writers,
    imdb.genres,
    imdb.runtimeMinutes,
    imdb.primaryTitle AS title,
    tmdb.Languages,
    tmdb.Country,
    tmdb.Director,
    tmdb.Writer,
    tmdb.Budget,
    tmdb.Revenue,
    (tmdb.Revenue - tmdb.Budget) AS profit
FROM transformasi.imdb AS imdb
JOIN transformasi.tmdb AS tmdb
ON LTRIM(RTRIM(LOWER(imdb.tconst))) = LTRIM(RTRIM(LOWER(tmdb.IMDb_ID)));
GO