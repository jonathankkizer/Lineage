
  
    

create or replace transient table dw_dev.dev_jkizer.dim_leadingreach_provider
    copy grants
    
    
    as (--union all connected network providers and Suvida providers

select 
    prov.provider_id, 
    prov.provider_npi, 
    prov.first_name, 
    prov.last_name, 
    prov.name_prefix, 
    prov.name_suffix, 
    concat(first_name, ' ', last_name) as full_name, 
    cast(REGEXP_SUBSTR(prov.organization, '/([0-9]+)$', 1, 1, 'e', 1) as int) as organization_id,
    org.name as organization_name,
    REGEXP_SUBSTR(prov.default_location, '/([0-9]+)$', 1, 1, 'e', 1) as default_location_id,
    location.location_name as default_location_name,
    phone.number as main_phone_number, 
    max(specialty.classification) as specialty_classification, 
    max(specialty.specialization) as specialization, 
    prov.created_at, 
    prov.updated_at
from dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider prov
left join dw_dev.dev_jkizer_staging.stg_leadingreach_connected_organization org 
    on org.organization_id = REGEXP_SUBSTR(prov.organization, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer_staging.stg_leadingreach_connected_location location 
    on location.location_id = REGEXP_SUBSTR(prov.default_location, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider_phone phone 
    on phone.provider_id = prov.provider_id and phone.phone_type = 'main'
left join dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider_specialty specialty
    on specialty.provider_id = prov.provider_id
where prov.is_no_npi_number = false and prov.provider_npi is not null
group by all

union all 

select 
    suvida.provider_id, 
    suvida.npi as provider_npi, 
    suvida.first_name, 
    suvida.last_name, 
    suvida.name_prefix, 
    suvida.name_suffix, 
    concat(suvida.first_name, ' ', suvida.last_name) as full_name, 
    27727 as organization_id, 
    'Suvida' as organization_name, 
    REGEXP_SUBSTR(suvida.default_location, '/([0-9]+)$', 1, 1, 'e', 1) as default_location_id,
    location.name as default_location_name, 
    NULL as main_phone_number, 
    max(specialty.classification) as specialty_classification, 
    max(specialty.specialization) as specialization, 
    suvida.created_at, 
    suvida.updated_at
from dw_dev.dev_jkizer_staging.stg_leadingreach_provider suvida 
left join dw_dev.dev_jkizer_staging.stg_leadingreach_location location 
    on location.location_id = REGEXP_SUBSTR(suvida.default_location, '/([0-9]+)$', 1, 1, 'e', 1)
left join dw_dev.dev_jkizer_staging.stg_leadingreach_provider_specialty specialty
    on specialty.provider_id = suvida.provider_id
group by all
    )
;


  