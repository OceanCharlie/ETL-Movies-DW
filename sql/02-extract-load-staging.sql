USE DB_Movies;
GO

/* Membuat stored procedure untuk ETL tahap Ekstraksi */
CREATE OR ALTER PROCEDURE ekstraksi.csv_to_staging
AS
BEGIN
    -- Bersihkan tabel staging sebelum insert baru
    TRUNCATE TABLE ekstraksi.imdb_stg;
    TRUNCATE TABLE ekstraksi.tmdb_stg;
    
    /* Memasukkan data dari imdb.csv */
    BULK INSERT ekstraksi.imdb_stg
    FROM 'C:\Users\OCEAN\Documents\SQL Server Management Studio\Dataset\source\imdb.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',', 
        ROWTERMINATOR = '0x0d0a',
        CODEPAGE = '65001',
        TABLOCK,
        ERRORFILE = 'C:\Users\OCEAN\Documents\SQL Server Management Studio\Dataset\source\imdb_error.log'
    );

    /* Memasukkan data dari tmdb.csv */
    BULK INSERT ekstraksi.tmdb_stg
    FROM 'C:\Users\OCEAN\Documents\SQL Server Management Studio\Dataset\source\tmdb.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',', 
        ROWTERMINATOR = '0x0d0a',
        CODEPAGE = '65001',
        TABLOCK,
        ERRORFILE = 'C:\Users\OCEAN\Documents\SQL Server Management Studio\Dataset\source\tmdb_error.log'
    );
END;
GO

-- Eksekusi Prosedur Ekstraksi
EXEC ekstraksi.csv_to_staging;