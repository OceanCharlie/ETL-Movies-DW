USE DB_Movies;
GO

/* Membuat Stored Procedure Table dimensi */
CREATE OR ALTER PROCEDURE DW_Movies.load_dimensions
AS
BEGIN
    -- Hapus data lama (opsional, tergantung strategi SCD)
    DELETE FROM DW_Movies.dim_writer;
    DELETE FROM DW_Movies.dim_genre;
    DELETE FROM DW_Movies.dim_director;
    DELETE FROM DW_Movies.dim_country;
    DELETE FROM DW_Movies.dim_language;

    INSERT INTO DW_Movies.dim_language (language_name)
    SELECT DISTINCT Languages
    FROM transformasi.tmdb
    WHERE Languages IS NOT NULL;

    INSERT INTO DW_Movies.dim_country (country_name)
    SELECT DISTINCT Country
    FROM transformasi.tmdb
    WHERE Country IS NOT NULL;

    INSERT INTO DW_Movies.dim_director (director_name)
    SELECT DISTINCT directors
    FROM transformasi.imdb
    WHERE directors IS NOT NULL;

    INSERT INTO DW_Movies.dim_genre (genre_name)
    SELECT DISTINCT genres
    FROM transformasi.imdb
    WHERE genres IS NOT NULL;

    INSERT INTO DW_Movies.dim_writer (writer_name)
    SELECT DISTINCT writers
    FROM transformasi.imdb
    WHERE writers IS NOT NULL;
END;
GO

/* Membuat stored procedure tabel fakta */
CREATE OR ALTER PROCEDURE DW_Movies.load_fact_movies
AS
BEGIN
    TRUNCATE TABLE DW_Movies.fact_movies;

    INSERT INTO DW_Movies.fact_movies (
        title,
        budget,
        revenue,
        vote_average,
        vote_count,
        popularity,
        genre_key,
        language_key,
        country_key,
        director_key,
        writer_key
    )
    SELECT
        vm.title,
        vm.budget,
        vm.revenue,
        vm.averageRating,
        vm.numVotes,
        vm.rank_score,
        genre.genre_key,
        lang.language_key,
        country.country_key,
        director.director_key,
        writer.writer_key
    FROM transformasi.valid_match_movies AS vm
    LEFT JOIN DW_Movies.dim_genre AS genre 
        ON vm.genres = genre.genre_name
    LEFT JOIN DW_Movies.dim_language AS lang 
        ON vm.Languages = lang.language_name
    LEFT JOIN DW_Movies.dim_country AS country 
        ON vm.Country = country.country_name
    LEFT JOIN DW_Movies.dim_director AS director 
        ON vm.directors = director.director_name
    LEFT JOIN DW_Movies.dim_writer AS writer 
        ON vm.writers = writer.writer_name;
END;
GO

-- Eksekusi Prosedur Load
EXEC DW_Movies.load_dimensions;
EXEC DW_Movies.load_fact_movies;