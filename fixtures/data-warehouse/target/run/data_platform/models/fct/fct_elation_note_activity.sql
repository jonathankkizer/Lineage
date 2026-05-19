
  
    

create or replace transient table dw_dev.dev_jkizer.fct_elation_note_activity
    copy grants
    
    
    as (select 
    md5(cast(coalesce(cast(vn2.visit_note_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn2.custom_block_snapshot_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(question_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(response as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(is_visible as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as note_activity_skey,
    vn2.visit_note_id, 
    vn2.el8_note_id,
    vn2.patient_id as elation_id,
    siw.suvida_id,
    vn.document_date as encounter_date, 
    vn2.custom_block_snapshot_id, 
    label as custom_block_label,
    question_id, 
    field_name as question_field_name, 
    question_type, 
    nullif(trim(question_text), '') AS question_text,
    response, 
    is_required,
    is_visible
from dw_dev.dev_jkizer_staging.stg_elation_vn2_note vn2
left join dw_dev.dev_jkizer_staging.stg_elation_vn2_custom_block_snapshot snapshot 
    on snapshot.custom_block_snapshot_id = vn2.custom_block_snapshot_id 
left join  dw_dev.dev_jkizer_staging.stg_elation_vn2_custom_block custom_block
    on custom_block.custom_block_id = snapshot.custom_block_id 
left join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn
    on vn.visit_note_id = vn2.visit_note_id 
left join dw_dev.dev_jkizer.suvida_id_walk siw 
    on siw.member_id = vn2.patient_id 
    and source = 'Elation'
where is_deleted = FALSE
    )
;


  