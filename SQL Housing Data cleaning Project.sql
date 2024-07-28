
--DATA CLEANING OF HOUSING DATA, Download the dateset [https://tinyurl.com/ep22zk7e]

/*
Housing Data Cleaning Project

Skills used: Joins, CTE's, Windows Functions,  Converting Data Types, Date Formating
*/


SELECT *
FROM apple.dbo.nashville_housing$
;


-- create a stagging table 
USE apple;
DROP TABLE IF EXISTS stagging_max;



SELECT *
INTO stagging_max
FROM apple.dbo.nashville_housing$
;



-- return the new table 'stagging_max'

SELECT *
FROM stagging_max
;



-- Step 1. date formatting, removing of the time stamp

SELECT SaleDate
FROM stagging_max
;




SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM stagging_max
;



--  create a column for newly separated column

ALTER TABLE stagging_max
ADD ConvertedSaleDate DATE
;



UPDATE stagging_max
SET ConvertedSaleDate = CONVERT(DATE, SaleDate)
FROM stagging_max
;



-- Populate the missing records using 'SELF JOIN' 
-- considering 'PropertyAddress' column

SELECT *
FROM stagging_max
WHERE  PropertyAddress is NULL
;



SELECT t1.PropertyAddress,t1.ParcelID, t2.PropertyAddress, t2.ParcelID,
ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM stagging_max AS t1
JOIN stagging_max AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID < > t2.UniqueID 
	WHERE t1.PropertyAddress IS NULL
;



-- replace the missing values, update the record by populating the NULL VALUE of t1 with records of t2 

UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM stagging_max AS t1
JOIN stagging_max AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID < > t2.UniqueID 
	WHERE t1.PropertyAddress IS NULL
;




-- Format 'PropertyAddress column to individual addree and city using substring string functon

SELECT 
	SUBSTRING(PropertyAddress, 1, 
	CHARINDEX(',', PropertyAddress)-1), 
	SUBSTRING(PropertyAddress, 
	CHARINDEX(',', PropertyAddress) + 1, 
	LEN(PropertyAddress))
FROM stagging_max  
;



-- create a new columns name for the two newly separared column

ALTER TABLE stagging_max
ADD  PropertySplitAddress NVARCHAR(255)
;



UPDATE stagging_max
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, 
						   CHARINDEX(',', PropertyAddress)-1)
;


ALTER TABLE stagging_max
ADD PropertySplitCity NVARCHAR(255)
;



UPDATE stagging_max
SET PropertySplitCity = SUBSTRING(PropertyAddress, 
						CHARINDEX(',', PropertyAddress) + 1, 
						LEN(PropertyAddress))
;




-- format 'OwnerAdress' column to individual address, city, and state using parsename function,
-- much more eaiser to use than previous substring

SELECT PARSENAME(OwnerAddress, 1)
FROM stagging_max
;



--NOTE 'PARSENAME' function locate only the full stop/priod in the string
-- we will convert the delimiter from cormer to period using 'REPLACE' function

SELECT REPLACE(OwnerAddress, ',', '.')
FROM stagging_max
;



-- combine the the function, 'PARSENAME and REPLACE' function and duplicate the query 
-- into adress, city and state.

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM stagging_max
;



SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
FROM stagging_max
;



SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM stagging_max
;


-- we create three respective new columns for the separated 'OwnerAddress' column

ALTER TABLE stagging_max
ADD SplitOwnerAddress NVARCHAR(255)
;



UPDATE stagging_max
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
;



ALTER TABLE stagging_max
ADD SplitOwnerCity NVARCHAR(255)
;



UPDATE stagging_max
SET SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
;



ALTER TABLE stagging_max
ADD SplitOwnerState NVARCHAR(255)
;


UPDATE stagging_max
SET SplitOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
;



-- transfrom SplitOwnerState column futher by populating the NULL values with state

SELECT DISTINCT(SplitOwnerState) 
FROM stagging_max
;



SELECT DISTINCT(SplitOwnerState), ISNULL(SplitOwnerState, 'TN')
FROM stagging_max
;



UPDATE stagging_max
SET SplitOwnerState = ISNULL(SplitOwnerState, 'TN')
FROM stagging_max
;


SELECT SplitOwnerState 
FROM stagging_max
WHERE SplitOwnerState IS NULL
;



-- trim 'SplitOwnerState' column

SELECT TRIM(SplitOwnerState)
FROM stagging_max
;



UPDATE  stagging_max
SET SplitOwnerState = TRIM(SplitOwnerState)
FROM stagging_max
;



-- clean the 'SoldAsVacant' by tranforming column into binary data (YES and NO)

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM stagging_max
GROUP BY SoldAsVacant
ORDER BY 2
;


-- Use case statement to convert the strings to YES and No

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM stagging_max
;



-- Create new cloumn for the transfrom 'SoldAsVacant' column

ALTER TABLE stagging_max
ADD SoldAsVacantCC NVARCHAR(50)
;



UPDATE  stagging_max 
SET SoldAsVacantCC = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
;



-- confirmation of the transformation 'SoldAsVacant'

SELECT DISTINCT(SoldAsVacantCC), COUNT(SoldAsVacantCC)
FROM stagging_max
GROUP BY SoldAsVacantCC
;



-- Reomve the duplicate recored using window function 'ROW_NUMBER'
-- assign row number to the table to check for duplicate record

SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					PropertyAddress,
					SalePrice,
					LegalReference
					ORDER BY UniqueID
						) AS row_num
FROM stagging_max
;



-- use common table expression to query the block of code

WITH duplicate_CTE AS
(
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					PropertyAddress,
					SalePrice,
					LegalReference
					ORDER BY UniqueID
						) AS row_num
FROM stagging_max
)
SELECT *
FROM duplicate_CTE
WHERE row_num > 1
;

-- Delet the duplicate 'row_num' where the value is greathan 1

WITH duplicate_CTE AS
(
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID, 
					PropertyAddress,
					SalePrice,
					LegalReference
					ORDER BY UniqueID
						) AS row_num
FROM stagging_max
)
DELETE
FROM duplicate_CTE
WHERE row_num > 1
;



-- Drop columns that is not neccessary for analysis 

ALTER TABLE stagging_max
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict
;




-- populate the missing records in 'OwnerName value with no Real Estate

SELECT OwnerName, ISNULL(OwnerName, 'Real Estate')
FROM stagging_max
WHERE OwnerName IS NULL
;



UPDATE stagging_max
SET OwnerName = ISNULL(OwnerName, 'Real Estate')
FROM stagging_max
WHERE OwnerName IS NULL
;



-- check for null value for 'Acreage' column for null value and replace with zero 

SELECT Acreage, ISNULL(Acreage, '0.0')
FROM stagging_max
WHERE Acreage IS NULL
;


UPDATE stagging_max
SET Acreage = ISNULL(Acreage, '0.0')
FROM stagging_max
WHERE Acreage IS NULL
;



-- check null value for 'LandValue' column

SELECT LandValue, ISNULL(LandValue, '0.0000')
FROM stagging_max
WHERE LandValue IS NULL
;




UPDATE stagging_max
SET LandValue = ISNULL(LandValue, '0.0')
FROM stagging_max
WHERE LandValue IS NULL
;



-- continued the process untill all the NULL value from respective column is transfromed 
-- while for string variable we make use of 'CAST' funcrin to convert the datatype to string
-- populate the 'SplitOwnerAddress' with no record

SELECT SplitOwnerAddress, ISNULL(CAST(SplitOwnerAddress AS NVARCHAR), 'NO RECORDS FOUNDS')
FROM stagging_max
WHERE SplitOwnerAddress IS NULL
;



UPDATE stagging_max
SET SplitOwnerAddress = ISNULL(CAST(SplitOwnerAddress AS NVARCHAR), 'NO RECORDS FOUNDS')
FROM stagging_max
WHERE SplitOwnerAddress IS NULL
;


-- populate the 'SplitOwnerCity' with no record

SELECT SplitOwnerCity, ISNULL(CAST(SplitOwnerCity AS NVARCHAR), 'No record')
FROM stagging_max
WHERE SplitOwnerCity IS NULL
;



UPDATE stagging_max
SET SplitOwnerCity = ISNULL(CAST(SplitOwnerAddress AS NVARCHAR), 'No record')
FROM stagging_max
WHERE SplitOwnerCity IS NULL
;



SELECT *
FROM stagging_max 
;

--THE END OF THE TRANSFORMATION


