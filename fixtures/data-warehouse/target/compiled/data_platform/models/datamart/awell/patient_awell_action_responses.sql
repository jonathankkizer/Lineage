--Table grain is one row per response per form
--Each form can have multiple responses to questions 
--Only looks at complete actions 

select 
    md5(cast(coalesce(cast(fct.activity_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dp.definition_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as response_skey,
    fct.activity_id, 
    object_type, 
    object_name, 
    completion_date as activity_date, 
    to_timestamp(completion_date) as activity_timestamp,
    action_started_at as start_date,
    fct.care_flow_id,
    fct.care_flow_name,
    care_flow_status,
    orchestrated_instance_id, 
    track_name,
    step_name,
    action_name,
    dp.definition_id as data_point_definition_id,
    q.title as question_title,
    dp.value_raw as action_value_raw,
    dp.label as action_value_label, 
    dp.value_type as action_value_type,
    awell_patient_id,
    elation_id, 
    suvida_id,
    patient_full_name,
    location_name,
    awell_user_email,
    elation_user_id,
    staff_full_name,
    fct.title,
    department,
    work_location
from dw_dev.dev_jkizer.fct_awell_user_activity fct 
left join dw_dev.dev_jkizer_staging.stg_awell_data_points dp 
    on dp.activity_id = fct.activity_id
left join dw_dev.dev_jkizer_staging.stg_awell_questions q 
    on q.definition_id = dp.definition_id 
    and q.release_id = dp.release_id
where object_type = 'form' and fct.status = 'done' and fct.resolution = 'success'
group by all