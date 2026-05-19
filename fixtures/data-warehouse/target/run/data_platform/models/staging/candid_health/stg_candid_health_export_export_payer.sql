
  create or replace   view dw_dev.dev_jkizer_staging.stg_candid_health_export_export_payer
  
  copy grants
  
  
  as (
    with source as (

    select * from airbyte_source_prod.candid_health_prod.export_payer

),

renamed as (

    select
        payer_uuid,
        primary_payer_id,
        primary_name,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed
  );

