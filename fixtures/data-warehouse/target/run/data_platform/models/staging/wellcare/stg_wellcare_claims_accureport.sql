
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellcare_claims_accureport
  
  copy grants
  
  
  as (
    with adj_paid_amounts as (
	select
		receivedmonth as received_month, 
		claim_number as claim_id,
		detail_line_number as claim_line_number,
		sum(net_amount_paid) as net_amount_paid -- sum to net out any adjustments
	from airbyte_source_prod.wellcare_tx.claims_accureports
	where split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar != 'TX42952_SUVIDAHEAL_claims_2025_08_21.txt'
	group by all
)
select
	MASTER_IPA as master_ipa,
	to_varchar(SEQ_MEMB_ID) as member_id,
	coalesce(
		try_to_date(ACTIVITY_DATE, 'MM/DD/YYYY'),
		try_to_date(ACTIVITY_DATE, 'YYYY-MM-DD')
	) as activity_date,
	SEQ_PCP_ID as seq_pcp_id,
	SUBSCRIBER_ID as subscriber_id,
	PCP_FIRST_NAME as pcp_first_name,
	PCP_LAST_NAME as pcp_last_name,
	EXTERNAL_PCP_ID as external_pcp_id,
	LOB as line_of_business,
	case 
		when CLAIM_TYPE = 'INST' then 'institutional'
		when CLAIM_TYPE = 'PROF' then 'professional'
	end as claim_type,
	to_varchar(CLAIM_NUMBER) as claim_id,
	AUTH_NUMBER as auth_number,
	to_varchar(PLACE_OF_SERVICE_1) as place_of_service_code,
	DENIAL_REASON_LIST as denial_reason_list,
	trim(replace(DIAGNOSIS_1, '.', '')) as diagnosis_1,
	trim(replace(DIAGNOSIS_2, '.', '')) as diagnosis_2,
	trim(replace(DIAGNOSIS_3, '.', '')) as diagnosis_3,
	trim(replace(DIAGNOSIS_4, '.', '')) as diagnosis_4,
	trim(replace(DIAGNOSIS_5, '.', '')) as diagnosis_5,
	trim(replace(DIAGNOSIS_6, '.', '')) as diagnosis_6,
	trim(replace(DIAGNOSIS_7, '.', '')) as diagnosis_7,
	trim(replace(DIAGNOSIS_8, '.', '')) as diagnosis_8,
	trim(replace(DIAGNOSIS_9, '.', '')) as diagnosis_9,
	trim(replace(DIAGNOSIS_10, '.', '')) as diagnosis_10,
	trim(replace(DIAGNOSIS_11, '.', '')) as diagnosis_11,
	trim(replace(DIAGNOSIS_12, '.', '')) as diagnosis_12,
	trim(replace(DIAGNOSIS_13, '.', '')) as diagnosis_13,
	trim(replace(DIAGNOSIS_14, '.', '')) as diagnosis_14,
	trim(replace(DIAGNOSIS_15, '.', '')) as diagnosis_15,
	trim(replace(DIAGNOSIS_16, '.', '')) as diagnosis_16,
	trim(replace(DIAGNOSIS_17, '.', '')) as diagnosis_17,
	trim(replace(DIAGNOSIS_18, '.', '')) as diagnosis_18,
	trim(replace(DIAGNOSIS_19, '.', '')) as diagnosis_19,
	trim(replace(DIAGNOSIS_20, '.', '')) as diagnosis_20,
	trim(replace(DIAGNOSIS_21, '.', '')) as diagnosis_21,
	trim(replace(DIAGNOSIS_22, '.', '')) as diagnosis_22,
	trim(replace(DIAGNOSIS_23, '.', '')) as diagnosis_23,
	trim(replace(DIAGNOSIS_24, '.', '')) as diagnosis_24,
	trim(replace(DIAGNOSIS_25, '.', '')) as diagnosis_25,
	DIAGNOSIS_ICD_VERSION_1 as diagnosis_icd_version_1,
	DIAGNOSIS_ICD_VERSION_2 as diagnosis_icd_version_2,
	DIAGNOSIS_ICD_VERSION_3 as diagnosis_icd_version_3,
	DIAGNOSIS_ICD_VERSION_4 as diagnosis_icd_version_4,
	DIAGNOSIS_ICD_VERSION_5 as diagnosis_icd_version_5,
	DIAGNOSIS_ICD_VERSION_6 as diagnosis_icd_version_6,
	DIAGNOSIS_ICD_VERSION_7 as diagnosis_icd_version_7,
	DIAGNOSIS_ICD_VERSION_8 as diagnosis_icd_version_8,
	DIAGNOSIS_ICD_VERSION_9 as diagnosis_icd_version_9,
	DIAGNOSIS_ICD_VERSION_10 as diagnosis_icd_version_10,
	DIAGNOSIS_ICD_VERSION_11 as diagnosis_icd_version_11,
	DIAGNOSIS_ICD_VERSION_12 as diagnosis_icd_version_12,
	DIAGNOSIS_ICD_VERSION_13 as diagnosis_icd_version_13,
	DIAGNOSIS_ICD_VERSION_14 as diagnosis_icd_version_14,
	DIAGNOSIS_ICD_VERSION_15 as diagnosis_icd_version_15,
	DIAGNOSIS_ICD_VERSION_16 as diagnosis_icd_version_16,
	DIAGNOSIS_ICD_VERSION_17 as diagnosis_icd_version_17,
	DIAGNOSIS_ICD_VERSION_18 as diagnosis_icd_version_18,
	DIAGNOSIS_ICD_VERSION_19 as diagnosis_icd_version_19,
	DIAGNOSIS_ICD_VERSION_20 as diagnosis_icd_version_20,
	DIAGNOSIS_ICD_VERSION_21 as diagnosis_icd_version_21,
	DIAGNOSIS_ICD_VERSION_22 as diagnosis_icd_version_22,
	DIAGNOSIS_ICD_VERSION_23 as diagnosis_icd_version_23,
	DIAGNOSIS_ICD_VERSION_24 as diagnosis_icd_version_24,
	DIAGNOSIS_ICD_VERSION_25 as diagnosis_icd_version_25,
	to_varchar(BILL_TYPE) as bill_type_code,
	to_varchar(DRG_CODE) as drg_code,
	to_varchar(SERVICE_PROVIDER_ID) as service_provider_id,
	PROVIDER_LAST_NAME as provider_last_name,
	PROVIDER_FIRST_NAME as provider_first_name,
	PATIENT_STATUS as patient_status,
	PROVIDER_PAR_STAT as provider_par_stat,
	PROVIDER_SPEC as provider_spec,
	VM_FULL_NAME as vm_full_name,
	coalesce(
		try_to_date(SERVICE_DATE, 'MM/DD/YYYY'),
		try_to_date(SERVICE_DATE, 'YYYY-MM-DD')
	) as claim_start_date,
	coalesce(
		try_to_date(SERVICE_THRU_DATE, 'MM/DD/YYYY'),
		try_to_date(SERVICE_THRU_DATE, 'YYYY-MM-DD')
	) as claim_end_date,
	coalesce(
		try_to_date(SERVICE_DATE, 'MM/DD/YYYY'),
		try_to_date(SERVICE_DATE, 'YYYY-MM-DD')
	) as claim_line_start_date,
	coalesce(
		try_to_date(SERVICE_THRU_DATE, 'MM/DD/YYYY'),
		try_to_date(SERVICE_THRU_DATE, 'YYYY-MM-DD')
	) as claim_line_end_date,
	PROCEDURE_CODE_1 as procedure_code_1,
	PROCEDURE_CODE_TYPE_1 as procedure_code_1_type,
	PROCEDURE_ICD_VERSION_1 as procedure_code_1_version,
	PROCEDURE_MODIFIER_1_1 as procedure_code_1_modifier_1,
	PROCEDURE_MODIFIER_1_2 as procedure_code_1_modifier_2,
	PROCEDURE_MODIFIER_1_3 as procedure_code_1_modifier_3,
	PROCEDURE_MODIFIER_1_4 as procedure_code_1_modifier_4,
	PROCEDURE_CODE_2 as procedure_code_2,
	PROCEDURE_CODE_TYPE_2 as procedure_code_2_type,
	PROCEDURE_ICD_VERSION_2 as procedure_code_2_version,
	PROCEDURE_MODIFIER_2_1 as procedure_code_2_modifier_1,
	PROCEDURE_MODIFIER_2_2 as procedure_code_2_modifier_2,
	PROCEDURE_MODIFIER_2_3 as procedure_code_2_modifier_3,
	PROCEDURE_MODIFIER_2_4 as procedure_code_2_modifier_4,
	PROCEDURE_CODE_3 as procedure_code_3,
	PROCEDURE_CODE_TYPE_3 as procedure_code_3_type,
	PROCEDURE_ICD_VERSION_3 as procedure_code_3_version,
	PROCEDURE_MODIFIER_3_1 as procedure_code_3_modifier_1,
	PROCEDURE_MODIFIER_3_2 as procedure_code_3_modifier_2,
	PROCEDURE_MODIFIER_3_3 as procedure_code_3_modifier_3,
	PROCEDURE_MODIFIER_3_4 as procedure_code_3_modifier_4,
	PROCEDURE_CODE_4 as procedure_code_4,
	PROCEDURE_CODE_TYPE_4 as procedure_code_4_type,
	PROCEDURE_ICD_VERSION_4 as procedure_code_4_version,
	PROCEDURE_MODIFIER_4_1 as procedure_code_4_modifier_1,
	PROCEDURE_MODIFIER_4_2 as procedure_code_4_modifier_2,
	PROCEDURE_MODIFIER_4_3 as procedure_code_4_modifier_3,
	PROCEDURE_MODIFIER_4_4 as procedure_code_4_modifier_4,
	REVENUE_CODE_1 as revenue_code_1,
	REVENUE_CODE_2 as revenue_code_2,
	REVENUE_CODE_3 as revenue_code_3,
	REVENUE_CODE_4 as revenue_code_4,
	QUANTITY as service_unit_quantity,
	BILLED_AMOUNT as billed_amount,
	ALLOWED_AMOUNT as allowed_amount,
	COPAYMENT_1_AMOUNT as copayment_amount,
	coalesce(apa.net_amount_paid, c.net_amount_paid) as paid_amount,
	CLAIM_STATUS as claim_status,
	PROCESSING_STATUS as processing_status,
	coalesce(
		try_to_date(POST_DATE, 'YYYY-MM-DD'),
		try_to_date(POST_DATE, 'MM/DD/YYYY')
	) as paid_date,
	coalesce(
		try_to_date(CHECK_DATE, 'YYYY-MM-DD'),
		try_to_date(CHECK_DATE, 'MM/DD/YYYY')
	) as check_date,
	coalesce(
		try_to_date(ADMISSION_DATE, 'YYYY-MM-DD'),
		try_to_date(ADMISSION_DATE, 'MM/DD/YYYY')
	) as admission_date,
	to_varchar(SERVICE_PROVIDER_NPI) as rendering_npi,
	to_varchar(DETAIL_LINE_NUMBER) as claim_line_number,
	DETAIL_SUB_LINE_CODE as detail_sub_line_code,
	RECEIVEDMONTH as receivedmonth,
	'Wellcare/Centene' as data_source,
	split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
	dense_rank() over (
		partition by date_trunc(month, claim_line_start_date) order by date(RECEIVEDMONTH, 'YYYYMM') desc, 

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 desc
	) as _rn,
	date(RECEIVEDMONTH, 'YYYYMM') as last_update,
	min(date(RECEIVEDMONTH, 'YYYYMM')) over (partition by to_varchar(CLAIM_NUMBER), to_varchar(DETAIL_LINE_NUMBER)) as first_received_date,
	iff(vm_full_name = 'SUVIDAHEALTHCARENPHO', '882864363', null) as rendering_tin
from airbyte_source_prod.wellcare_tx.claims_accureports c
left join adj_paid_amounts apa
	on c.claim_number = apa.claim_id
	and c.detail_line_number = apa.claim_line_number
	and c.RECEIVEDMONTH = apa.received_month
where DETAIL_SUB_LINE_CODE in ('X', '0.')
and src_file_name != 'TX42952_SUVIDAHEAL_claims_2025_08_21.txt'
  );

