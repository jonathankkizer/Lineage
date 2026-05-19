with source as (

    select * from airbyte_source_prod.candid_health_prod.export_service_line_projected_financials

),

renamed as (

    select
        service_line_id,
        organization_id,
        organization_name,
        procedure_code,
        billed_amount_dollars,
        expected_allowed_amount_dollars,
        expected_allowed_amount_source,
        expected_adjustment_amount_dollars,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed