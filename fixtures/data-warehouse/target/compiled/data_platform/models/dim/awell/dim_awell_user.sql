--Staff with at least one action in Awell will appear, join back to Rippling by work email
--Awell does not produce a user ID/PK for staff 
select distinct
    aw.user_email as awell_user_email,
    elation.user_id as elation_user_id,
    first_name,
    last_name, 
    full_name,
    rip.is_active,
    title,
    department,
    work_location,
    work_location_state,
    work_location_city, 
    job_family_name, 
    is_actively_seeing_patients,
from dw_dev.dev_jkizer_staging.stg_awell_user_actions aw
left join dw_dev.dev_jkizer.dim_rippling_staff rip 
    on lower(trim(rip.work_email)) = lower(trim(aw.user_email))
left join dw_dev.dev_jkizer_staging.stg_elation_user elation 
    on trim(aw.user_email) = trim(elation.user_email)