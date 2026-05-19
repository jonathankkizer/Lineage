select 
    elation_id,
    COMPENDIUM_LAST_UPDATED as compendium_last_updated_datetime,
    replace(icd_codes.value:hccCategory, '"', '') as hcc,
    replace(icd_codes.value:hccCategoryDescription, '"', '') as hcc_description,
    replace(icd_codes.value:icdCode, '"', '') as icd_code,
    replace(icd_codes.value:icdCodeDescription, '"', '') as icd_description,
    replace(icd_codes.value:_id, '"', '') as hcc_icd_id,
    date(icd_codes.value:lastUpdated) as icd_last_updated,
    codes:"Confirmed ICD-10 Codes" as confirmed_codes_array
from source_prod.mdportals.suspects,
LATERAL FLATTEN(input => codes:"Confirmed ICD-10 Codes") as hcc_entries,
LATERAL FLATTEN(input => hcc_entries.value) as icd_codes