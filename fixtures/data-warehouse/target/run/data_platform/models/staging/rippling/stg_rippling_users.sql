
  create or replace   view dw_dev.dev_jkizer_staging.stg_rippling_users
  
  copy grants
  
  
  as (
    select
    id,
    created_at,
    updated_at,
    username,
    display_name,
    name_formatted,
    name_given_name,
    name_family_name,
    name_middle_name,
    name_preferred_given_name,
    name_preferred_family_name,
    active,
    timezone,
    locale,
    preferred_language,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.users
  );

