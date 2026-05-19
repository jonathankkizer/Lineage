select
    fph.suvida_id,
    round(fph.patient_id) as patient_id,
    seph.patient_history_id,
    fph.history_type,
    fph.history_value,
    fph.history_value_numeric,
    fph.history_value_relationship_type,
    fph.history_value_rank,
    fph.creation_datetime,
    fph.last_modified_datetime,
    fph.created_by_user_id,
    u.user_email,
    fph.patient_history_index
from dw_dev.dev_jkizer.fct_patient_history fph
left join dw_dev.dev_jkizer.ehr_user u
    on fph.created_by_user_id = u.user_id
left join dw_dev.dev_jkizer_staging.stg_elation_patient_history seph
    on fph.patient_id = seph.patient_id and
       fph.creation_datetime = seph.creation_datetime and
       fph.created_by_user_id = seph.created_by_user_id and 
       case
        when fph.history_type = 'Mini-Cog' and seph.history_type = 'Cognitive' and seph.history_value like 'Cognitive: Mini-Cog Score:%' then 1
        when fph.history_type = 'KATZ-ADL' and seph.history_type like '%KATZ-ADL%' then 1
        when fph.history_type = 'Alcohol use' and seph.history_type = 'Habits' and seph.history_value like 'Alcohol use: AUDIT-C Score:%' then 1
        when fph.history_type = 'TUG' and seph.history_type = 'Maintenance' and seph.history_value like '%TUG:%' then 1
        when fph.history_type = 'Pre-TUG' and seph.history_type = 'Functional' and (seph.history_value like '%Pre-%' and seph.history_value like '%Timed Up and Go Test:%')  then 1
        when fph.history_type = 'Post-TUG' and seph.history_type = 'Functional' and (seph.history_value like '%Post-%' and seph.history_value like '%Timed Up and Go Test:%') then 1
        when fph.history_type = 'Pre-Chair-Stand' and seph.history_type = 'Functional' and (seph.history_value like '%Pre-%' and seph.history_value like '%30 Second Chair Stand Test:%')  then 1
        when fph.history_type = 'Post-Chair-Stand' and seph.history_type = 'Functional' and (seph.history_value like '%Post-%' and seph.history_value like '%30 Second Chair Stand Test:%')  then 1
        when fph.history_type in ('Cognitive', 'Psychological') and fph.history_type = seph.history_type and fph.history_value = seph.history_value then 1
        when fph.history_type = 'GAD-7' and seph.history_type = 'Psychological' and seph.history_value like 'Anxiety: GAD-7 Score:%' and fph.history_value = split_part(split_part(seph.history_value, 'Anxiety: GAD-7 Score: ', 2), ' (', 1) then 1
        when fph.history_type = 'PHQ-9' and seph.history_type = 'Psychological' and seph.history_value like 'Depression: PHQ-9 Score:%' and fph.history_value = split_part(split_part(seph.history_value, 'Depression: PHQ-9 Score: ', 2), ' (', 1) then 1
        when fph.history_type = 'PHQ-2' and seph.history_type = 'Psychological' and seph.history_value like 'Depression: PHQ-2 Score:%' and fph.history_value = split_part(split_part(seph.history_value, 'Depression: PHQ-2 Score: ', 2), ' (', 1) then 1
        else 0
       end = 1