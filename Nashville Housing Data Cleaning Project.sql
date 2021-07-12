
-- Cleaning data in SQL
---------------------------------------------------------------------------------------------------------

-- View the data
select * from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
order by PropertyAddress

-- First I will change the format of SaleDate

select SaleDate, CONVERT(date, SaleDate)
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

update [Nashville Houseing]
set SaleDate = CONVERT(Date, SaleDate)

select SaleDate from [Nashville Houseing]

-- This did not work, so we will try another approach

alter table [Nashville Houseing]
add SaleDateConverted Date;
update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set SaleDateConverted = CONVERT(Date, SaleDate)

-- View our results to check
select SaleDate, SaleDateConverted from [Nashville Houseing]


----------------------------------------------------------------------------------

-- Now to populate the property address data where there are null values. 



select * from [Nashville Houseing]

-- We will separate the street name and suburb name into different columns

select PropertyAddress 
from [Nashville Houseing]
where PropertyAddress is null

-- can see that there are null values for some rows

select * 
from [Nashville Houseing]
order by ParcelID

-- if we look at the data, we can see that rows with the same Parcel ID wil have the same ProperyAddress.
-- Lets use this to populate the Null values in the data
-- We want to join the table onto itself where the parcel ID's equal and the UniqueID does not equal. This will line up all of our properties with other sales.
-- We only want to see lines with a Null value as this is what we will be populating
-- We also only want to see Parcel ID's and Property Address'
-- Use ISNULL function to obtain b.PropertyAddress values where a.PropertyAddress is Null.

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing] a
join [Portfolio Project - Nashville Housing Data]..[Nashville Houseing] b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- Now we have our new column of correct PropertyAddress data, we will want to update our table

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing] a
join [Portfolio Project - Nashville Housing Data]..[Nashville Houseing] b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- run the first join cell to check we no longer have null values


-----------------------------------------------------------------------------------------------------

-- Now to break out our address column into seperate columns (street, Suburb)


select PropertyAddress 
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

-- Lets use substring to select a portion of the string data in each column
-- We will use the comma to deliminate the values.
-- We will use CHARINDEX to identify the index of the comma character in each string.

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

--Now that we have separated the data into new columns, we will want to update the table to include these.

-- Street
alter table [Nashville Houseing]
add PropertyStreet Nvarchar(255);

update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

-- Suburb
alter table [Nashville Houseing]
add PropertySuburb Nvarchar(255);

update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set PropertySuburb = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Lets check our table updated correcly
select * from [Nashville Houseing]


--------------------------------------------------------------------------------------------------------------

-- Lets have a look at OwnerAddress


select ownerAddress from [Nashville Houseing]

-- Lets separate these values out using a different method, PARSENAME.
-- Since PARSENAME looks for '.' we will need to replace the commas.

select
PARSENAME(Replace(OwnerAddress, ',', '.' ),3),
PARSENAME(Replace(OwnerAddress, ',', '.' ),2),
PARSENAME(Replace(OwnerAddress, ',', '.' ),1)
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

-- Now we will update our table similarly to before.

-- Street
alter table [Nashville Houseing]
add OwnerStreet Nvarchar(255);

update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set OwnerStreet = PARSENAME(Replace(OwnerAddress, ',', '.' ),3)

-- Suburb
alter table [Nashville Houseing]
add OwnerSuburb Nvarchar(255);

update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set OwnerSuburb = PARSENAME(Replace(OwnerAddress, ',', '.' ),2)

-- State
alter table [Nashville Houseing]
add OwnerState Nvarchar(255);

update [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
set OwnerState = PARSENAME(Replace(OwnerAddress, ',', '.' ),1)

-- Check to see our updates were processed successfully
select * from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]



----------------------------------------------------------------------------------------


-- Now lets have a look at all the different values in the SoldAsVacant column


select Distinct(SoldAsVacant), count(SoldAsVacant)
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
group by SoldAsVacant
order by 2 desc

-- We will update this so we only have two possible outcomes(Yes, No)

select SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant 
	   End
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

-- Lets update the table

update [Nashville Houseing]
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant 
	   End


----------------------------------------------------------------------------------------

-- Lets remove duplicates from the data
-- we will use a CTE so we can select the data where the row number is greater than 1


with RowNumCTE AS(
select *,
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 order by 
					UniqueID) row_num
	
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
--order by ParcelID
)

select * 
--delete 
from RowNumCTE
where row_num > 1
order by PropertyAddress


------------------------------------------------------------------------------------------------


-- Delete unused columns
-- (We would not usually do this to the raw data)

select * 
from [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]

ALTER TABLE [Portfolio Project - Nashville Housing Data]..[Nashville Houseing]
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict


-----------------------------------------------------------------------------------------------

-- Thats it! Now we have a cleaner data set that is much more user friendly fore exploring and analysing.