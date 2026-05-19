--
-- Provider staff subset of intmdt_rippling_staff: employees with an NPI number
-- whose department maps to 'provider_staff' in map_rippling_staff.
-- This includes PCPs and Nurse Practitioners actively seeing patients
-- Grain: one row per active provider.
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
    job_family_name,
    iff(is_active = true and staff.department = 'Provider', true, false) as is_actively_seeing_patients
from dw_dev.dev_jkizer.intmdt_rippling_staff staff
left join dw_dev.dev_jkizer_source.map_rippling_staff map 
    on map.department = staff.department
where
    npi_number is not null
    and map.warehouse = 'provider_staff'
    and work_email not in ('dkoon@suvidahealthcare.com', 'omatuk@suvidahealthcare.com') -- NPI holders who are admin/leadership, not actively seeing patients
    and staff.title not in ('Vice President, Lifestyle Medicine', 'Fitness Instructor', 'Fitness Instructor (Contractor)') -- Lifestyle Medicine titles that are support staff despite provider department