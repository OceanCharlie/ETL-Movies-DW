USE DB_Movies;
GO

/* Membuat Skema */
CREATE SCHEMA ekstraksi;
GO

CREATE SCHEMA transformasi;
GO

CREATE SCHEMA DW_Movies;
GO

-- 1. Tabel Staging (Ekstraksi)
/* Membuat Table Pada Skema Ekstraksi */
IF OBJECT_ID('ekstraksi.imdb_stg', 'U') IS NOT NULL
    DROP TABLE ekstraksi.imdb_stg;
GO

CREATE TABLE ekstraksi.imdb_stg (
	[tconst] VARCHAR(20),
    [primaryTitle] VARCHAR(255),
    [startYear] INT,
    [rank_score] INT,
    [averageRating] DECIMAL(3,1),
    [numVotes] INT,
    [runtimeMinutes] INT,
    [directors] VARCHAR(MAX),
    [writers] VARCHAR(MAX),
    [genres] VARCHAR(255)
);

IF OBJECT_ID('ekstraksi.tmdb_stg', 'U') IS NOT NULL
    DROP TABLE ekstraksi.tmdb_stg;
GO

CREATE TABLE ekstraksi.tmdb_stg (
	[IMDb_ID] VARCHAR(MAX),
	[Title] VARCHAR(MAX),
	[Year] INT,
	[Runtime] INT,
	[Director] VARCHAR(MAX),
    [Writer] VARCHAR(MAX),
    [Budget] BIGINT,
    [Revenue] BIGINT,
	[Country] VARCHAR(MAX),
	[Languages] VARCHAR(MAX)
);

-- 2. Tabel Transformasi
/* Membuat table pada schema transformasi */
CREATE TABLE transformasi.imdb (
    [tconst] VARCHAR(20),
    [primaryTitle] VARCHAR(255),
    [startYear] INT,
    [rank_score] INT,
    [averageRating] DECIMAL(3,1),
    [numVotes] INT,
    [runtimeMinutes] INT,
    [directors] VARCHAR(MAX),
    [writers] VARCHAR(MAX),
    [genres] VARCHAR(255)
);

CREATE TABLE transformasi.tmdb (
	[IMDb_ID] VARCHAR(MAX),
	[Title] VARCHAR(MAX),
	[Year] INT,
	[Runtime] INT,
	[Director] VARCHAR(MAX),
    [Writer] VARCHAR(MAX),
    [Budget] BIGINT,
    [Revenue] BIGINT,
	[Country] VARCHAR(MAX),
	[Languages] VARCHAR(MAX),
    -- Kolom Staging sementara untuk Cleansing
    runtime_raw VARCHAR(MAX),
	budget_raw VARCHAR(MAX),
    revenue_raw VARCHAR(MAX)
);

-- 3. Tabel Data Warehouse (Load)
/* Membuat Table Dimensi */
CREATE TABLE DW_Movies.dim_language (
    language_key INT IDENTITY(1,1) PRIMARY KEY,
    language_name VARCHAR(MAX)
);

CREATE TABLE DW_Movies.dim_country (
    country_key INT IDENTITY(1,1) PRIMARY KEY,
    country_name VARCHAR(MAX)
);

CREATE TABLE DW_Movies.dim_director (
    director_key INT IDENTITY(1,1) PRIMARY KEY,
    director_name VARCHAR(MAX)
);

CREATE TABLE DW_Movies.dim_genre (
    genre_key INT IDENTITY(1,1) PRIMARY KEY,
    genre_name VARCHAR(MAX)
);

CREATE TABLE DW_Movies.dim_writer (
	writer_key INT IDENTITY(1,1) PRIMARY KEY,
	writer_name VARCHAR(MAX)
);

/* Membuat Table Fact */
IF OBJECT_ID('DW_Movies.fact_movies', 'U') IS NOT NULL
    DROP TABLE DW_Movies.fact_movies;
GO

CREATE TABLE DW_Movies.fact_movies (
    movie_id INT IDENTITY(1,1) PRIMARY KEY,
    title VARCHAR(MAX),
    budget BIGINT,
    revenue BIGINT,
    profit AS (revenue - budget) PERSISTED,
    vote_average DECIMAL(3,1),
    vote_count INT,
    popularity INT,

    genre_key INT,
    language_key INT,
    country_key INT,
    director_key INT,
    writer_key INT,

    FOREIGN KEY (genre_key) REFERENCES DW_Movies.dim_genre(genre_key),
    FOREIGN KEY (language_key) REFERENCES DW_Movies.dim_language(language_key),
    FOREIGN KEY (country_key) REFERENCES DW_Movies.dim_country(country_key),
    FOREIGN KEY (director_key) REFERENCES DW_Movies.dim_director(director_key),
    FOREIGN KEY (writer_key) REFERENCES DW_Movies.dim_writer(writer_key)
);