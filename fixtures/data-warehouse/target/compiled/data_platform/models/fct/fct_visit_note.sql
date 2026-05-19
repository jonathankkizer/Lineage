

with bullet_hierarchy as (
    select
        nb.visit_note_id,
        nb.visit_note_bullet_id,
        nb.parent_bullet_id,
        nb.category,
        nb.sequence,
        nb.text,
        nb.last_modified_datetime,
        vn.signed_date,
        vn.signed_by_user_id,
        u.user_name as signed_by_user_name,
        vn._is_deleted_record,
        vn.deletion_datetime,
        -- Get child bullet text using window function instead of self-join
        case 
            when nb.parent_bullet_id is null then (
                select listagg(child.text, ' ')
                from dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet child
                where child.parent_bullet_id = nb.visit_note_bullet_id
                and child.deleted_datetime is null
            )
            else null
        end as bullet_text
    from dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet nb
    left join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn
        on nb.visit_note_id = vn.visit_note_id
        and vn._idx = 1
        and vn._is_test_patient = 0
    left join dw_dev.dev_jkizer_staging.stg_elation_user u
        on vn.physician_user_id = u.user_id
        and u._idx = 1
), visit_note_join_logic as (
    select
        bh.visit_note_id,
        bh.visit_note_bullet_id,
        bh.category,
        bh.sequence,
        array_to_string(
            array_construct_compact(bh.text, icd10.code),
            ''
          ) as primary_text,
        bh.last_modified_datetime,
        bh.visit_note_bullet_id,
        bh.parent_bullet_id,
        bh.bullet_text,
        bh.sequence,
        bh.signed_date,
        bh.signed_by_user_id,
        bh.signed_by_user_name,
        bh._is_deleted_record,
        bh.deletion_datetime
    from bullet_hierarchy bh
    left join dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet_imo_join imo_j
        on bh.visit_note_bullet_id = imo_j.visit_note_bullet_id
    left join dw_dev.dev_jkizer_staging.stg_elation_icd10 icd10
        using (imo_id)
    where bh.parent_bullet_id is null -- only process parent bullets to avoid duplication
    
          -- this filter will only be applied on an incremental run
          -- will re-run for all visit note ids altered since last run
        and bh.last_modified_datetime >= dateadd(day, -7, current_date())
    
    
    order by bh.category, bh.sequence, bh.last_modified_datetime asc 
), combined_text_processing as ( -- process text in single pass for both full_text and category breakdown
    select
        visit_note_id,
        category,
        max(last_modified_datetime) as last_modified_datetime,
        listagg(primary_text || '>' || coalesce(bullet_text, '')) as note,
        max(signed_date) as signed_date,
        max(signed_by_user_id) as signed_by_user_id,
        max(signed_by_user_name) as signed_by_user_name,
        max(_is_deleted_record) as _is_deleted_record,
        max(deletion_datetime) as deletion_datetime
    from visit_note_join_logic
    group by visit_note_id, category
), full_text as ( -- get column with all note text available
    select
        visit_note_id,
        max(last_modified_datetime) as last_modified_datetime,
        listagg(note) as full_text_note,
        max(signed_date) as signed_date,
        max(signed_by_user_id) as signed_by_user_id,
        max(signed_by_user_name) as signed_by_user_name,
        max(_is_deleted_record) as _is_deleted_record,
        max(deletion_datetime) as deletion_datetime
    from combined_text_processing
    group by visit_note_id
), condense_note as ( -- notes already broken out by category from combined_text_processing
    select 
        visit_note_id,
        category,
        note,
    from combined_text_processing
), pivot as ( -- pivot note per category (corresponds with Elation sections)
    select 
        *
    from condense_note cn 
    pivot (max(note)
        for category in ('Surgical','Referenced','ROS','Reason','Instr','Objective','Narrative','Followup','Assessment','Family','Past','Plan','Social','Habits','Problem','Procedure','Assessplan','Data','Tx','Med','Hpi','Dateprocedure','Test','Orders','Allergies','PE')
        ) as pivot_table
)
select
    fe.encounter_skey,
    fe.appointment_encounter_skey,
    fe.encounter_date,
    fe.suvida_id,
    fe.visit_note_name,
    p.visit_note_id,
    p.$2 as surgical_note,
    p.$3 as referenced_note,
    p.$4 as ros_note,
    p.$5 as reason_note,
    p.$6 as care_plan_note,
    p.$7 as objective_note,
    p.$8 as narrative_note,
    p.$9 as followup_note,
    p.$10 as assessment_note,
    p.$11 as family_note,
    p.$12 as past_note,
    p.$13 as plan_note,
    p.$14 as social_note,
    p.$15 as habit_note,
    p.$16 as problem_note,
    p.$17 as procedure_note,
    p.$18 as assessplan_note,
    p.$19 as data_note,
    p.$20 as tx_note,
    p.$21 as med_note,
    p.$22 as hpi_note,
    p.$23 as date_procedure_note,
    p.$24 as test_note,
    p.$25 as orders_note,
    p.$26 as allergies_note,
    p.$27 as pe_note,
    ft.full_text_note,
    ft.last_modified_datetime,
    ft.signed_date,
    ft.signed_by_user_id,
    ft.signed_by_user_name,
    ft._is_deleted_record,
    ft.deletion_datetime,
    vnt.inferred_time_minutes,
    vnt.action_count,
from pivot p 
inner join full_text ft 
    on p.visit_note_id = ft.visit_note_id
inner join dw_dev.dev_jkizer.fct_encounter fe 
    on p.visit_note_id = fe.visit_note_id
    and fe.visit_note_id != '1125709524107288'
left join dw_dev.dev_jkizer.fct_visit_note_timing vnt
    on p.visit_note_id = vnt.visit_note_id