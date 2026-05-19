
  create or replace   view dw_dev.dev_jkizer_staging.stg_devoted_pharmacy_claim
  
  copy grants
  
  
  as (
    select 
	data:ClaimNumber::varchar as claim_id, 
	null as claim_line_number, 
	data:MBI::varchar as patient_id, 
	data:DevotedID::varchar as member_id, 
	data:PrescriberID::varchar as prescribing_provider_npi, 
	data:PharmacyID::varchar as dispensing_provider_npi, 
	data:DateFilled::date as dispensing_date, 
	data:ProductNDC::varchar as ndc_code, 
	try_to_double(data:QuantityDispensed::varchar) as quantity, 
	try_to_double(data:DaysSupply::varchar) as days_supply, 
	try_to_double(data:NumberOfRefills::varchar) as refills, 
	data:DatePaid::date as paid_date, 
	try_to_double(data:TotalPaidAmount::varchar) as paid_amount, 
	to_decimal(null) as allowed_amount, 
	'Devoted' as data_source, 
	'2026-05-11 19:32:14.126160-04:00' as last_update,
	row_number() over (partition by member_id, claim_id order by data:ReportDate::date desc) as _rn
from airbyte_source_prod.devoted.claims_pharmacy
  );

