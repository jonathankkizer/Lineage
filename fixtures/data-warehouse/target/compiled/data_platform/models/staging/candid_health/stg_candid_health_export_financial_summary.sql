with source as (

    select * from airbyte_source_prod.candid_health_prod.export_financial_summary

),

renamed as (

    select
        encounter_id,
        claim_id,
        try_to_timestamp(updated_at) as updated_at,
        organization_id,
        is_persisted_financial_summary_record_stale,
        billed_amount_cents / 100.0 as billed_amount,
        allowed_amount_cents / 100.0 as allowed_amount,
        patient_responsibility_cents / 100.0 as patient_responsibility,
        insurance_paid_amount_cents / 100.0 as insurance_paid_amount,
        insurance_adjustment_amount_cents / 100.0 as insurance_adjustment_amount,
        patient_paid_amount_cents / 100.0 as patient_paid_amount,
        patient_adjustment_amount_cents / 100.0 as patient_adjustment_amount,
        patient_balance_amount_cents / 100.0 as patient_balance_amount,
        copay_amount_cents / 100.0 as copay_amount,
        deductible_amount_cents / 100.0 as deductible_amount,
        coinsurance_amount_cents / 100.0 as coinsurance_amount,
        claim_balance_amount_cents / 100.0 as claim_balance_amount,
        insurance_write_off_amount_cents / 100.0 as insurance_write_off_amount,
        organization_name,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed