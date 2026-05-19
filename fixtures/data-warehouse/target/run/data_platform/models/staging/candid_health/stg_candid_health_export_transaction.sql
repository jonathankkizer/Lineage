
  create or replace   view dw_dev.dev_jkizer_staging.stg_candid_health_export_transaction
  
  copy grants
  
  
  as (
    with source as (

    select * from airbyte_source_prod.candid_health_prod.export_transaction

),

renamed as (

    select
        transaction_id,
        transaction_type,
        voids_transaction_id,
        voided_by_transaction_id,
        try_to_timestamp(transaction_timestamp) as transaction_timestamp,
        organization_id,
        organization_name,
        amount_cents / 100.0 as amount,
        target_id,
        target_type,
        counter_party_id,
        counter_party_type,
        payer_plan_group_id,
        batch_id,
        try_to_timestamp(batch_date) as batch_date,
        encounter_id,
        service_line_id,
        charge_id,
        charge_transaction_id,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed
  );

