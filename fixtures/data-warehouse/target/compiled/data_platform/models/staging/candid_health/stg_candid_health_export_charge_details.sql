with source as (

    select * from airbyte_source_prod.candid_health_prod.export_charge_details

),

renamed as (

    select
        transaction_id,
        try_to_date(service_date) as service_date,
        billing_provider_npi,
        billing_provider_tax_id,
        billing_provider_id,
        rendering_provider_npi,
        rendering_provider_id,
        service_facility_name,
        service_facility_address1,
        service_facility_city,
        service_facility_state,
        service_facility_zip_code,
        service_facility_id,
        cpt,
        quantity,
        place_of_service_code,
        payer_plan_group_id,
        organization_id,
        organization_name,
        status,
        charge_id,
        modifiers,
        external_organization_id,
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id

    from source

)

select * from renamed