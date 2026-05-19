
  
    

create or replace transient table dw_dev.dev_jkizer.patient_inpatient_encounter
    copy grants
    
    
    as (/*
    SUVIDA UNIFIED INPATIENT ENCOUNTER MODEL

    Purpose: Single source of truth for inpatient admissions, combining:
    - Census data (most recent 3 months): Timely data from census tracking
    - Claims data (>3 months old): Complete, adjudicated historical data

    Data Source Switching Logic (aligns with patient_member_month):
    - Recent admissions (last 3 months): Census data
    - Historical admissions (>3 months): Claims data

    Key Metrics Calculated:
    - 30-day readmission flags and rates
    - Total admissions (excludes Airtable-only entries)
    - Time-based groupings (month, quarter, year)
*/

with census_data as (
    -- Recent admissions from census tracking (last 3 months)
    select
        suvida_id,
        md5(cast(coalesce(cast(census_grouping_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_inpatient_encounter_skey,
        admit_date,
        discharge_date,
        facilities as facility_name,
        length_of_stay,
        diagnosis_codes as diagnosis_code,
        diagnosis as diagnosis_description,
        null as total_paid,
        'census' as data_source_flag,
        iff(source_types = 'Airtable Manual Entry', true, false) as is_airtable_only_admission,
        is_bamboo_only_event as is_bamboo_only_admission,
    from dw_dev.dev_jkizer.patient_census_event
    where is_inpatient = 1
    and admit_date >= dateadd(month, -3, date_trunc(month, current_date()))
),

claims_data as (
    -- Historical admissions from claims data (>3 months old)
    select
        pci.suvida_id,
        md5(cast(coalesce(cast(temp_encounter_type_key as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_inpatient_encounter_skey,
        min(pci.encounter_start_date) as admit_date,
        max(pci.encounter_end_date) as discharge_date,
        listagg(pci.facility_name, ' | ') as facility_name,
        datediff(day, min(pci.encounter_start_date), max(pci.encounter_end_date)) as length_of_stay,
        listagg(pci.primary_diagnosis_code, ' | ') as diagnosis_code,
        listagg(pci.primary_diagnosis_description, ' | ') as diagnosis_description,
        sum(pci.paid_amount) as total_paid,
        'claims' as data_source_flag,
        false as is_airtable_only_admission,
        false as is_bamboo_only_admission,
    from dw_dev.dev_jkizer.patient_claim_inpatient pci
    where pci.encounter_type = 'acute inpatient' and pci.encounter_start_date < dateadd(month, -3, date_trunc(month, current_date()))
    group by all
),

unified_data as (
    select * from census_data
    union all
    select * from claims_data
),

readmission_calc as (
    /*
        Calculate readmission metrics and time-based groupings

        30-Day Readmission Logic:
        - Looks back to previous discharge date (via LAG window function)
        - If current admission is within 30 days of previous discharge, flags as readmission
        - Partitioned by suvida_id to track readmissions per patient
    */
    select
        *,

        -- Time period groupings for reporting
        monthname(admit_date) as admit_month_name,
        case
            when month(admit_date) in (1,2,3) then 'Q1' || year(admit_date)
            when month(admit_date) in (4,5,6) then 'Q2' || year(admit_date)
            when month(admit_date) in (7,8,9) then 'Q3' || year(admit_date)
            when month(admit_date) in (10,11,12) then 'Q4' || year(admit_date)
        end as admit_quarter_year,
        year(admit_date) as admit_year,

        -- Get previous discharge date for readmission calculation
        lag(discharge_date) over (partition by suvida_id order by admit_date) as prev_discharge_date

    from unified_data
)

select
    *,

    -- Flag admissions occurring within 30 days of previous discharge
    case
        when prev_discharge_date is not null
             and datediff(day, prev_discharge_date, admit_date) <= 30
        then true
        else false
    end as is_30_day_readmission,

    -- Rolling 12-month window for claims data (months 3-15 in the past)
    -- Used for trend analysis comparing complete historical claims periods
    iff(date_trunc('month', admit_date) between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date())), true, false) as is_claim_rolling_12_window,

from readmission_calc
order by suvida_id, admit_date desc
    )
;


  