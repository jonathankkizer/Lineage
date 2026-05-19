
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_census_operations
  
  copy grants
  
  
  as (
    with columnar_data as (
    select
        census_event_skey,
        census_integration_skey,
        census_grouping_integration_skey,
        airtable_id,
        to_date("ADMIT DATE - SUPPLEMENTAL") as admit_date_supplemental,
        to_date("DISCHARGE DATE - SUPPLEMENTAL") as discharge_date_supplemental,
        "EVENT TYPE - SUPPLEMENTAL"::varchar as event_type_supplemental,
        "FACILITY NAME - SUPPLEMENTAL"::varchar as facility_name_supplemental,
        coalesce("TRUE EVENT - SUPPLEMENTAL"::boolean, FALSE) as is_true_event_supplemental,
        "TRUE READMISSION - SUPPLEMENTAL"::varchar as is_true_readmission_supplemental,
        "IS PATIENT DECEASED - SUPPLEMENTAL"::varchar as is_patient_deceased_supplemental,
        "DUPLICATE EVENT - SUPPLEMENTAL"::varchar as is_duplicate_event_supplemental,
        "MED REC STATUS - SUPPLEMENTAL"::varchar as med_rec_status_supplemental,
        "PATIENT STILL ADMITTED - SUPPLEMENTAL"::varchar as is_patient_still_admitted,
        "DIAGNOSIS CODES - SUPPLEMENTAL"::varchar as diagnosis_codes_supplemental,
        "DIAGNOSIS - SUPPLEMENTAL"::varchar as diagnosis_supplemental,
        notes::varchar as notes,
        convert_timezone('UTC', 'America/Chicago', to_timestamp("CREATED")) as created_datetime,
        convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
        "LAST MODIFIED BY":"name"::string as last_modified_by_name,
        "LAST MODIFIED BY":"email"::string as last_modified_by_email,
        to_timestamp(run_datetime) as run_datetime
    from source_prod.airtable.src_airtable_census_operations
),

json_data as (
    select
        census_event_skey,
        parse_json(airtable_data) as jd,
        airtable_id,
        convert_timezone('UTC', 'America/Chicago', to_timestamp("LAST MODIFIED")) as last_modified_datetime,
        to_timestamp(run_datetime) as run_datetime
    from source_prod.airtable.src_airtable_census_operations_json
),

json_parsed as (
    select
        census_event_skey,
        null::varchar as census_integration_skey,
        jd:"CENSUS_GROUPING_INTEGRATION_SKEY"::string as census_grouping_integration_skey,
        airtable_id,
        to_date(jd:"Admit Date - Supplemental"::string) as admit_date_supplemental,
        to_date(jd:"Discharge Date - Supplemental"::string) as discharge_date_supplemental,
        jd:"Event Type - Supplemental"::string as event_type_supplemental,
        jd:"Facility Name - Supplemental"::string as facility_name_supplemental,
        coalesce(jd:"True Event - Supplemental"::boolean, FALSE) as is_true_event_supplemental,
        jd:"True Readmission - Supplemental"::string as is_true_readmission_supplemental,
        jd:"Is Patient Deceased - Supplemental"::string as is_patient_deceased_supplemental,
        jd:"Duplicate Event - Supplemental"::string as is_duplicate_event_supplemental,
        jd:"Med Rec Status - Supplemental"::string as med_rec_status_supplemental,
        jd:"Patient Still Admitted - Supplemental"::string as is_patient_still_admitted,
        jd:"Diagnosis Codes - Supplemental"::string as diagnosis_codes_supplemental,
        jd:"Diagnosis - Supplemental"::string as diagnosis_supplemental,
        jd:"Notes"::string as notes,
        convert_timezone('UTC', 'America/Chicago', to_timestamp(jd:"Created"::string)) as created_datetime,
        last_modified_datetime,
        jd:"Last Modified By":"name"::string as last_modified_by_name,
        jd:"Last Modified By":"email"::string as last_modified_by_email,
        run_datetime
    from json_data
),

data as (
    select * from columnar_data
    union all
    select * from json_parsed
)

select
*
from data
qualify row_number() over (partition by census_event_skey order by last_modified_datetime desc) = 1
  );

