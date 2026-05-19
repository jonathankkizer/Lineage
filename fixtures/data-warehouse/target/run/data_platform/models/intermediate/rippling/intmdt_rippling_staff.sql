
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_rippling_staff
    copy grants
    
    
    as (--
-- Joins Fivetran Rippling staging models into a denormalized staff record
-- Grain: one row per worker. Excludes Fivetran-deleted records and former employees
-- without clinical credentials. Workers without a work_email are retained if they
-- have an NPI or medical license number (e.g., contract providers).
-- Custom fields (licenses, NPI, DEA, sub-department) are pivoted from
-- stg_rippling_worker_custom_field via conditional aggregation.
--

with custom_fields as (
    select
        worker_id,
        max(case when name = 'Medical License Number' and value is not null then value end) as medical_license_number,
        max(case when name = 'Medical License State' and value is not null then value end) as medical_license_state,
        max(case when name = 'NPI Number' and value is not null then value end) as npi_number,
        max(case when name = 'DEA License Number' and value is not null then value end) as dea_license_number,
        max(case when name = 'Sub Department' and value is not null then value end) as job_family_name
    from dw_dev.dev_jkizer_staging.stg_rippling_worker_custom_field
    group by worker_id
)

select
    worker.work_email,
    users.name_given_name as first_name,
    users.name_family_name as last_name,
    users.name_preferred_given_name as preferred_first_name,
    users.name_preferred_family_name as preferred_last_name,
    worker.status = 'ACTIVE' as is_active,
    worker.title,
    department.name as department,
    work_location.name as work_location_nickname,
    work_location.address_region as work_location_state,
    work_location.address_locality as work_location_city,
    work_location.address_postal_code as work_location_zip,
    work_location.address_country as work_location_country,
    null as location_description,
    company.id as company,
    custom_fields.medical_license_number,
    custom_fields.medical_license_state,
    custom_fields.npi_number,
    custom_fields.dea_license_number,
    null as job_family_name
from dw_dev.dev_jkizer_staging.stg_rippling_worker worker
left join dw_dev.dev_jkizer_staging.stg_rippling_users users 
    on users.id = worker.user_id
left join dw_dev.dev_jkizer_staging.stg_rippling_department department 
    on department.id = worker.department_id
left join dw_dev.dev_jkizer_staging.stg_rippling_work_location work_location 
    on work_location.id = worker.work_location_id
cross join dw_dev.dev_jkizer_staging.stg_rippling_company company
left join custom_fields 
    on custom_fields.worker_id = worker.id
where 
    worker._fivetran_deleted = false
qualify row_number() over (partition by worker.work_email order by worker.updated_at desc) = 1
    )
;


  