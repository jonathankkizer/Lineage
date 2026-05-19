
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_rippling_clinical_staff
    copy grants
    
    
    as (--
-- Clinical staff subset of intmdt_rippling_staff
-- whose department maps to 'clinical_staff' in map_rippling_staff.
-- Grain: one row per active clinical staff member.
--

select distinct
    work_email,
    initcap(first_name) as first_name,
    initcap(last_name) as last_name,
    initcap(concat(first_name, ' ', last_name)) as full_name,
    preferred_first_name,
    preferred_last_name,
    is_active,
    staff.title,
    staff.department,
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
    job_family_name
from dw_dev.dev_jkizer.intmdt_rippling_staff staff
left join dw_dev.dev_jkizer_source.map_rippling_staff map 
    on map.department = staff.department
where 
    map.warehouse = 'clinical_staff'
    )
;


  