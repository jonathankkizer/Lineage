with source as (

    select * from airbyte_source_prod.candid_health_prod.export_informational_adjustment_details

),

renamed as (

    select
        adjustment_detail_id,
        adjustment_id,
        organization_id,
        organization_name,
        try_to_timestamp(adjustment_timestamp) as adjustment_timestamp,
        try_to_timestamp(adjustment_updated_at) as adjustment_updated_at,
        adjustment_type,
        posted_status,
        external_payment_id,
        try_to_date(check_date) as check_date,
        try_to_timestamp(payment_posted_date) as payment_posted_date,
        amount_cents / 100.0 as amount,
        carc,
        patient_id,
        encounter_id,
        service_line_id,
        charge_id,
        remark_codes,
        claim_adjustment_group_code,
        adjustment_reason_code,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed