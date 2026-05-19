
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellcare_claims_sftp
  
  copy grants
  
  
  as (
    select
    Claim as claim_id,
    Line as claim_line_number,
    case 
        when Prof_Inst = 'INST' then 'INSTITUTIONAL'
        when Prof_Inst = 'PROF' then 'PROFESSIONAL'  
    end as claim_type,
    MEDICARE_NO as patient_id,
    SUBSCRIBER_ID as member_id,
    date(SVC_Date) as claim_start_date,
    date(SVC_Date) as claim_end_date,
    date(SVC_Date) as claim_line_start_date,
    date(SVC_Date) as claim_line_end_date,
    date(null) as admission_date,
    date(null) as discharge_date,
    to_varchar(null) as admit_source_code,
    to_varchar(null) as admit_type_code,
    to_varchar(null) as discharge_disposition_code,
    POS as place_of_service_code,
    to_varchar(null) as bill_type_code,
    DRG as ms_drg_code,
    to_varchar(null) as apr_drg_code,
    to_varchar(null) as revenue_center_code,
    try_to_number(replace(quantity, ',', '')) as service_unit_quantity,
    PROCEDURE as hcpcs_code,
    modifier as hcpcs_modifier_1,
    to_varchar(null) as hcpcs_modifier_2,
    to_varchar(null) as hcpcs_modifier_3,
    to_varchar(null) as hcpcs_modifier_4,
    to_varchar(null) as hcpcs_modifier_5,
    NPI as rendering_npi,
    NPI as billing_npi,
    NPI as facility_npi,
    L_Code as l_code,
    date(Insert_Date) as paid_date,
    try_to_number(Prof_Net, 38, 8) as paid_amount,
    try_to_number(Allowed, 38, 8) as allowed_amount,
    try_to_number(Billed, 38, 8) as charge_amount,
    try_to_number(TOTAL_BILLED_AMT, 38, 8) as total_cost_amount,
    replace(DIAGNOSIS_1, '.', '') as icd10diag1,
    replace(DIAGNOSIS_2, '.', '') as icd10diag2,
    replace(DIAGNOSIS_3, '.', '') as icd10diag3,
    replace(DIAGNOSIS_4, '.', '') as icd10diag4,
    replace(DIAGNOSIS_5, '.', '') as icd10diag5,
    replace(DIAGNOSIS_6, '.', '') as icd10diag6,
    'Wellcare/Centene' as data_source,
    split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
    datefromparts(right(left(src_file_name,8),4),left(src_file_name,2),substring(left(src_file_name,8),3,2)) as last_update,
    row_number() over (partition by SUBSCRIBER_ID, Claim, Line order by datefromparts(right(left(src_file_name,8),4),left(src_file_name,2),substring(left(src_file_name,8),3,2)) desc, date(Insert_Date) desc, L_Code desc) as _rn
from airbyte_source_prod.wellcare_tx.claims_sftp
where Claim is not null
  );

