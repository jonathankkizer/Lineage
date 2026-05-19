
  create or replace   view dw_dev.dev_jkizer.phone_type_intelligence_roster
  
    
    
(
  
    "SUVIDA_ID" COMMENT $$The patient's Suvida identifier$$, 
  
    "PHONE" COMMENT $$The patient's phone number$$, 
  
    "PHONE_TYPE" COMMENT $$The patient phone's type, as identified by the EMR (Elation)$$
  
)

  copy grants
  
  
  as (
    

with line_intelligence as (
    select
        *,
        row_number() over (partition by suvida_id, phone order by date_created desc) as _idx
    from source_prod.messaging.phone
),

latest_intelligence as (
    select *
    from line_intelligence
    where _idx = 1
)

select distinct
    ps.suvida_id,
    ph.phone,
    ph.phone_type
from dw_dev.dev_jkizer.patient_summary ps
left join dw_dev.dev_jkizer_staging.stg_elation_patient_phone ph
    on ps.elation_id = ph.patient_id
left join latest_intelligence tph
    on ps.suvida_id = tph.suvida_id
left join source_prod.messaging.phone_exclusions pe
    on ph.phone = pe.phone
where
    (
        -- Return only records for active assignment patients
        -- or patients that have a future appointment
        ps.is_active_assignment = 1 or
        (
            ps.next_careteam_appt_date is not null or
            ps.last_pcp_appt_date is not null
        )
    ) and
    -- Filter out any deleted Elation phone records
    ph._is_deleted_record = FALSE and
    (
        -- Return only phone records where there is no intelligence (no date_created)
        -- or the date_created is older than 90 days (ensuring a quarterly refresh of a phone intelligence record)
        tph.date_created is null or
        sysdate() >= dateadd(day, 90, tph.date_created)
    ) and
    -- Filter out any phones in the exclusion list
    pe.phone is null
  );

