
  create or replace   view dw_dev.dev_jkizer_staging.stg_candid_health_export_payment_details
  
  copy grants
  
  
  as (
    with source as (

    select * from airbyte_source_prod.candid_health_prod.export_payment_details

),

renamed as (

    select
        transaction_id,
        try_to_timestamp(payment_posted_date) as payment_posted_date,
        try_to_date(check_date) as check_date,
        claim_status_code,
        payment_type,
        external_payment_id,
        payer_plan_group_id,
        charge_id,
        organization_id,
        organization_name,
        try_to_timestamp(updated_at) as updated_at,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed
  );

