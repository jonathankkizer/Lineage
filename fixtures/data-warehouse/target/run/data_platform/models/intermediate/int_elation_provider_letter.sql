
  
    

create or replace transient table dw_dev.dev_jkizer.int_elation_provider_letter
    copy grants
    
    
    as (

with hosted_share as (
    select
        uq_provider_letter,
        provider_letter_id,
        patient_id,
        practice_id,
        send_to_name,
        subject,
        body,
        email_to,
        delivery_method,
        delivery_date,
        recipient_first_name,
        recipient_last_name,
        recipient_middle_name,
        recipient_npi,
        recipient_credentials,
        recipient_contact_type,
        recipient_address,
        recipient_city,
        recipient_state,
        recipient_zip,
        recipient_fax,
        recipient_org_name,
        recipient_specialty,
        document_datetime,
        chart_feed_datetime,
        last_modified_datetime,
        creation_time,
        created_by_user_id,
        deletion_datetime,
        deleted_by_user_id,
        signed_datetime,
        signed_by_user_id,
        from_plr,
        hdb_last_sync_datetime,
        _last_sync_date,
        'hosted_share' as _data_source
    from dw_dev.dev_jkizer_staging.stg_elation_provider_letter
    where _idx = 1
), relay_path as (
    select
        to_varchar(letter_id) as uq_provider_letter,
        letter_id as provider_letter_id,
        patient_id,
        practice_id,
        send_to_name,
        subject,
        body,
        email_to,
        delivery_method,
        convert_timezone('America/Los_Angeles', delivery_datetime)::timestamp_ntz as delivery_date,
        recipient_first_name,
        recipient_last_name,
        recipient_middle_name,
        recipient_npi,
        cast(null as varchar) as recipient_credentials,
        cast(null as varchar) as recipient_contact_type,
        cast(null as varchar) as recipient_address,
        cast(null as varchar) as recipient_city,
        cast(null as varchar) as recipient_state,
        cast(null as varchar) as recipient_zip,
        fax_to as recipient_fax,
        recipient_org_name,
        recipient_specialty,
        convert_timezone('America/Los_Angeles', document_datetime)::timestamp_ntz as document_datetime,
        cast(null as timestamp_ntz) as chart_feed_datetime,
        convert_timezone('America/Los_Angeles', event_time)::timestamp_ntz as last_modified_datetime,
        convert_timezone('America/Los_Angeles', created_datetime)::timestamp_ntz as creation_time,
        cast(null as number) as created_by_user_id,
        convert_timezone('America/Los_Angeles', deleted_datetime)::timestamp_ntz as deletion_datetime,
        cast(null as number) as deleted_by_user_id,
        convert_timezone('America/Los_Angeles', sign_datetime)::timestamp_ntz as signed_datetime,
        signed_by_user_id,
        cast(null as boolean) as from_plr,
        convert_timezone('America/Los_Angeles', _airbyte_extracted_at)::timestamp_ntz as hdb_last_sync_datetime,
        date(convert_timezone('America/Los_Angeles', _airbyte_extracted_at)) as _last_sync_date,
        'relay' as _data_source
    from dw_dev.dev_jkizer_staging.stg_elation_relay_letter
    where _idx = 1
        and is_deleted = 0
        and letter_type = 'provider'
        and created_datetime >= dateadd(hour, -24, current_timestamp())
), combined as (
    select * from hosted_share
    union all
    select * from relay_path
)
select *
from combined
qualify row_number() over (
    partition by provider_letter_id
    order by case when _data_source = 'relay' then 1 else 2 end
) = 1
    )
;


  