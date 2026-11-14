USE dw_medallion_sales;
GO

EXEC bronze.load_bronze;
EXEC silver.load_silver;
EXEC gold.load_gold;

SELECT COUNT(*)
FROM gold.fact_sales
WHERE customer_key IS NULL OR product_key IS NULL;   -- debe dar 0