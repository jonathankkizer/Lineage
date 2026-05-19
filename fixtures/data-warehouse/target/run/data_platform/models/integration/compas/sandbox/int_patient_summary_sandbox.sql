
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_summary_sandbox
    copy grants
    
    
    as (with provider_rippling_employees as (
    select distinct
        dp.physician_id,
        dp.npi,
        coalesce(drs.work_email, dp.user_email) as email
    from dw_dev.dev_jkizer.dim_provider dp
    left join dw_dev.dev_jkizer.dim_rippling_staff drs
        on dp.npi = drs.npi_number
)

select
    md5(cast(coalesce(cast(ps.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as suvida_id,
    sep.id as elation_id,
    null as sf_account_id,
    sep.first_name,
    sep.last_name,
    null as full_name,
    null as preferred_name,
    sep.dob as birth_date,
    case
        when lower(sep.sex) = 'male' then 'm'
        when lower(sep.sex) = 'female' then 'f'
        else sep.sex
    end as gender,
    iff(lower(sep.race) = 'no race specified', null, sep.race) as race,
    null as secondary_race,
    iff(lower(sep.ethnicity) = 'no ethnicity specified', null, sep.race) as ethnicity,
    null as email,
    sep.phone,
    sep.preferred_language,
    sep.address_address_line1 as address_line_1,
    sep.address_address_line2 as address_line_2,
    sep.address_city as city,
    sep.address_state as state,
    sep.address_zip as zip,
    null as occupation,
    to_boolean(is_active_assignment) as is_active_assignment,
    is_future_assignment,
    iff(is_active_patient = 1, TRUE, FALSE) as is_active_patient,
    elation_status,
    ps.assigned_guia_name,
    ps.provider_name,
    provider_npi,
    prv.physician_id as provider_id,
    case
        when prv.email = 'evaldes@suvidahealthcare.com' then 'ctucker@suvidahealthcare.com'
        when prv.email = 'aordonez@suvidahealthcare.com' then 'wzink@suvidahealthcare.com'
        when prv.email = 'jvaquerano@suvidahealthcare.com' then 'acochran@suvidahealthcare.com'
        when prv.email = 'mrobert@suvidahealthcare.com' then 'tmckamey@suvidahealthcare.com'
        when prv.email = 'anava@suvidahealthcare.com' then 'mbrown@suvidahealthcare.com'
        when prv.email = 'palvarez@suvidahealthcare.com' then 'khanson@suvidahealthcare.com'
        when prv.email = 'ldelatorre@suvidahealthcare.com' then 'mmendis@suvidahealthcare.com'
        else prv.email
    end as provider_email,
    sl.name as location_name,
    sl.id as location_id,
    ps.nearest_location_name,
    ps.nearest_location_distance,
    ps.payer_name,
    ps.payer_plan_code,
    ps.payer_plan_name,
    left(base64_encode(random()), uniform(8, 12, random())) as payer_member_id,
    ps.elation_insurance_plan,
	payer_plan_program_type,
	payer_plan_network_program_type,
	left(base64_encode(random()), uniform(8, 12, random())) as payer_medicare_beneficiary_id,
	ps.payer_assigned_provider_name,
    ps.eligibility_start_month,
    ps.eligibility_max_month,
    ps.dual_status,
    ps.patient_acquisition_type,
    coalesce(num_months_since_eligibility_acquisition, 0) as num_months_since_eligibility_acquisition,
    coalesce(open_quality_gaps, 0) as open_quality_gaps,
    coalesce(number_of_quality_gaps, 0) as num_quality_gaps,
    ps.emr_risk_score_ytd,
    coalesce(num_hcc_diagnoses_ytd, 0) as num_hcc_diagnoses_ytd,
    coalesce(mdportals_suspect_hcc_opportunities_count, 0) as mdportals_suspect_hcc_opportunities_count,
    ps.first_pt_appt_date,
    ps.last_pt_appt_date,
    ps.next_pt_appt_date,
    ps.first_pcp_appt_date,
    ps.last_pcp_appt_date,
    ps.next_pcp_appt_date,
    ps.last_awv_date,
    null as recent_non_visit_note_text,
    'https://sandbox.elationemr.com/patient/' || sep.id as elation_patient_url,
    null as emr_claims_blended_risk_score_adj_ytd,
    sep.created_date as creation_date,
    ps.come_back_to_care_priority,
    ps.num_pcp_visits_ytd,
    high_risk_patient,
    ps.most_recent_height,
    ps.most_recent_height_units,
    ps.most_recent_height_date,
    ps.most_recent_weight,
    ps.most_recent_weight_units,
    ps.most_recent_weight_date
from dw_dev.dev_jkizer_staging.stg_sandbox_ehr_patient sep
left join dw_dev.dev_jkizer_staging.stg_sandbox_patient_mapping spm
    on to_varchar(sep.id) = spm.sandbox_elation_id
left join dw_dev.dev_jkizer.patient_summary ps
    on spm.suvida_id = ps.suvida_id
left join provider_rippling_employees prv
    on ps.provider_npi = prv.npi
left join source_prod.misc.src_ehd_service_locations sl
    on sl.name = 
        case
            when ps.location_name = 'DFW - Oak Cliff' then 'Dallas - Oak Cliff'
            when ps.location_name = 'DFW - Northside' then 'Ft Worth - Northside'
            when ps.location_name = 'Houston - Aldine' then 'Houston-Aldine'
            when ps.location_name = 'Houston - Spring Branch' then 'Houston-Spring Branch'
            when ps.location_name = 'Houston - Pasadena' then 'Houston-Pasadena'
            when ps.location_name = 'Austin - South Austin' then 'Suvida-South-Austin'
            else ps.location_name
        end
    )
;


  