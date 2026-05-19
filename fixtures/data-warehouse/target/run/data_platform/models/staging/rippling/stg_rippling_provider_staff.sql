
  create or replace   view dw_dev.dev_jkizer_staging.stg_rippling_provider_staff
  
  copy grants
  
  
  as (
    -- Any staff with NPI number, PCPs and Nurse Practitioners actively see patients
select distinct
    work_email, 
    initcap(first_name) first_name,
    initcap(last_name) last_name, 
    initcap(concat(first_name,' ', last_name)) as full_name,
    preferred_first_name, 
    preferred_last_name, 
    is_active, 
    source.title, 
    source.department, 
    trim(work_location_nickname) as work_location, 
    work_location_state,
    work_location_city, 
    work_location_zip, 
    work_location_country, 
    location_description, 
    company, 
    medical_license_number, 
    medical_license_state, 
    npi_number, 
    dea_license_number, 
    job_family_name,
    iff(is_active = true and source.department = 'Provider', true, false) as is_actively_seeing_patients
from source_prod.rippling.employee source
left join dw_dev.dev_jkizer_source.map_rippling_staff map on map.department = source.department
where npi_number is not null and map.warehouse = 'provider_staff'
and work_email is not null
  );

