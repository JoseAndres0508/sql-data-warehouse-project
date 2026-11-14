USE dw_medallion_sales;
GO

CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2,
            @batch_start_time DATETIME2 = SYSDATETIME();

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Loading gold layer';
        PRINT '================================================';

        -- Vaciar todo primero: hechos y luego dimensiones
        TRUNCATE TABLE gold.fact_sales;
        TRUNCATE TABLE gold.dim_customers;
        TRUNCATE TABLE gold.dim_products;

        -- ============================== dim_customers ==============================
        SET @start_time = SYSDATETIME();
        INSERT INTO gold.dim_customers (
            customer_id, customer_number, first_name, last_name,
            country, marital_status, gender, birthdate, create_date
        )
        SELECT
            ci.cst_id,
            ci.cst_key,
            ci.cst_firstname,
            ci.cst_lastname,
            COALESCE(la.cntry, 'n/a'),
            ci.cst_marital_status,
            CASE
                WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
                ELSE COALESCE(ca.gen, 'n/a')
            END,
            ca.bdate,
            ci.cst_create_date
        FROM silver.crm_cust_info ci
        LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
        LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid
        ORDER BY ci.cst_id;
        PRINT '>> dim_customers: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        -- ============================== dim_products ==============================
        SET @start_time = SYSDATETIME();
        INSERT INTO gold.dim_products (
            product_id, product_number, product_name, category_id,
            category, subcategory, maintenance, cost, product_line, start_date
        )
        SELECT
            pn.prd_id,
            pn.prd_key,
            pn.prd_nm,
            pn.cat_id,
            COALESCE(pc.cat, 'n/a'),
            COALESCE(pc.subcat, 'n/a'),
            COALESCE(pc.maintenance, 'n/a'),
            pn.prd_cost,
            pn.prd_line,
            pn.prd_start_dt
        FROM silver.crm_prd_info pn
        LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
        WHERE pn.prd_end_dt IS NULL
        ORDER BY pn.prd_start_dt, pn.prd_key;
        PRINT '>> dim_products: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        -- ============================== fact_sales ==============================
        SET @start_time = SYSDATETIME();
        INSERT INTO gold.fact_sales (
            order_number, product_key, customer_key,
            order_date, shipping_date, due_date,
            sales_amount, quantity, price
        )
        SELECT
            sd.sls_ord_num,
            pr.product_key,
            cu.customer_key,
            sd.sls_order_dt,
            sd.sls_ship_dt,
            sd.sls_due_dt,
            sd.sls_sales,
            sd.sls_quantity,
            sd.sls_price
        FROM silver.crm_sales_details sd
        LEFT JOIN gold.dim_products  pr ON sd.sls_prd_key = pr.product_number
        LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;
        PRINT '>> fact_sales: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows, '
            + CAST(DATEDIFF(MILLISECOND, @start_time, SYSDATETIME()) AS NVARCHAR) + ' ms';

        PRINT '================================================';
        PRINT 'Gold layer loaded in '
            + CAST(DATEDIFF(SECOND, @batch_start_time, SYSDATETIME()) AS NVARCHAR) + ' s';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR loading gold layer';
        PRINT 'Message: ' + ERROR_MESSAGE();
        PRINT 'Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '================================================';
        THROW;
    END CATCH
END
GO