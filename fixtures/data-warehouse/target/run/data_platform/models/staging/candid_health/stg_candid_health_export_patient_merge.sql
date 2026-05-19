
  create or replace   view dw_dev.dev_jkizer_staging.stg_candid_health_export_patient_merge
  
  copy grants
  
  
  as (
    with source as (

    select * from airbyte_source_prod.candid_health_prod.export_patient_merge

),

renamed as (

    select
        patient_merge_id,
        organization_id,
        organization_name,
        version,
        updating_user_id,
        try_to_timestamp(updated_at) as updated_at,
        deactivated,
        primary_patient_mrn,
        alternative_patient_mrn,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed
  );

