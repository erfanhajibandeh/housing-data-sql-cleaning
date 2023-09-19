-- Use the NashvilleHousing database
USE NashvilleHousing;

-- Select all data from the NashvilleHousing table
SELECT *
FROM dbo.NashvilleHousing;

-- Standardize Date Format
UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate);

-- Populate Property Address Data
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Split Address into Individual Columns (Address, City, State)
UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split Owner Address into Individual Columns (Address, City, State)
UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Change 'Y' and 'N' to 'Yes' and 'No' in "Sold as Vacant" Field
UPDATE dbo.NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Remove Duplicates
WITH DuplicateRemovalCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM dbo.NashvilleHousing
)
DELETE FROM DuplicateRemovalCTE
WHERE row_num > 1;

-- Delete Unused Columns
ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
