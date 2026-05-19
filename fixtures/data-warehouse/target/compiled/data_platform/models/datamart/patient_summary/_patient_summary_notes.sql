

-- Component: Patient operational notes (insurance changes, chase lists, HRH, etc.)
-- Extracted from patient_summary to reduce model complexity

with non_visit_note_insurance_change as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_insurance_change_note_text
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%pcp change status%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

insurance_verification as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_insurance_verification_note_text
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%insurance eligibility check%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

agent_of_record as (
    select
        suvida_id,
        note_text as recent_agent_of_record_note_text,
        encounter_date as recent_agent_of_record_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%agent of record%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

come_back_2_care as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_come_back_care_note_text,
        encounter_date as recent_come_back_care_encounter_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%come back 2 care%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

bp_chase_list as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_bp_chase_note_text,
        encounter_date as recent_bp_chase_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%#bpch%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

dm_chase_list as (
    select
        suvida_id,
        concat(note_text,' Created by: ', provider_name) as recent_dm_chase_note_text,
        encounter_date as recent_dm_chase_note_date
    from dw_dev.dev_jkizer.fct_encounter
    where lower(note_text) like '%#dmch%'
    qualify row_number() over (partition by suvida_id order by encounter_datetime desc) = 1
),

hrh_dates as (
    select
        suvida_id,
        encounter_date as last_huddle_date,
        followup_note as next_huddle_date_raw,
        regexp_substr(followup_note, '\\d{1,2}[-/]\\d{1,2}[-/]\\d{2,4}') AS next_huddle_date_formatted
    from dw_dev.dev_jkizer.encounter_visit_note
    where full_text_note ilike ('%next hrh date%')
    qualify row_number() over (partition by suvida_id order by encounter_date desc) = 1
),

all_patients as (
    select distinct suvida_id from dw_dev.dev_jkizer.dim_patient
)

select
    ap.suvida_id,
    nvnic.recent_insurance_change_note_text,
    iv.recent_insurance_verification_note_text,
    aor.recent_agent_of_record_note_text,
    aor.recent_agent_of_record_note_date,
    trim(replace(replace(split(aor.recent_agent_of_record_note_text, ': ')[1]::varchar, 'Agent Phone Number', ''), '-', '')) as agent_of_record,
    cb2.recent_come_back_care_note_text,
    cb2.recent_come_back_care_encounter_date,
    bcl.recent_bp_chase_note_text,
    bcl.recent_bp_chase_note_date,
    dcl.recent_dm_chase_note_text,
    dcl.recent_dm_chase_note_date,
    hrh.last_huddle_date,
    hrh.next_huddle_date_raw,
    (coalesce(try_to_date(hrh.next_huddle_date_formatted, 'MM-DD-YYYY'), try_to_date(hrh.next_huddle_date_formatted, 'MM/DD/YY'), try_to_date(hrh.next_huddle_date_formatted, 'MM/DD/YYYY'))) as next_huddle_date_formatted
from all_patients ap
left join non_visit_note_insurance_change nvnic on ap.suvida_id = nvnic.suvida_id
left join insurance_verification iv on ap.suvida_id = iv.suvida_id
left join agent_of_record aor on ap.suvida_id = aor.suvida_id
left join come_back_2_care cb2 on ap.suvida_id = cb2.suvida_id
left join bp_chase_list bcl on ap.suvida_id = bcl.suvida_id
left join dm_chase_list dcl on ap.suvida_id = dcl.suvida_id
left join hrh_dates hrh on ap.suvida_id = hrh.suvida_id