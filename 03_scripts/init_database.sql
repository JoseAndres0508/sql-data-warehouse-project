USE master;
GO

IF DB_ID('dw_medallion_sales') IS NULL
    CREATE DATABASE dw_medallion_sales;
GO

USE dw_medallion_sales;
GO

IF SCHEMA_ID('bronze') IS NULL EXEC('CREATE SCHEMA bronze');
IF SCHEMA_ID('silver') IS NULL EXEC('CREATE SCHEMA silver');
IF SCHEMA_ID('gold')   IS NULL EXEC('CREATE SCHEMA gold');
GO