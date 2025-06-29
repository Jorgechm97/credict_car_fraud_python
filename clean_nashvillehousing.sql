-- clean data with sql dataset by Alex the Analyst
SELECT * FROM portaforlioproject.nashvillehousing;

-- date format on table

SELECT STR_TO_DATE(SaleDate, '%Y-%m-%d') AS SaleDateConverted
FROM portaforlioproject.nashvillehousing;

Update nashvillehousing
SET SaleDate = date(SaleDate);

-- populate property address data

select *
from portaforlioproject.nashvillehousing
-- where PropertyAddress is null
order by ParcelID;

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.PropertyAddress, b.PropertyAddress)
from portaforlioproject.nashvillehousing a
join portaforlioproject.nashvillehousing b
	on a.ParcelID = b.ParcelID
    and a.UniqueID_ <> b.UniqueID_
where a.PropertyAddress is null;

-- desactivate safe mode for update table
set sql_safe_updates = 0;
#for activate safe mode use the same code with the number 1 set sql_safe_updates = 1;

UPDATE portaforlioproject.nashvillehousing a
JOIN portaforlioproject.NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.UniqueID_ <> b.UniqueID_
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- breaking out adress into individual columns (adress, city, state)

select PropertyAddress
from portaforlioproject.nashvillehousing;
-- where PropertyAddress is null
-- order by ParcelID

SELECT 
  CASE 
    WHEN INSTR(PropertyAddress, ',') > 0 THEN 
        SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) 
    ELSE 
        TRIM(PropertyAddress)
  END AS Address,
  CASE 
    WHEN INSTR(PropertyAddress, ',') > 0 THEN 
        SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1, LENGTH(PropertyAddress)) 
    ELSE 
        ''
  END AS Address
FROM portaforlioproject.nashvillehousing;

alter table nashvillehousing
add PropertySplitCity char(255) character set utf8mb4;

update nashvillehousing
set PropertySplitCity = substring(PropertyAddress, instr(PropertyAddress, ',') + 1, length(PropertyAddress));

select PropertySplitCity
from portaforlioproject.nashvillehousing;

select OwnerAddress
from portaforlioproject.nashvillehousing;

SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS FullAddress,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) AS State
FROM portaforlioproject.nashvillehousing;

alter table nashvillehousing
add FullAddress text character set utf8mb4;

update nashvillehousing
set FullAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

alter table nashvillehousing
add City text character set utf8mb4;

update nashvillehousing
set City = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

alter table nashvillehousing
add State text character set utf8mb4;

update nashvillehousing
set State = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1);

select *
from portaforlioproject.nashvillehousing;

-- change Y and N to yes and no in 'sold as vacant' field

select distinct(SoldAsVacant), count(SoldAsVacant)
from portaforlioproject.nashvillehousing
group by SoldAsVacant
order by 2;

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
end as UpdateSoldAsVacant
from portaforlioproject.nashvillehousing;

update nashvillehousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
    else SoldAsVacant
    end;

select distinct(SoldAsVacant), count(SoldAsVacant)
from portaforlioproject.nashvillehousing
group by SoldAsVacant
order by 2;

-- remove duplicates

DELETE n
FROM portaforlioproject.nashvillehousing n
JOIN (
    SELECT UniqueID_
    FROM (
        SELECT UniqueID_,
               @row_number := CASE
                                WHEN @prev_values = CONCAT(ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference)
                                THEN @row_number + 1
                                ELSE 1
                              END AS row_num,
               @prev_values := CONCAT(ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference)
        FROM portaforlioproject.nashvillehousing
        CROSS JOIN (SELECT @row_number := 1, @prev_values := NULL) AS vars
        ORDER BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    ) as subquery
    WHERE row_num > 1
) d ON n.UniqueID_ = d.UniqueID_;

select *
from portaforlioproject.nashvillehousing;

alter table portaforlioproject.nashvillehousing
drop column OwnerAddress, 
drop column TaxDistrict, 
drop column PropertyAddress;

