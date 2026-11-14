USE dw_medallion_sales;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2,
            @batch_start_time DATETIME2 = SYSDATETIME();

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Loading bronze layer';
        PRINT '================================================';

        PRINT '--- CRM tables ---';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_crm\cust_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> crm_cust_info: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_crm\prd_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> crm_prd_info: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_crm\sales_details.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> crm_sales_details: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        PRINT '--- ERP tables ---';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_erp\CUST_AZ12.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> erp_cust_az12: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_erp\LOC_A101.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> erp_loc_a101: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        SET @start_time = SYSDATETIME();
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\dev\base de datos\sql-data-warehouse-project\01_datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
        PRINT '>> erp_px_cat_g1v2: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        PRINT '================================================';
        PRINT 'Bronze layer loaded in '
            + CAST(DATEDIFF(SECOND, @batch_start_time, SYSDATETIME()) AS NVARCHAR) + ' s';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR loading bronze layer';
        PRINT 'Message: ' + ERROR_MESSAGE();
        PRINT 'Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '================================================';
        THROW;
    END CATCH
END
GO