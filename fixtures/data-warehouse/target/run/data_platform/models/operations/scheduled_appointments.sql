
  
    

create or replace transient table dw_dev.dev_jkizer.scheduled_appointments
    copy grants
    
    
    as (with 

cte_elation_users as (
  select 
    physician_id, 
    user_id as id, 
    user_first_name as first_name, 
    user_last_name as last_name
  from dw_dev.dev_jkizer_staging.stg_elation_user
  where _idx = 1
),

cte_location_id_name as (
  select
    id,
    name
  from elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.service_location
  group by id, name
),

cte_appointments as (
  select
    usr.physician_id as physician,
    usr.first_name || ' ' || usr.last_name as physician_name,
    lctn.name as location,
    appts.*
  from dw_dev.dev_jkizer_staging.stg_elation_appointment appts
  left join cte_elation_users as usr 
    on appts.physician_id = usr.id
  inner join dw_dev.dev_jkizer.dim_patient as pts 
    on appts.elation_id = pts.elation_id
  left join cte_location_id_name as lctn
    on appts.elation_location_id = lctn.id
)

select 
  mati.patient_relationship,
  mati.visit_method,
  mati.department,
  app.physician as physician_id,
  app.physician_id as physician_user_id,
  app.physician_name,
  app.location,
  app.elation_id,
  app.practice_id,
  app.appointment_datetime,
  app.appointment_type,
  app.appointment_description,
  app.appointment_duration,
  app.elation_location_id
from cte_appointments app 
inner join dw_dev.dev_jkizer_source.map_appt_type_info mati 
  on app.appointment_type = mati.appt_type
    )
;


  