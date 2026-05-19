
  
    

create or replace transient table dw_dev.dev_jkizer.fct_encounter_workflow
    copy grants
    
    
    as (with pcp_change_form as ( --cte for this specific workflow type
    select
        encounter_skey,
        suvida_id,
        patient_id,
        encounter_datetime,
        'pcp_change_form' as workflow_type,
        substr(ltrim(regexp_substr(note_text,'date:(.*)',1), 'Suvida PCP effective date:'),1,10) as suvida_pcp_effective_date,
        rtrim(rtrim(ltrim(regexp_substr(regexp_substr(lower(note_text),'date and time (.*)',1), 'call:(.*) - name',1), 'call:'), 'name'), ' - ') as date_and_time_of_call,
        trim(rtrim(rtrim(substr(regexp_substr(note_text,'person spoken to:(.*) Reference number:'),18), 'Call of Reference number:'),'-'), ' ') as name_of_person_spoken_to,
        rtrim(split_part(ltrim(regexp_substr(note_text,'number:(.*)'), 'number:'), '- Faxed',1), ' -') as call_of_reference_number,
        substr(ltrim(regexp_substr(note_text,'Faxed Form:(.*)'), 'Faxed Form:'),1,3) as faxed_form
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%pcp change status%'
), pcp_change_form_structure as (
    select
        encounter_skey,
        suvida_id,
        patient_id,
        encounter_datetime,
        unpvt.workflow_key,
        trim(unpvt.workflow_value) as workflow_value,
    from pcp_change_form
    unpivot (
        workflow_value for workflow_key in (suvida_pcp_effective_date, date_and_time_of_call, name_of_person_spoken_to, call_of_reference_number, faxed_form)
    ) as unpvt
)
select 
    encounter_skey,
    md5(cast(coalesce(cast(encounter_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(workflow_key as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as encounter_workflow_skey,
    suvida_id,
    patient_id,
    encounter_datetime,
    workflow_key,
    workflow_value,
from pcp_change_form_structure
    )
;


  