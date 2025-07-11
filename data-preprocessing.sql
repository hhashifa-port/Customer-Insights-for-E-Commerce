-- DATA CLEANING

-- rename all columns name change “_” with “ “
ALTER TABLE public."CustomersData" RENAME COLUMN "CustomerID" to "Customer ID";
ALTER TABLE public."CustomersData" RENAME COLUMN "Tenure_Months" to "Tenure Months";

ALTER TABLE public."Discount_Coupon" RENAME COLUMN "Product_Category" to "Product Category";
ALTER TABLE public."Discount_Coupon" RENAME COLUMN "Coupon_Code" to "Coupon Code";
ALTER TABLE public."Discount_Coupon" RENAME COLUMN "Discount_pct" to "Discount";

ALTER TABLE public."Markerting_Spend" RENAME COLUMN "Offline_Spend" to "Offline Spend";
ALTER TABLE public."Markerting_Spend" RENAME COLUMN "Online_Spend" to "Online Spend";

ALTER TABLE public."Online_Sales" RENAME COLUMN "CustomerID" to "Customer ID";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Transaction_ID" to "Transaction ID";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Transaction_Date" to "Transaction Date";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Product_SKU" to "Product SKU";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Product_Description" to "Product Description";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Product_Category" to "Product Category";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Avg_Price" to "Avg Price";
ALTER TABLE public."Online_Sales" RENAME COLUMN "Delivery_Charges" to "Delivery Charges";

ALTER TABLE public."Tax_amount" RENAME COLUMN "Product_Category" to "Product Category";


-- CustomersData | Gender (change F, M with Female, Male)
UPDATE public."CustomersData"
SET "Gender" = (
CASE 
	WHEN "Gender" = 'F' THEN 'Female'
	WHEN "Gender" = 'M' THEN 'Male'
	ELSE NULL
END
);

SELECT "Gender", COUNT(*) AS "SUM"
FROM public."CustomersData"
GROUP BY 1;


-- Discount_Coupon |Discount (change data type to float, divide by 100)
ALTER TABLE public."Discount_Coupon"
ALTER COLUMN "Discount" TYPE FLOAT;

UPDATE public."Discount_Coupon"
SET "Discount" = "Discount" / 100;

SELECT *
FROM public."Discount_Coupon";


-- Marketing_Spend | Date (change format to date)
UPDATE public."Marketing_Spend"
SET "Date" = TO_DATE("Date", 'MM/DD/YYY');

ALTER TABLE public."Marketing_Spend"
ALTER COLUMN "Date" TYPE DATE USING ("Date"::text::date);

SELECT *
FROM public."Marketing_Spend";


-- Online_Sales | Transaction Date (change format to date)
UPDATE public."Online_Sales"
SET "Transaction Date" = TO_DATE("Transaction Date", 'MM/DD/YYY');

ALTER TABLE public."Online_Sales"
ALTER COLUMN "Transaction Date" TYPE DATE USING ("Transaction Date"::text::date);

SELECT "Transaction Date", COUNT(*) AS "SUM"
FROM public."Online_Sales"
GROUP BY 1
ORDER BY 1;


-- Tax_amount | GST	(remove “%”, change type to float, divide by 100)
UPDATE public."Tax_amount"
SET "GST" = REPLACE("GST", '%', '');

ALTER TABLE public."Tax_amount"
ALTER COLUMN "GST" TYPE FLOAT;

UPDATE public."Tax_amount"
SET "GST" = "GST" / 100;

SELECT *
FROM public."Tax_amount";


----------------------------------------
-- no missing value in each tables
-- duplicates checking
SELECT "Customer ID", "Gender", "Location", "Tenure Months", COUNT(*)
FROM public."CustomersData"
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 1;

SELECT "Month", "Product Category", "Coupon Code", "Discount", COUNT(*)
FROM public."Discount_Coupon"
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 1;

SELECT "Date", "Offline Spend", "Online Spend", COUNT(*)
FROM public."Marketing_Spend"
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1;

SELECT 
	"Customer ID", "Transaction ID", "Transaction Date",
	"Product SKU", "Product Description", "Product Category",
	"Quantity", "Avg Price", "Delivery Charges", 
	"Coupon Status", COUNT(*)
FROM public."Online_Sales"
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
HAVING COUNT(*) > 1;

SELECT "Product Category", "GST", COUNT(*)
FROM public."Tax_amount"
GROUP BY 1, 2
HAVING COUNT(*) > 1;


----------------------------------------
-- encode col Month in Disounct Coupon
ALTER TABLE public."Discount_Coupon"
ADD "Month Encoded" INT;

UPDATE public."Discount_Coupon"
SET "Month Encoded" = (
CASE 
	WHEN "Month" = 'Jan' THEN 1
	WHEN "Month" = 'Feb' THEN 2
	WHEN "Month" = 'Mar' THEN 3
	WHEN "Month" = 'Apr' THEN 4
	WHEN "Month" = 'May' THEN 5
	WHEN "Month" = 'Jun' THEN 6
	WHEN "Month" = 'Jul' THEN 7
	WHEN "Month" = 'Aug' THEN 8
	WHEN "Month" = 'Sep' THEN 9
	WHEN "Month" = 'Oct' THEN 10
	WHEN "Month" = 'Nov' THEN 11
	WHEN "Month" = 'Dec' THEN 12
	ELSE NULL
END);


-- checking values: theres only one discount coupon for each product category every month
SELECT "Month Encoded", "Product Category", COUNT(*) 
FROM public."Discount_Coupon"
GROUP BY 1, 2
HAVING COUNT(*) > 1;


-- create month of transaction in online sales table
ALTER TABLE public."Online_Sales"
ADD "Transaction Month" INT;

UPDATE public."Online_Sales"
SET "Transaction Month" = EXTRACT(MONTH FROM "Transaction Date");


-- CREATE TABLE FOR VISUALIZATION
CREATE TABLE public."Online Transaction"
AS(
	SELECT
		public."Online_Sales"."Transaction ID",
		public."Online_Sales"."Transaction Date",
		public."Online_Sales"."Customer ID",
		public."CustomersData"."Gender",
		public."CustomersData"."Location",
		public."CustomersData"."Tenure Months",
		public."Online_Sales"."Product SKU",
		public."Online_Sales"."Product Description",
		public."Online_Sales"."Product Category",
		public."Online_Sales"."Quantity",
		public."Online_Sales"."Avg Price",
		public."Online_Sales"."Delivery Charges",
		public."Online_Sales"."Coupon Status",
		public."Discount_Coupon"."Coupon Code",
		public."Discount_Coupon"."Discount",
		public."Tax_amount"."GST"
	FROM public."Online_Sales"
	LEFT JOIN public."CustomersData" 
		ON public."Online_Sales"."Customer ID" = public."CustomersData"."Customer ID"
	LEFT JOIN public."Discount_Coupon"
		ON public."Online_Sales"."Product Category" = public."Discount_Coupon"."Product Category"
			AND public."Online_Sales"."Transaction Month" = public."Discount_Coupon"."Month Encoded"
	LEFT JOIN public."Tax_amount"
		ON public."Online_Sales"."Product Category" = public."Tax_amount"."Product Category"
	);


-- fill null values
UPDATE public."Online_Transaction"
SET "Coupon Code" = 'NONE'
WHERE "Coupon Code" IS NULL;

UPDATE public."Online_Transaction"
SET "Discount" = 0
WHERE "Discount" IS NULL;

UPDATE public."Online_Transaction"
SET "GST" = 0
WHERE "GST" IS NULL;



----------------------------------------
-- create invoice value column (revenue for each transaction and item level)
ALTER TABLE public."Online_Transaction"
ADD "Invoice Value" FLOAT;

UPDATE public."Online_Transaction"
SET "Invoice Value" = (
CASE 
	WHEN "Coupon Status" = 'Used' THEN ("Quantity" * "Avg Price") 
										* (1 - "Discount") 
										* (1 + "GST") 
										+ ("Delivery Charges")
	ELSE ("Quantity" * "Avg Price") 
		* (1 - 0) 
		* (1 + "GST") 
		+ ("Delivery Charges")
END);

SELECT *
FROM public."CustomersData";



----------------------------------------
-- create new table customers related
SELECT public."CustomersData"."Customer ID", 
	   SUM(public."Online_Transaction"."Invoice Value") AS "Total Invoice",
	   COUNT(DISTINCT public."Online_Transaction"."Transaction ID") AS "Total Transaction",
	   SUM(public."Online_Transaction"."Invoice Value") / COUNT(DISTINCT public."Online_Transaction"."Transaction ID") AS "Average Order Value"
INTO TEMP "About_Cust"
FROM public."CustomersData" LEFT JOIN public."Online_Transaction"
ON public."CustomersData"."Customer ID" = public."Online_Transaction"."Customer ID"
GROUP BY 1;

SELECT *
FROM "About_Cust";

CREATE TABLE public."Customers_Data"
AS(
	SELECT
		public."CustomersData"."Customer ID",
		public."CustomersData"."Gender",
		public."CustomersData"."Location",
		public."CustomersData"."Tenure Months",
		"About_Cust"."Total Invoice",
		"About_Cust"."Total Transaction",
		"About_Cust"."Average Order Value"
	FROM public."CustomersData"
	LEFT JOIN "About_Cust" 
		ON public."CustomersData"."Customer ID" = "About_Cust"."Customer ID"
	);