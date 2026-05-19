
  
    

create or replace transient table dw_dev.dev_jkizer.int_elation_referral
    copy grants
    
    
    as (

with hosted_share as (
    select
        uq_referral_order,
        referral_id,
        elation_id,
        practice_id,
        send_to_name,
        referral_subject,
        referral_body_text,
        email_to,
        delivery_method,
        delivery_date,
        fax_status,
        processing_status,
        resolution_state,
        clinical_reason,
        sender_user_id,
        authorization_for,
        authorization_number,
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
        from_plr,
        is_deleted,
        document_date,
        document_datetime,
        chart_feed_date,
        chart_feed_datetime,
        last_modified_date,
        last_modified_datetime,
        creation_date,
        creation_datetime,
        created_by_user_id,
        deletion_date,
        deletion_datetime,
        deleted_by_user_id,
        signed_date,
        signed_datetime,
        signed_by_user_id,
        warehouse_id,
        hdb_last_sync_datetime,
        'hosted_share' as _data_source
    from dw_dev.dev_jkizer_staging.stg_elation_referral_order
), relay_referral as (
    select *
    from dw_dev.dev_jkizer_staging.stg_elation_relay_referral_order
    where _idx = 1
), relay_letter as (
    select *
    from dw_dev.dev_jkizer_staging.stg_elation_relay_letter
    where _idx = 1
), relay_path as (
    select
        to_varchar(r.referral_id) as uq_referral_order,
        r.referral_id,
        r.elation_id,
        r.practice_id,
        l.send_to_name,
        l.subject as referral_subject,
        l.body as referral_body_text,
        l.email_to,
        l.delivery_method,
        convert_timezone('America/Los_Angeles', coalesce(l.delivery_datetime, r.referral_letter_delivery_datetime))::timestamp_ntz as delivery_date,
        l.fax_status,
        cast(null as varchar) as processing_status,
        r.resolution_state,
        l.body as clinical_reason,
        cast(null as number) as sender_user_id,
        r.authorization_for,
        r.auth_number as authorization_number,
        l.recipient_first_name,
        l.recipient_last_name,
        l.recipient_middle_name,
        l.recipient_npi,
        cast(null as varchar) as recipient_credentials,
        cast(null as varchar) as recipient_contact_type,
        cast(null as varchar) as recipient_address,
        cast(null as varchar) as recipient_city,
        cast(null as varchar) as recipient_state,
        cast(null as varchar) as recipient_zip,
        l.fax_to as recipient_fax,
        l.recipient_org_name,
        l.recipient_specialty,
        cast(null as boolean) as from_plr,
        greatest(coalesce(r.is_deleted, 0), coalesce(l.is_deleted, 0)) as is_deleted,
        date(convert_timezone('America/Los_Angeles', l.document_datetime)) as document_date,
        convert_timezone('America/Los_Angeles', l.document_datetime)::timestamp_ntz as document_datetime,
        cast(null as date) as chart_feed_date,
        cast(null as timestamp_ntz) as chart_feed_datetime,
        date(convert_timezone('America/Los_Angeles', r.event_time)) as last_modified_date,
        convert_timezone('America/Los_Angeles', r.event_time)::timestamp_ntz as last_modified_datetime,
        date(convert_timezone('America/Los_Angeles', coalesce(l.created_datetime, r.created_datetime, r.event_time))) as creation_date,
        convert_timezone('America/Los_Angeles', coalesce(l.created_datetime, r.created_datetime, r.event_time))::timestamp_ntz as creation_datetime,
        cast(null as number) as created_by_user_id,
        date(convert_timezone('America/Los_Angeles', coalesce(r.deleted_datetime, l.deleted_datetime))) as deletion_date,
        convert_timezone('America/Los_Angeles', coalesce(r.deleted_datetime, l.deleted_datetime))::timestamp_ntz as deletion_datetime,
        cast(null as number) as deleted_by_user_id,
        date(convert_timezone('America/Los_Angeles', coalesce(r.referral_letter_sign_datetime, l.sign_datetime))) as signed_date,
        convert_timezone('America/Los_Angeles', coalesce(r.referral_letter_sign_datetime, l.sign_datetime))::timestamp_ntz as signed_datetime,
        l.signed_by_user_id,
        cast(null as number) as warehouse_id,
        convert_timezone('America/Los_Angeles', r._airbyte_extracted_at)::timestamp_ntz as hdb_last_sync_datetime,
        'relay' as _data_source
    from relay_referral r
    left join relay_letter l on l.letter_id = r.letter_id
    where l.created_datetime >= dateadd(hour, -24, current_timestamp())
), combined as (
    select * from hosted_share
    union all
    select * from relay_path
)
select *
from combined
qualify row_number() over (
    partition by referral_id
    order by case when _data_source = 'relay' then 1 else 2 end
) = 1
    )
;


  