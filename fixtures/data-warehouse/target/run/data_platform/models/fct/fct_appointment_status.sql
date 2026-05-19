
  
    

create or replace transient table dw_dev.dev_jkizer.fct_appointment_status
    copy grants
    
    
    as (select 
    appointment_status_id,
    appointment_id,
    appointment_status,
    note,
    name_code,
    creation_datetime as status_creation_datetime,
    creation_datetime_utc as status_creation_datetime_utc,
    u.user_name as appointment_status_user_name,
    lag(appointment_status) over (partition by appointment_id order by creation_datetime asc) as prev_status,
    lag(creation_datetime) over (partition by appointment_id order by creation_datetime asc) as prev_status_datetime,
    timestampdiff('seconds', lag(creation_datetime) over (partition by appointment_id order by creation_datetime asc), creation_datetime) as interval_seconds,
    lead(appointment_status) over (partition by appointment_id order by creation_datetime asc) as next_status,
    lead(creation_datetime) over (partition by appointment_id order by creation_datetime asc) as next_status_datetime,
    rank() over (partition by appointment_id order by creation_datetime asc) as appointment_status_order,
from dw_dev.dev_jkizer_staging.stg_elation_appointment_status s
left join dw_dev.dev_jkizer_staging.stg_elation_user u 
    on s.created_by_user_id = u.user_id
where deletion_datetime is null
    )
;


  