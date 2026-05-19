
  create or replace   view dw_dev.dev_jkizer_staging.stg_rippling_worker
  
  copy grants
  
  
  as (
    select
    id,
    created_at,
    updated_at,
    start_date,
    end_date,
    status,
    number,
    title,
    country,
    location_type,
    work_email,
    personal_email,
    gender,
    ethnicity,
    date_of_birth,
    overtime_exemption,
    termination_type,
    termination_reason,
    department_id,
    level_id,
    manager_id,
    user_id,
    work_location_id,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.worker
  );

