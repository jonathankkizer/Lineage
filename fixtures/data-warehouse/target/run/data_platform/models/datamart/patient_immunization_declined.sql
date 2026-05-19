
  
    

create or replace transient table dw_dev.dev_jkizer.patient_immunization_declined
    copy grants
    
    
    as (select
    uq_patient_immunization_declined,
    patient_immunization_declined_id,
    patient_id as elation_id,
    suvida_id,
    cdc_type,
    declined_datetime,
    -- declined reasons are hardcoded from Elation tech rep, no mapping available in their database
    case
        when declined_reason = '00' then 'Parental decision'
        when declined_reason = '01' then 'Religious exemption'
        when declined_reason = '02' then 'Other'
        when declined_reason = '03' then 'Patient decision'
        else null 
    end as declined_reason,
    immunity as is_immunity,
    last_modified_datetime,
    created_by_user_id as created_by_elation_staff_id,
    user.user_name as elation_staff_name,
    user.user_email as elation_staff_email,
    deletion_datetime,
    deleted_by_user_id,
    hdb_last_sync_datetime,
    _last_sync_date,
    _idx
from dw_dev.dev_jkizer_staging.stg_elation_patient_immunization_declined pim 
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on pim.patient_id = siw.member_id
	and siw.source = 'Elation'
left join dw_dev.dev_jkizer.dim_ehr_user user 
    on user.user_id = pim.created_by_user_id
    )
;


  