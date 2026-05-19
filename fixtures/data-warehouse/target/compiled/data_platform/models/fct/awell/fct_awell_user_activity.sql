-- Table grain is one row per action per object
-- Awell only returns user email data on assigned tasks that have been completed (through Retool)
-- The rest of the object types (step, pathway, track) won't be assigned to one specific user -- the whole team should be completing a careflow through tasks populated in Retool
select
    act.activity_id,
    act.action,
    act.status,
    act.resolution,
    act.object_id as object_definition_id,
    act.object_type,
    act.object_name,
    act.status as object_status,
    act.activity_date,
    act.activity_timestamp,
    act.care_flow_id,
    cf.title as care_flow_name,
    cf.status as care_flow_status,
    act.orchestrated_instance_id,
    act.orchestrated_track_id,
    act.orchestrated_step_id,
    act.track_id as track_definition_id,
    act.track_name,
    act.step_name,
    a.action_name,
    act.scheduled_date,
    act.completion_date,
    date(dateadd(day, act.duration_in_days, act.start_date)) as due_date,
    iff(datediff(day, due_date, completion_date) <=0, 1, 0) as is_completed_on_time,
    a.action_started_at,
    a.action_completed_at,
    a.duration_in_seconds,
    patient.awell_patient_id,
    patient.elation_id,
    patient.suvida_id,
    patient.full_name as patient_full_name,
    patient.location_name,
    user.awell_user_email,
    user.elation_user_id,
    user.full_name as staff_full_name,
    user.title,
    user.department,
    user.work_location
from dw_dev.dev_jkizer_staging.stg_awell_activities act
left join dw_dev.dev_jkizer_staging.stg_awell_user_actions ua
    on ua.activity_id = act.activity_id
    and ua.user_action_index = 1
left join dw_dev.dev_jkizer.dim_awell_user user
    on user.awell_user_email = ua.user_email
left join dw_dev.dev_jkizer_staging.stg_awell_actions a
    on a.action_id = act.orchestrated_instance_id
left join dw_dev.dev_jkizer_staging.stg_awell_care_flows cf
    on cf.care_flow_id = act.care_flow_id
left join dw_dev.dev_jkizer.dim_awell_patient patient
    on patient.awell_patient_id = cf.patient_id