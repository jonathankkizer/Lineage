
  
    

create or replace transient table dw_dev.dev_jkizer.dim_leadingreach_location
    copy grants
    
    
    as (select 
    location.location_id, 
    location.location_type, 
    location.location_name,
    location.is_default,
    organization_id, 
    npi as organization_npi, 
    name as organization_name, 
    website, 
    org.created_at, 
    org.updated_at
from dw_dev.dev_jkizer_staging.stg_leadingreach_connected_location location 
left join dw_dev.dev_jkizer_staging.stg_leadingreach_connected_organization org  
    on REGEXP_SUBSTR(location.organization, '/([0-9]+)$', 1, 1, 'e', 1) = org.organization_id
    )
;


  