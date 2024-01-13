/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM PortfolioProject..NashvilleHousing;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


SELECT SaleDateConverted, CONVERT(DATE,SaleDate)
FROM PortfolioProject..NashvilleHousing;

-- This should work, but for some reason it does not.
UPDATE NashvilleHousing
SET SaleDate = CONVERT(DATE,SaleDate);


ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate);



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data


SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL;


SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;


-- This will have made the column with the address we want in to the empty PropertyAddresses
SELECT NH1.ParcelID, NH1.PropertyAddress, NH2.ParcelID, NH2.PropertyAddress,
ISNULL(NH1.PropertyAddress,NH2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing NH1
JOIN PortfolioProject..NashvilleHousing NH2
	ON NH1.ParcelID = NH2.ParcelID
	AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL;


-- We can also write a string instead of addid existing column info with ISNULL
UPDATE NH1
SET PropertyAddress = ISNULL(NH1.PropertyAddress,NH2.PropertyAddress)
FROM PortfolioProject..NashvilleHousing NH1
JOIN PortfolioProject..NashvilleHousing NH2
	ON NH1.ParcelID = NH2.ParcelID
	AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- First we use Substring to separate the address and city

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;

-- This takes away everything after the comma
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
-- This line tells us where the comma is, it´s a number so we can take it out with the -1
--, CHARINDEX(',', PropertyAddress)
FROM PortfolioProject..NashvilleHousing;


-- Now we name another column to move the city into and separate the address and city..
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing;


-- Now we make those 2 new columns into to the actual table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 );

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress));


-- Lets use ParseName for this to separate all 3.

-- Now let´s look at the Owner Address wich has the same thing but also a state
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing;

-- Parsename looks for '.' not comma, but we can Replace the comma
-- Then we get the las part, the state, so we add the second and first ones, then we switch them around to go address first.
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM PortfolioProject..NashvilleHousing;


-- Now we make those 3 new columns into to the actual table again
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1);



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

-- As we see here, there are 399 N:s and 52 Y:s so we need to chance them into Yes and No.
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing;


UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	END;

-- Now there are only Yes and No values


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- Removing data from database in not Standard, usually it is done only to clean the duplicates into temptables


-- This is how we see all the Duplicates
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Now we Delete them
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

-- Checking if it worked (104 rows affected) though
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

-- Again don´t do this to your raw data at a company!!


SELECT *
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate;