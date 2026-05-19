with base_data as (
-- Single scan of fct_awell_user_activity with all necessary data and window function
    select 
        *,
        -- Pre-calculate LAG function only for records that need it
        case 
            when object_type in ('pathway', 'track', 'step') and action in ('complete', 'activate')
            then lag(activity_date) over (partition by object_definition_id, care_flow_id, orchestrated_instance_id order by activity_timestamp asc)
            else null
        end as prev_date
    from dw_dev.dev_jkizer.fct_awell_user_activity
    where 
        (object_type in ('pathway', 'track', 'step') and action in ('complete', 'activate'))
        or object_type in ('form', 'message')
        or awell_user_email is not null
),

pathway_track_step_data as (
-- Pre-filtered data for pathway/track/step objects
    select 
        activity_id,
        action,
        object_type,
        object_name,
        object_status,
        activity_date,
        activity_timestamp,
        prev_date,
        due_date,
        care_flow_id,
        care_flow_name,
        care_flow_status,
        orchestrated_instance_id,
        track_name,
        step_name,
        action_name,
        awell_patient_id,
        elation_id,
        suvida_id,
        patient_full_name,
        location_name
    from base_data
    where object_type in ('pathway', 'track', 'step') and action in ('complete', 'activate')
),

form_message_assigned as (
-- Form/message records that are assigned but not completed
    select 
        concat(activity_id, '1') as activity_id, 
        action, 
        object_type, 
        object_name, 
        object_status,
        activity_date, 
        activity_timestamp,
        null as start_date,
        null as duration_days,
        due_date,
        null as is_completed_on_time,
        care_flow_id,
        care_flow_name,
        care_flow_status,
        orchestrated_instance_id, 
        track_name,
        step_name,
        action_name,
        awell_patient_id,
        elation_id, 
        suvida_id,
        patient_full_name,
        location_name,
        awell_user_email,
        elation_user_id,
        staff_full_name,
        title,
        department,
        work_location
    from base_data
    where object_type in ('form', 'message')
),

form_message_completed as (
-- Form/message records that are completed
    select 
        activity_id, 
        'complete' as action, 
        object_type, 
        object_name, 
        object_status,
        completion_date as activity_date, 
        to_timestamp(completion_date) as activity_timestamp,
        action_started_at as start_date,
        round((duration_in_seconds / (24 * 60 * 60)),0) as duration_days,
        due_date,
        is_completed_on_time,
        care_flow_id,
        care_flow_name,
        care_flow_status,
        orchestrated_instance_id, 
        track_name,
        step_name,
        action_name,
        awell_patient_id,
        elation_id, 
        suvida_id,
        patient_full_name,
        location_name,
        awell_user_email,
        elation_user_id,
        staff_full_name,
        title,
        department,
        work_location
    from base_data
    where object_type in ('form', 'message')
    and status = 'done' and resolution = 'success'
),

-- Optimize user lookups by breaking down OR conditions
care_flow_users_by_flow as (
    select distinct
        care_flow_id,
        awell_user_email,
        elation_user_id,
        staff_full_name,
        title,
        department,
        work_location
    from base_data
    where awell_user_email is not null and care_flow_id is not null
),

care_flow_users_by_track as (
    select distinct
        orchestrated_track_id,
        awell_user_email,
        elation_user_id,
        staff_full_name,
        title,
        department,
        work_location
    from base_data
    where awell_user_email is not null and orchestrated_track_id is not null
),

care_flow_users_by_step as (
    select distinct
        orchestrated_step_id,
        awell_user_email,
        elation_user_id,
        staff_full_name,
        title,
        department,
        work_location
    from base_data
    where awell_user_email is not null and orchestrated_step_id is not null
)

-- Pathway/track/step data with optimized user joins
select distinct
    md5(cast(coalesce(cast(pts.activity_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(coalesce(cf.awell_user_email, ct.awell_user_email, cs.awell_user_email) as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as care_flow_track_skey,
    pts.activity_id,
    pts.action,
    pts.object_type,
    pts.object_name,
    pts.object_status,
    pts.activity_date,
    pts.activity_timestamp,
    pts.prev_date as start_date,
    datediff('day', pts.prev_date, pts.activity_date) as duration_days,
    pts.due_date,
    null as is_completed_on_time,
    pts.care_flow_id,
    pts.care_flow_name,
    pts.care_flow_status,
    pts.orchestrated_instance_id,
    pts.track_name,
    pts.step_name,
    pts.action_name,
    pts.awell_patient_id,
    pts.elation_id,
    pts.suvida_id,
    pts.patient_full_name,
    pts.location_name,
    coalesce(cf.awell_user_email, ct.awell_user_email, cs.awell_user_email) as awell_user_email,
    coalesce(cf.elation_user_id, ct.elation_user_id, cs.elation_user_id) as elation_user_id,
    coalesce(cf.staff_full_name, ct.staff_full_name, cs.staff_full_name) as staff_full_name,
    coalesce(cf.title, ct.title, cs.title) as title,
    coalesce(cf.department, ct.department, cs.department) as department,
    coalesce(cf.work_location, ct.work_location, cs.work_location) as work_location
from pathway_track_step_data pts
left join care_flow_users_by_flow cf 
    on cf.care_flow_id = pts.orchestrated_instance_id
left join care_flow_users_by_track ct 
    on ct.orchestrated_track_id = pts.orchestrated_instance_id  
left join care_flow_users_by_step cs 
    on cs.orchestrated_step_id = pts.orchestrated_instance_id

union all

-- Form/message assigned records
select distinct 
    md5(cast(coalesce(cast(activity_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(action as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as care_flow_track_skey,
    activity_id,
    action,
    object_type,
    object_name,
    object_status,
    activity_date,
    activity_timestamp,
    start_date,
    duration_days,
    due_date,
    is_completed_on_time,
    care_flow_id,
    care_flow_name,
    care_flow_status,
    orchestrated_instance_id,
    track_name,
    step_name,
    action_name,
    awell_patient_id,
    elation_id,
    suvida_id,
    patient_full_name,
    location_name,
    awell_user_email,
    elation_user_id,
    staff_full_name,
    title,
    department,
    work_location
from form_message_assigned

union all

-- Form/message completed records
select distinct 
    md5(cast(coalesce(cast(activity_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(action as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(awell_user_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as care_flow_track_skey,
    activity_id,
    action,
    object_type,
    object_name,
    object_status,
    activity_date,
    activity_timestamp,
    start_date,
    duration_days,
    due_date,
    is_completed_on_time,
    care_flow_id,
    care_flow_name,
    care_flow_status,
    orchestrated_instance_id,
    track_name,
    step_name,
    action_name,
    awell_patient_id,
    elation_id,
    suvida_id,
    patient_full_name,
    location_name,
    awell_user_email,
    elation_user_id,
    staff_full_name,
    title,
    department,
    work_location
from form_message_completed